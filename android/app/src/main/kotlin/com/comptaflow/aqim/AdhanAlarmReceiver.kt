package com.comptaflow.aqim

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import androidx.core.content.ContextCompat

class AdhanAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_DAILY_MAINTENANCE) {
            goAsyncRefresh(context)
            return
        }

        val soundName = intent.getStringExtra(EXTRA_SOUND) ?: return
        val title = intent.getStringExtra(EXTRA_TITLE) ?: "حان وقت الصلاة"
        val body = intent.getStringExtra(EXTRA_BODY) ?: "حيّ على الصلاة، حيّ على الفلاح."
        val notificationId = intent.getIntExtra(EXTRA_NOTIFICATION_ID, DEFAULT_NOTIFICATION_ID)
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager
        val exactAvailable = Build.VERSION.SDK_INT < Build.VERSION_CODES.S || alarmManager?.canScheduleExactAlarms() == true

        if (!exactAvailable) {
            postFallbackAdhan(context, soundName, title, body, notificationId)
            return
        }

        val serviceIntent = Intent(context, AdhanAlarmService::class.java).apply {
            putExtra(AdhanAlarmService.EXTRA_SOUND, soundName)
            putExtra(AdhanAlarmService.EXTRA_TITLE, title)
            putExtra(AdhanAlarmService.EXTRA_BODY, body)
            putExtra(AdhanAlarmService.EXTRA_NOTIFICATION_ID, notificationId)
        }
        ContextCompat.startForegroundService(context, serviceIntent)
    }

    private fun goAsyncRefresh(context: Context) {
        val pendingResult = goAsync()
        Thread {
            try {
                AdhanAlarmScheduler.refreshCurrentDayAsyncBlocking(context)
            } finally {
                pendingResult.finish()
            }
        }.start()
    }

    private fun postFallbackAdhan(context: Context, soundName: String, title: String, body: String, notificationId: Int) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return
        val channelId = "aqim_adhan_fallback_$soundName"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val soundUri = Uri.parse("android.resource://${context.packageName}/raw/$soundName")
            val audioAttributes = AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ALARM).setContentType(AudioAttributes.CONTENT_TYPE_MUSIC).build()
            val channel = NotificationChannel(channelId, "أذان أقم", NotificationManager.IMPORTANCE_HIGH).apply {
                description = "الأذان عند دخول وقت الصلاة"
                setSound(soundUri, audioAttributes)
                enableVibration(true)
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            }
            manager.createNotificationChannel(channel)
        }
        val stopIntent = Intent(context, StopAdhanReceiver::class.java).apply { putExtra(StopAdhanReceiver.EXTRA_NOTIFICATION_ID, notificationId) }
        val stopPendingIntent = PendingIntent.getBroadcast(context, notificationId, stopIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val notification = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            android.app.Notification.Builder(context, channelId)
                .setSmallIcon(com.comptaflow.aqim.R.drawable.ic_aqim_logo)
                .setContentTitle(title).setContentText(body)
                .setCategory(android.app.Notification.CATEGORY_ALARM)
                .setPriority(android.app.Notification.PRIORITY_MAX)
                .setVisibility(android.app.Notification.VISIBILITY_PUBLIC)
                .setOngoing(true)
                .addAction(android.app.Notification.Action.Builder(android.graphics.drawable.Icon.createWithResource(context, com.comptaflow.aqim.R.drawable.ic_aqim_notification), "إيقاف الأذان", stopPendingIntent).build())
                .build()
        } else {
            android.app.Notification.Builder(context)
                .setSmallIcon(com.comptaflow.aqim.R.drawable.ic_aqim_logo)
                .setContentTitle(title).setContentText(body)
                .setSound(Uri.parse("android.resource://${context.packageName}/raw/$soundName"), AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ALARM).build())
                .setCategory(android.app.Notification.CATEGORY_ALARM)
                .setPriority(android.app.Notification.PRIORITY_MAX)
                .setOngoing(true)
                .addAction(android.app.Notification.Action.Builder(android.graphics.drawable.Icon.createWithResource(context, com.comptaflow.aqim.R.drawable.ic_aqim_notification), "إيقاف الأذان", stopPendingIntent).build())
                .build()
        }
        manager.notify(notificationId, notification)
    }

    companion object {
        const val ACTION_DAILY_MAINTENANCE = "com.comptaflow.aqim.action.DAILY_ADHAN_MAINTENANCE"
        const val EXTRA_SOUND = "sound_name"
        const val EXTRA_TITLE = "title"
        const val EXTRA_BODY = "body"
        const val EXTRA_NOTIFICATION_ID = "notification_id"
        const val DEFAULT_NOTIFICATION_ID = 10002
    }
}