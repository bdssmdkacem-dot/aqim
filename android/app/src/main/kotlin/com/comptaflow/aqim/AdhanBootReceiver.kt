package com.comptaflow.aqim

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Restores scheduled native Adhan alarms after Android clears AlarmManager on reboot. */
class AdhanBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        when (intent?.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            "android.intent.action.QUICKBOOT_POWERON",
            "com.htc.intent.action.QUICKBOOT_POWERON" -> {
                AdhanAlarmScheduler.requestReschedule(context)
            }
        }
    }
}
