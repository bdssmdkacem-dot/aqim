package com.comptaflow.aqim

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat

class AdhanAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val soundName = intent.getStringExtra(EXTRA_SOUND) ?: return
        val title = intent.getStringExtra(EXTRA_TITLE) ?: "حان وقت الصلاة"
        val body = intent.getStringExtra(EXTRA_BODY) ?: "حيّ على الصلاة، حيّ على الفلاح."
        val notificationId = intent.getIntExtra(EXTRA_NOTIFICATION_ID, DEFAULT_NOTIFICATION_ID)
        val serviceIntent = Intent(context, AdhanAlarmService::class.java).apply {
            putExtra(AdhanAlarmService.EXTRA_SOUND, soundName)
            putExtra(AdhanAlarmService.EXTRA_TITLE, title)
            putExtra(AdhanAlarmService.EXTRA_BODY, body)
            putExtra(AdhanAlarmService.EXTRA_NOTIFICATION_ID, notificationId)
        }
        ContextCompat.startForegroundService(context, serviceIntent)
    }

    companion object {
        const val EXTRA_SOUND = "sound_name"
        const val EXTRA_TITLE = "title"
        const val EXTRA_BODY = "body"
        const val EXTRA_NOTIFICATION_ID = "notification_id"
        const val DEFAULT_NOTIFICATION_ID = 10002
    }
}
