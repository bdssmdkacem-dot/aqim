package com.comptaflow.aqim

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import java.util.TimeZone

/** Persists and restores only the dedicated native Adhan alarms across reboot. */
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
    private const val MAX_ALARMS = 5

    fun persist(context: Context, id: Int, timeMillis: Long, soundName: String, title: String, body: String, notificationId: Int) {
        val date = java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.US).apply {
            timeZone = TimeZone.getDefault()
        }.format(java.util.Date(timeMillis))
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putInt(KEY_PREFIX + id + KEY_ID, id)
            .putLong(KEY_PREFIX + id + KEY_TIME, timeMillis)
            .putString(KEY_PREFIX + id + KEY_SOUND, soundName)
            .putString(KEY_PREFIX + id + KEY_TITLE, title)
            .putString(KEY_PREFIX + id + KEY_BODY, body)
            .putInt(KEY_PREFIX + id + KEY_NOTIFICATION_ID, notificationId)
            .putString(KEY_PREFIX + id + KEY_DATE, date)
            .putInt(KEY_PREFIX + id + KEY_TZ_OFFSET, TimeZone.getDefault().getOffset(timeMillis))
            .apply()
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
    }

    fun requestReschedule(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val canExact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S || alarmManager.canScheduleExactAlarms()

        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val now = System.currentTimeMillis()
        val currentDate = java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.US).apply {
            timeZone = TimeZone.getDefault()
        }.format(java.util.Date(now))
        val currentOffset = TimeZone.getDefault().getOffset(now)

        for (slot in 0 until MAX_ALARMS) {
            val id = slot * 10 + 2
            val prefix = KEY_PREFIX + id
            val time = prefs.getLong(prefix + KEY_TIME, 0L)
            val sound = prefs.getString(prefix + KEY_SOUND, null)
            val storedDate = prefs.getString(prefix + KEY_DATE, null)
            val storedOffset = prefs.getInt(prefix + KEY_TZ_OFFSET, Int.MIN_VALUE)

            if (time <= now || sound.isNullOrBlank() || storedDate != currentDate || storedOffset != currentOffset) {
                cancelAlarm(alarmManager, context, id)
                remove(context, id)
                continue
            }

            val pendingIntent = PendingIntent.getBroadcast(
                context,
                id,
                Intent(context, AdhanAlarmReceiver::class.java).apply {
                    putExtra(AdhanAlarmReceiver.EXTRA_SOUND, sound)
                    putExtra(AdhanAlarmReceiver.EXTRA_TITLE, prefs.getString(prefix + KEY_TITLE, "حان وقت الصلاة"))
                    putExtra(AdhanAlarmReceiver.EXTRA_BODY, prefs.getString(prefix + KEY_BODY, "حيّ على الصلاة، حيّ على الفلاح."))
                    putExtra(AdhanAlarmReceiver.EXTRA_NOTIFICATION_ID, prefs.getInt(prefix + KEY_NOTIFICATION_ID, 10000 + id))
                },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !canExact) {
                // Do not silently downgrade a prayer Adhan to an inexact alarm.
                // The Flutter layer requests the special Alarms & reminders access.
                continue
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, time, pendingIntent)
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, time, pendingIntent)
            }
        }
    }

    private fun cancelAlarm(alarmManager: AlarmManager, context: Context, id: Int) {
        val pendingIntent = PendingIntent.getBroadcast(context, id, Intent(context, AdhanAlarmReceiver::class.java), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        alarmManager.cancel(pendingIntent)
        pendingIntent.cancel()
    }
}
