package com.comptaflow.aqim

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

/** Native Adhan scheduler. Keeps the next prayer-day scheduled even when Flutter is closed. */
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
    private const val MAINTENANCE_REQUEST_CODE = 90001
    private const val MAX_ALARMS = 5
    private const val ALADHAN_METHOD = 21

    private fun dateString(timeMillis: Long): String = SimpleDateFormat("yyyy-MM-dd", Locale.US).apply {
        timeZone = TimeZone.getDefault()
    }.format(Date(timeMillis))

    fun persist(context: Context, id: Int, timeMillis: Long, soundName: String, title: String, body: String, notificationId: Int) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        prefs.edit()
            .putInt(KEY_PREFIX + id + KEY_ID, id)
            .putLong(KEY_PREFIX + id + KEY_TIME, timeMillis)
            .putString(KEY_PREFIX + id + KEY_SOUND, soundName)
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
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().clear().apply()
        cancelMaintenance(context)
    }

    fun requestReschedule(context: Context) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (!prefs.getBoolean(KEY_ENABLED, false)) return
        refreshCurrentDayAsync(context)
    }

    fun scheduleMaintenance(context: Context) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (!prefs.getBoolean(KEY_ENABLED, false)) return
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, AdhanAlarmReceiver::class.java).apply {
            action = AdhanAlarmReceiver.ACTION_DAILY_MAINTENANCE
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            MAINTENANCE_REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val calendar = Calendar.getInstance().apply {
            timeInMillis = System.currentTimeMillis()
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 5)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            if (timeInMillis <= System.currentTimeMillis()) add(Calendar.DAY_OF_YEAR, 1)
        }
        val trigger = calendar.timeInMillis
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S || alarmManager.canScheduleExactAlarms()) {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, trigger, pendingIntent)
            } else {
                alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, trigger, pendingIntent)
            }
        } else {
            alarmManager.setExact(AlarmManager.RTC_WAKEUP, trigger, pendingIntent)
        }
    }

    private fun cancelMaintenance(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            MAINTENANCE_REQUEST_CODE,
            Intent(context, AdhanAlarmReceiver::class.java).apply { action = AdhanAlarmReceiver.ACTION_DAILY_MAINTENANCE },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.cancel(pendingIntent)
        pendingIntent.cancel()
    }

    fun refreshCurrentDayAsync(context: Context) {
        Thread {
            try {
                refreshForDate(context, Calendar.getInstance())
            } catch (_: Exception) {
                scheduleMaintenance(context)
            }
        }.start()
    }

    private fun refreshForDate(context: Context, calendar: Calendar) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        if (!prefs.getBoolean(KEY_ENABLED, false)) return

        val locationPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val lat = readDouble(locationPrefs, "flutter.last_lat", "last_lat") ?: return
        val lng = readDouble(locationPrefs, "flutter.last_lng", "last_lng") ?: return

        val date = SimpleDateFormat("dd-MM-yyyy", Locale.US).apply { timeZone = TimeZone.getDefault() }.format(calendar.time)
        val url = URL("https://api.aladhan.com/v1/timings/$date?latitude=$lat&longitude=$lng&method=$ALADHAN_METHOD")
        val connection = url.openConnection() as HttpURLConnection
        connection.connectTimeout = 10000
        connection.readTimeout = 10000
        connection.requestMethod = "GET"
        try {
            if (connection.responseCode !in 200..299) return
            val response = connection.inputStream.bufferedReader().use { it.readText() }
            val timings = JSONObject(response).getJSONObject("data").getJSONObject("timings")
            val prayers = listOf("Fajr", "Dhuhr", "Asr", "Maghrib", "Isha")
            val ids = listOf(2, 12, 22, 32, 42)
            val existingSounds = prayers.indices.map { index -> prefs.getString(KEY_PREFIX + ids[index] + KEY_SOUND, null) }
            val fallbackSounds = listOf("azan-Fajr-madina", "azan_maroc_1", "azan_maroc_1", "azan_maroc_1", "azan_maroc_1")

            val now = System.currentTimeMillis()
            for (i in prayers.indices) {
                val timeText = timings.optString(prayers[i]).substringBefore(" ")
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

                val id = ids[i]
                cancelAlarm(context, id)
                val sound = existingSounds[i].takeUnless { it.isNullOrBlank() } ?: fallbackSounds[i]
                val title = if (i == 1 && prayerCalendar.get(Calendar.DAY_OF_WEEK) == Calendar.FRIDAY) "حان وقت صلاة الجمعة" else "حان وقت ${listOf("الفجر", "الظهر", "العصر", "المغرب", "العشاء")[i]}"
                val body = "حيّ على الصلاة، حيّ على الفلاح."
                val notificationId = prefs.getInt(KEY_PREFIX + id + KEY_NOTIFICATION_ID, 10000 + id)
                persist(context, id, timeMillis, sound, title, body, notificationId)
                scheduleNativeAlarm(context, id, timeMillis, sound, title, body, notificationId)
            }
        } finally {
            connection.disconnect()
            scheduleMaintenance(context)
        }
    }

    private fun readDouble(prefs: android.content.SharedPreferences, primary: String, fallback: String): Double? {
        val primaryValue = prefs.all[primary]
        val fallbackValue = prefs.all[fallback]
        return when (val value = primaryValue ?: fallbackValue) {
            is Float -> value.toDouble()
            is Double -> value
            is Long -> value.toDouble()
            is Int -> value.toDouble()
            is String -> value.toDoubleOrNull()
            else -> null
        }
    }

    private fun scheduleNativeAlarm(context: Context, id: Int, timeMillis: Long, soundName: String, title: String, body: String, notificationId: Int) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, AdhanAlarmReceiver::class.java).apply {
            putExtra(AdhanAlarmReceiver.EXTRA_SOUND, soundName)
            putExtra(AdhanAlarmReceiver.EXTRA_TITLE, title)
            putExtra(AdhanAlarmReceiver.EXTRA_BODY, body)
            putExtra(AdhanAlarmReceiver.EXTRA_NOTIFICATION_ID, notificationId)
        }
        val pendingIntent = PendingIntent.getBroadcast(context, id, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S || alarmManager.canScheduleExactAlarms()) {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timeMillis, pendingIntent)
            } else {
                alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timeMillis, pendingIntent)
            }
        } else {
            alarmManager.setExact(AlarmManager.RTC_WAKEUP, timeMillis, pendingIntent)
        }
    }

    private fun cancelAlarm(context: Context, id: Int) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pendingIntent = PendingIntent.getBroadcast(context, id, Intent(context, AdhanAlarmReceiver::class.java), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        alarmManager.cancel(pendingIntent)
        pendingIntent.cancel()
    }

    fun rescheduleStored(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val now = System.currentTimeMillis()
        val currentDate = dateString(now)
        val currentOffset = TimeZone.getDefault().getOffset(now)
        for (slot in 0 until MAX_ALARMS) {
            val id = slot * 10 + 2
            val prefix = KEY_PREFIX + id
            val time = prefs.getLong(prefix + KEY_TIME, 0L)
            val sound = prefs.getString(prefix + KEY_SOUND, null)
            val storedDate = prefs.getString(prefix + KEY_DATE, null)
            val storedOffset = prefs.getInt(prefix + KEY_TZ_OFFSET, Int.MIN_VALUE)
            if (time <= now || sound.isNullOrBlank() || storedDate != currentDate || storedOffset != currentOffset) {
                cancelAlarm(context, id)
                remove(context, id)
                continue
            }
            scheduleNativeAlarm(context, id, time, sound, prefs.getString(prefix + KEY_TITLE, "حان وقت الصلاة") ?: "حان وقت الصلاة", prefs.getString(prefix + KEY_BODY, "حيّ على الصلاة، حيّ على الفلاح.") ?: "حيّ على الصلاة، حيّ على الفلاح.", prefs.getInt(prefix + KEY_NOTIFICATION_ID, 10000 + id))
        }
        scheduleMaintenance(context)
    }
}