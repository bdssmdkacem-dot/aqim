package com.comptaflow.aqim

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.Build
import android.os.IBinder

class PrePrayerAlarmService : Service() {
    private var player: MediaPlayer? = null

    override fun onCreate() {
        super.onCreate()
        createChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val soundName = intent?.getStringExtra(EXTRA_SOUND) ?: run {
            stopSelf(startId)
            return START_NOT_STICKY
        }
        val title = intent.getStringExtra(EXTRA_TITLE) ?: "استعد للصلاة"
        val body = intent.getStringExtra(EXTRA_BODY) ?: "حان وقت الاستعداد للصلاة."

        startForeground(NOTIFICATION_ID, buildNotification(title, body))
        player?.release()
        player = null

        val resId = resources.getIdentifier(soundName, "raw", packageName)
        if (resId == 0) {
            stopSelf(startId)
            return START_NOT_STICKY
        }

        player = MediaPlayer.create(this, resId)?.apply {
            setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build()
            )
            isLooping = false
            setOnCompletionListener { stopSelf() }
            setOnErrorListener { _, _, _ -> stopSelf(); true }
            start()
        }

        if (player == null) stopSelf(startId)
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        player?.stopSafely()
        player?.release()
        player = null
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "منبه قبل الصلاة",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "منبه صوتي مستمر قبل الصلاة"
            setSound(null, null)
            enableVibration(true)
        }
        getSystemService(NotificationManager::class.java)?.createNotificationChannel(channel)
    }

    private fun buildNotification(title: String, body: String): Notification {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            Notification.Builder(this)
        }
        return builder
            .setSmallIcon(com.comptaflow.aqim.R.drawable.ic_aqim_logo)
            .setContentTitle(title)
            .setContentText(body)
            .setOngoing(true)
            .setCategory(Notification.CATEGORY_ALARM)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .build()
    }

    private fun MediaPlayer.stopSafely() {
        try {
            if (isPlaying) stop()
        } catch (_: Exception) {
        }
    }

    companion object {
        const val EXTRA_SOUND = "sound_name"
        const val EXTRA_TITLE = "title"
        const val EXTRA_BODY = "body"
        private const val CHANNEL_ID = "aqim_pre_prayer_alarm_service_v1"
        private const val NOTIFICATION_ID = 7300
    }
}
