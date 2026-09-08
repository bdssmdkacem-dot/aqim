package com.aqim.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class StopPrePrayerReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        context.stopService(Intent(context, PrePrayerAlarmService::class.java))
        val notificationId = intent?.getIntExtra(EXTRA_NOTIFICATION_ID, PrePrayerAlarmService.DEFAULT_NOTIFICATION_ID) ?: PrePrayerAlarmService.DEFAULT_NOTIFICATION_ID
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? android.app.NotificationManager
        manager?.cancel(notificationId)
    }

    companion object {
        const val EXTRA_NOTIFICATION_ID = "notification_id"
    }
}
