package com.comptaflow.aqim

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class PrePrayerAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val soundName = intent.getStringExtra(EXTRA_SOUND) ?: return
        val title = intent.getStringExtra(EXTRA_TITLE) ?: "استعد للصلاة"
        val body = intent.getStringExtra(EXTRA_BODY) ?: "حان وقت الاستعداد للصلاة."
        val serviceIntent = Intent(context, PrePrayerAlarmService::class.java).apply {
            putExtra(PrePrayerAlarmService.EXTRA_SOUND, soundName)
            putExtra(PrePrayerAlarmService.EXTRA_TITLE, title)
            putExtra(PrePrayerAlarmService.EXTRA_BODY, body)
        }
        androidx.core.content.ContextCompat.startForegroundService(context, serviceIntent)
    }

    companion object {
        const val EXTRA_SOUND = "sound_name"
        const val EXTRA_TITLE = "title"
        const val EXTRA_BODY = "body"
    }
}
