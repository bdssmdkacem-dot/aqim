package com.comptaflow.aqim

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.Build
import android.os.IBinder

class PrePrayerAlarmService : Service() {
    private var player: MediaPlayer? = null
    private var activeSoundName: String? = null

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
        val notificationId = intent.getIntExtra(EXTRA_NOTIFICATION_ID, DEFAULT_NOTIFICATION_ID)

        // A duplicated delivery must never restart an adhan that is already playing.
        if (player?.isPlaying == true && activeSoundName == soundName) {
            return START_NOT_STICKY
        }

        startForeground(notificationId, buildNotification(title, body, notificationId))
        player?.stopSafely()
        player?.release()
        player = null
        activeSoundName = null

        val resId = resources.getIdentifier(soundName.trim(), "raw", packageName)
        if (resId == 0) {
            stopSelf(startId)
            return START_NOT_STICKY
        }

        try {
            player = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build()
                )
                setDataSource(resources.openRawResourceFd(resId))
                prepare()
                isLooping = false
                setOnCompletionListener { stopSelf() }
                setOnErrorListener { _, _, _ -> stopSelf(); true }
                start()
            }
            activeSoundName = soundName
        } catch (_: Exception) {
            player?.release()
            player = null
            activeSoundName = null
            stopSelf(startId)
        }

        return START_NOT_STICKY
    }

    override fun onDestroy() {
        player?.stopSafely()
        player?.release()
        player = null
        activeSoundName = null
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "أذان ومنبه أقم",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "تشغيل صوت الأذان والمنبه لمدة الملف الصوتي كاملة"
            setSound(null, null)
            enableVibration(true)
        }
        getSystemService(NotificationManager::class.java)?.createNotificationChannel(channel)
    }

    private fun buildNotification(title: String, body: String, notificationId: Int): Notification {
        val stopIntent = Intent(this, StopAdhanReceiver::class.java).apply {
            putExtra(StopAdhanReceiver.EXTRA_NOTIFICATION_ID, notificationId)
        }
        val stopPendingIntent = PendingIntent.getBroadcast(
            this,
            notificationId,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
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
            .addAction(Notification.Action.Builder(null, "إيقاف الأذان", stopPendingIntent).build())
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
        const val EXTRA_NOTIFICATION_ID = "notification_id"
        const val DEFAULT_NOTIFICATION_ID = 7300
        private const val CHANNEL_ID = "aqim_alarm_audio_service_v2"
    }
}
