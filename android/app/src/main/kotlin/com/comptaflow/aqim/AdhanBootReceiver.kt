package com.comptaflow.aqim

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Native boot receiver for the dedicated Adhan AlarmManager schedule.
 * It only requests rescheduling; it never starts Adhan playback directly.
 */
class AdhanBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        when (intent?.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            "android.intent.action.QUICKBOOT_POWERON",
            "com.htc.intent.action.QUICKBOOT_POWERON" -> {
                // Native Adhan alarms are recreated by the app's existing scheduling path.
                // Do not start playback from boot.
                AdhanAlarmScheduler.requestReschedule(context)
            }
        }
    }
}
