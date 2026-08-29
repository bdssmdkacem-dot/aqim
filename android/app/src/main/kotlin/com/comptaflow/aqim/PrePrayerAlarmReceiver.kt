package com.comptaflow.aqim

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class PrePrayerAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val soundName = intent.getStringExtra(EXTRA_SOUND) ?: return
        val title = intent.getStringExtra(EXTRA_TITLE) ?: "استعد للصلاة"
        val body = intent.getStringExtra(EXTRA_BODY) ?: "حان وقت الاستعداد للصلاة."
        val notificationId = intent.getIntExtra(EXTRA_NOTIFICATION_ID, DEFAULT_NOTIFICATION_ID)
        val serviceIntent = Intent(context, PrePrayerAlarmService::class.java).apply {
            putExtra(PrePrayerAlarmService.EXTRA_SOUND, soundName)
            putExtra(PrePrayerAlarmService.EXTRA_TITLE, title)
            putExtra(PrePrayerAlarmService.EXTRA_BODY, body)
            putExtra(PrePrayerAlarmService.EXTRA_NOTIFICATION_ID, notificationId)
        }
        androidx.core.content.ContextCompat.startForegroundService(context, serviceIntent)
    }

    companion object {
        const val EXTRA_SOUND = "sound_name"
        const val EXTRA_TITLE = "title"
        const val EXTRA_BODY = "body"
        const val EXTRA_NOTIFICATION_ID = "notification_id"
        const val DEFAULT_NOTIFICATION_ID = 7300
    }
}
