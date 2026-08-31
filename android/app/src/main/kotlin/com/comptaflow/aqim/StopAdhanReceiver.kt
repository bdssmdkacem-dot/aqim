package com.comptaflow.aqim

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Stops the actual prayer-time adhan service, not the pre-prayer alert service. */
class StopAdhanReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val notificationId = intent?.getIntExtra(
            EXTRA_NOTIFICATION_ID,
            AdhanAlarmReceiver.DEFAULT_NOTIFICATION_ID
        ) ?: AdhanAlarmReceiver.DEFAULT_NOTIFICATION_ID

        context.stopService(Intent(context, AdhanAlarmService::class.java))

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        manager?.cancel(notificationId)
    }

    companion object {
        const val EXTRA_NOTIFICATION_ID = "notification_id"
    }
}
