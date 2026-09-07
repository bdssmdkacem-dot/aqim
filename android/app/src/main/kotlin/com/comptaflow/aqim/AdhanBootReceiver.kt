package com.aqim.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Restores and re-aligns scheduled native Adhan alarms after system changes. */
class AdhanBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        when (intent?.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            "android.intent.action.TIMEZONE_OFFSET_CHANGED",
            "android.intent.action.QUICKBOOT_POWERON",
            "com.htc.intent.action.QUICKBOOT_POWERON" -> AdhanAlarmScheduler.requestReschedule(context)
        }
    }
}
