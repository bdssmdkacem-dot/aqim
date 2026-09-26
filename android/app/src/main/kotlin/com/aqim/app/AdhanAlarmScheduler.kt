package com.aqim.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.TimeZone

/** Native Adhan scheduler. Keeps prayer-time alarms independent of Flutter process state. */
object AdhanAlarmScheduler {
    private const val PREFS = "aqim_native_adhan_alarms"
    private const val KEY_PREFIX = "alarm_"
    private const val KEY_ID = "id"
    private const val KEY_TIME = "time"
    private const val KEY_SOUND = "sound"
    private const val KEY_TITLE = "title"
    private const val KEY_BODY = "body"
    private const val KEY_NOTIFICATION_ID = "notification_id"
    private const val KEY_DATE = "date"
    private const val KEY_TZ_OFFSET = "tz_offset"
    private const val KEY_ENABLED = "enabled"
    private const val MAINTENANCE_EVENING_REQUEST_CODE = 90001
    private const val MAINTENANCE_MORNING_REQUEST_CODE = 90002
    private const val PRE_MIDNIGHT_REFRESH_HOUR = 23
    private const val PRE_MIDNIGHT_REFRESH_MINUTE = 45
    private const val MAX_PRAYERS = 5
    private const val ALADHAN_METHOD = 21

    private val prayerIds = intArrayOf(2, 12, 22, 32, 42)
    private val prayerKeys = arrayOf("Fajr", "Dhuhr", "Asr", "Maghrib", "Isha")
    private val prayerNames = arrayOf("الفجر", "الظهر", "العصر", "المغرب", "العشاء")
    private val fallbackSounds = arrayOf(
        "azan-fajr",
        "azan_maroc_1",
        "azan_maroc_1",
        "azan_maroc_1",
        "azan_maroc_1"
    )

    private fun dateString(timeMillis: Long): String =
        SimpleDateFormat("yyyy-MM-dd", Locale.US).apply {
            timeZone = TimeZone.getDefault()
        }.format(Date(timeMillis))

    fun persist(
        context: Context,
        id: Int,
        timeMillis: Long,
        soundName: String,
        title: String,
        body: String,
        notificationId: Int
    ) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        prefs.edit()
            .putInt(KEY_PREFIX + id + KEY_ID, id)
            .putLong(KEY_PREFIX + id + KEY_TIME, timeMillis)
            .putString(KEY_PREFIX + id + KEY_SOUND, soundName.trim())
            .putString(KEY_PREFIX + id + KEY_TITLE, title)
            .putString(KEY_PREFIX + id + KEY_BODY, body)
            .putInt(KEY_PREFIX + id + KEY_NOTIFICATION_ID, notificationId)
            .putString(KEY_PREFIX + id + KEY_DATE, dateString(timeMillis))
            .putInt(KEY_PREFIX + id + KEY_TZ_OFFSET, TimeZone.getDefault().getOffset(timeMillis))
            .putBoolean(KEY_ENABLED, true)
            .apply()
        scheduleMaintenance(context)
    }

    fun remove(context: Context, id: Int) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .remove(KEY_PREFIX + id + KEY_ID)
            .remove(KEY_PREFIX + id + KEY_TIME)
            .remove(KEY_PREFIX + id + KEY_SOUND)
            .remove(KEY_PREFIX + id + KEY_TITLE)
            .remove(KEY_PREFIX + id + KEY_BODY)
            .remove(KEY_PREFIX + id + KEY_NOTIFICATION_ID)
            .remove(KEY_PREFIX + id + KEY_DATE)
            .remove(KEY_PREFIX + id + KEY_TZ_OFFSET)
            .apply()
    }

    fun clearAll(context: Context) {
        cancelAllStoredAlarms(context)
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().clear().apply()
        cancelMaintenance(context)
    }

    fun requestReschedule(context: Context) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (!prefs.getBoolean(KEY_ENABLED, false)) return
        rescheduleStored(context)
        refreshCurrentDayAsync(context)
    }

    /** Used for TIME_SET/TIMEZONE_CHANGED: refresh before replacing valid stored alarms. */
    fun requestSystemTimeReschedule(context: Context) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (!prefs.getBoolean(KEY_ENABLED, false)) return

        // A timezone change must invalidate alarms created under the old offset
        // before attempting the network refresh. If the device is offline, keeping
        // those alarms would fire at the old wall-clock time and a later Flutter
        // offline schedule could then produce a duplicate Adhan.
        rescheduleStored(context)
        refreshCurrentDayAsync(context)
    }

    /**
     * Keep two independent maintenance opportunities every day:
     * - 23:45 prepares tomorrow before the date rolls over.
     * - 00:05 refreshes today's schedule as a second recovery attempt.
     *
     * This avoids making the whole day dependent on one network/API attempt at 00:05.
     */
    fun scheduleMaintenance(context: Context) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (!prefs.getBoolean(KEY_ENABLED, false)) return
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        val eveningCalendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, PRE_MIDNIGHT_REFRESH_HOUR)
            set(Calendar.MINUTE, PRE_MIDNIGHT_REFRESH_MINUTE)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            if (timeInMillis <= System.currentTimeMillis()) add(Calendar.DAY_OF_YEAR, 1)
        }
        scheduleMaintenanceAlarm(
            context,
            alarmManager,
            MAINTENANCE_EVENING_REQUEST_CODE,
            eveningCalendar.timeInMillis
        )

        val morningCalendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 5)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            if (timeInMillis <= System.currentTimeMillis()) add(Calendar.DAY_OF_YEAR, 1)
        }
        scheduleMaintenanceAlarm(
            context,
            alarmManager,
            MAINTENANCE_MORNING_REQUEST_CODE,
            morningCalendar.timeInMillis
        )
    }

    private fun scheduleMaintenanceAlarm(
        context: Context,
        alarmManager: AlarmManager,
        requestCode: Int,
        timeMillis: Long
    ) {
        val intent = Intent(context, AdhanAlarmReceiver::class.java).apply {
            action = AdhanAlarmReceiver.ACTION_DAILY_MAINTENANCE
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        scheduleAlarm(context, alarmManager, timeMillis, pendingIntent)
    }

    private fun cancelMaintenance(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        for (requestCode in intArrayOf(
            MAINTENANCE_EVENING_REQUEST_CODE,
            MAINTENANCE_MORNING_REQUEST_CODE
        )) {
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                requestCode,
                Intent(context, AdhanAlarmReceiver::class.java).apply {
                    action = AdhanAlarmReceiver.ACTION_DAILY_MAINTENANCE
                },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            alarmManager.cancel(pendingIntent)
            pendingIntent.cancel()
        }
    }

    fun refreshCurrentDayAsync(context: Context) {
        Thread {
            try {
                val target = Calendar.getInstance()
                if (isPreMidnightWindow(target)) {
                    target.add(Calendar.DAY_OF_YEAR, 1)
                }
                refreshForDate(context, target)
            } catch (_: Exception) {
                scheduleMaintenance(context)
            }
        }.start()
    }

    private fun isPreMidnightWindow(calendar: Calendar): Boolean =
        calendar.get(Calendar.HOUR_OF_DAY) >= PRE_MIDNIGHT_REFRESH_HOUR &&
            (calendar.get(Calendar.HOUR_OF_DAY) > PRE_MIDNIGHT_REFRESH_HOUR ||
                calendar.get(Calendar.MINUTE) >= PRE_MIDNIGHT_REFRESH_MINUTE)

    private fun refreshForDate(context: Context, calendar: Calendar) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (!prefs.getBoolean(KEY_ENABLED, false)) return

        val locationPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val lat = readDouble(locationPrefs, "flutter.last_lat", "last_lat") ?: return
        val lng = readDouble(locationPrefs, "flutter.last_lng", "last_lng") ?: return
        val date = SimpleDateFormat("dd-MM-yyyy", Locale.US).apply {
            timeZone = TimeZone.getDefault()
        }.format(calendar.time)
        val url = URL(
            "https://api.aladhan.com/v1/timings/$date?latitude=$lat&longitude=$lng&method=$ALADHAN_METHOD"
        )
        val connection = url.openConnection() as HttpURLConnection
        connection.connectTimeout = 10000
        connection.readTimeout = 10000
        connection.requestMethod = "GET"
        try {
            if (connection.responseCode !in 200..299) return
            val response = connection.inputStream.bufferedReader().use { it.readText() }
            val timings = JSONObject(response).getJSONObject("data").getJSONObject("timings")
            val now = System.currentTimeMillis()
            val newAlarms = mutableListOf<AlarmData>()

            for (i in 0 until MAX_PRAYERS) {
                val timeText = timings.optString(prayerKeys[i]).substringBefore(" ")
                val parts = timeText.split(":")
                if (parts.size < 2) continue
                val hour = parts[0].toIntOrNull() ?: continue
                val minute = parts[1].toIntOrNull() ?: continue

                val prayerCalendar = calendar.clone() as Calendar
                prayerCalendar.set(Calendar.HOUR_OF_DAY, hour)
                prayerCalendar.set(Calendar.MINUTE, minute)
                prayerCalendar.set(Calendar.SECOND, 0)
                prayerCalendar.set(Calendar.MILLISECOND, 0)
                val timeMillis = prayerCalendar.timeInMillis
                if (timeMillis <= now) continue

                val id = prayerIds[i]
                val prefix = KEY_PREFIX + id
                val savedSound = prefs.getString(prefix + KEY_SOUND, null)?.trim()
                val sound = savedSound.takeUnless { it.isNullOrBlank() } ?: fallbackSounds[i]
                val title = if (
                    i == 1 && prayerCalendar.get(Calendar.DAY_OF_WEEK) == Calendar.FRIDAY
                ) {
                    "حان وقت صلاة الجمعة"
                } else {
                    "حان وقت ${prayerNames[i]}"
                }
                val body = "حيّ على الصلاة، حيّ على الفلاح."
                val notificationId = prefs.getInt(
                    prefix + KEY_NOTIFICATION_ID,
                    10000 + id
                )
                newAlarms += AlarmData(id, timeMillis, sound, title, body, notificationId)
            }

            // Never destroy valid stored alarms because a refresh returned no future
            // prayer (for example, because the target date is already past or the
            // response was incomplete). The next maintenance cycle will retry.
            if (newAlarms.isEmpty()) return

            for (id in prayerIds) cancelAlarm(context, id)
            for (alarm in newAlarms) {
                persist(
                    context,
                    alarm.id,
                    alarm.timeMillis,
                    alarm.sound,
                    alarm.title,
                    alarm.body,
                    alarm.notificationId
                )
                scheduleNativeAlarm(
                    context,
                    alarm.id,
                    alarm.timeMillis,
                    alarm.sound,
                    alarm.title,
                    alarm.body,
                    alarm.notificationId
                )
            }
        } finally {
            connection.disconnect()
            scheduleMaintenance(context)
        }
    }

    private data class AlarmData(
        val id: Int,
        val timeMillis: Long,
        val sound: String,
        val title: String,
        val body: String,
        val notificationId: Int
    )

    private fun readDouble(
        prefs: android.content.SharedPreferences,
        primary: String,
        fallback: String
    ): Double? {
        val value = prefs.all[primary] ?: prefs.all[fallback]
        return when (value) {
            is Float -> value.toDouble()
            is Double -> value
            is Long -> value.toDouble()
            is Int -> value.toDouble()
            is String -> value.toDoubleOrNull()
            else -> null
        }
    }

    private fun scheduleNativeAlarm(
        context: Context,
        id: Int,
        timeMillis: Long,
        soundName: String,
        title: String,
        body: String,
        notificationId: Int
    ) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, AdhanAlarmReceiver::class.java).apply {
            putExtra(AdhanAlarmReceiver.EXTRA_SOUND, soundName.trim())
            putExtra(AdhanAlarmReceiver.EXTRA_TITLE, title)
            putExtra(AdhanAlarmReceiver.EXTRA_BODY, body)
            putExtra(AdhanAlarmReceiver.EXTRA_NOTIFICATION_ID, notificationId)
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        scheduleAlarm(context, alarmManager, timeMillis, pendingIntent)
    }

    private fun scheduleAlarm(
        context: Context,
        alarmManager: AlarmManager,
        timeMillis: Long,
        pendingIntent: PendingIntent
    ) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S || alarmManager.canScheduleExactAlarms()) {
                alarmManager.setAlarmClock(
                    AlarmManager.AlarmClockInfo(timeMillis, pendingIntent),
                    pendingIntent
                )
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    timeMillis,
                    pendingIntent
                )
            } else {
                alarmManager.set(AlarmManager.RTC_WAKEUP, timeMillis, pendingIntent)
            }
        } else {
            alarmManager.set(AlarmManager.RTC_WAKEUP, timeMillis, pendingIntent)
        }
    }

    private fun cancelAlarm(context: Context, id: Int) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            id,
            Intent(context, AdhanAlarmReceiver::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.cancel(pendingIntent)
        pendingIntent.cancel()
    }

    private fun cancelAllStoredAlarms(context: Context) {
        for (id in prayerIds) cancelAlarm(context, id)
    }

    fun rescheduleStored(context: Context) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (!prefs.getBoolean(KEY_ENABLED, false)) return
        val now = System.currentTimeMillis()
        val currentCalendar = Calendar.getInstance()
        val currentDate = dateString(now)
        val tomorrowCalendar = currentCalendar.clone() as Calendar
        tomorrowCalendar.add(Calendar.DAY_OF_YEAR, 1)
        val tomorrowDate = dateString(tomorrowCalendar.timeInMillis)
        val currentOffset = TimeZone.getDefault().getOffset(now)
        var restored = 0

        for (slot in 0 until MAX_PRAYERS) {
            val id = prayerIds[slot]
            val prefix = KEY_PREFIX + id
            val time = prefs.getLong(prefix + KEY_TIME, 0L)
            val sound = prefs.getString(prefix + KEY_SOUND, null)?.trim()
            val storedDate = prefs.getString(prefix + KEY_DATE, null)
            val storedOffset = prefs.getInt(prefix + KEY_TZ_OFFSET, Int.MIN_VALUE)
            val lateNightTomorrow = isPreMidnightWindow(currentCalendar) && storedDate == tomorrowDate
            if (
                time > now &&
                !sound.isNullOrBlank() &&
                (storedDate == currentDate || lateNightTomorrow) &&
                storedOffset == currentOffset
            ) {
                scheduleNativeAlarm(
                    context,
                    id,
                    time,
                    sound,
                    prefs.getString(prefix + KEY_TITLE, "حان وقت الصلاة") ?: "حان وقت الصلاة",
                    prefs.getString(prefix + KEY_BODY, "حيّ على الصلاة، حيّ على الفلاح.")
                        ?: "حيّ على الصلاة، حيّ على الفلاح.",
                    prefs.getInt(prefix + KEY_NOTIFICATION_ID, 10000 + id)
                )
                restored++
            } else {
                cancelAlarm(context, id)
            }
        }
        if (restored > 0) scheduleMaintenance(context) else cancelMaintenance(context)
    }
}
