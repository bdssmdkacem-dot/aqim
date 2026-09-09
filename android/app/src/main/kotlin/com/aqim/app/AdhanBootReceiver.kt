package com.aqim.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Restores native Adhan alarms without requiring Flutter to be running. */
class AdhanBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        when (intent?.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            "android.intent.action.QUICKBOOT_POWERON",
            "com.htc.intent.action.QUICKBOOT_POWERON" -> {
                AdhanAlarmScheduler.requestReschedule(context)
            }

            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            "android.intent.action.TIMEZONE_OFFSET_CHANGED" -> {
                AdhanAlarmScheduler.requestSystemTimeReschedule(context)
            }
        }
    }
}
