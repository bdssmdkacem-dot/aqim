package com.aqim.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import java.io.File

class PrePrayerAlarmService : Service() {
    private var player: MediaPlayer? = null
    private var activeSoundName: String? = null
    private var wakeLock: PowerManager.WakeLock? = null

    override fun onCreate() {
        super.onCreate()
        createChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val rawSoundName = intent?.getStringExtra(EXTRA_SOUND)
            ?: run { stopSelf(startId); return START_NOT_STICKY }
        val soundName = rawSoundName.trim()
        val title = intent.getStringExtra(EXTRA_TITLE) ?: "استعد للصلاة"
        val body = intent.getStringExtra(EXTRA_BODY) ?: "حان وقت الاستعداد للصلاة."
        val notificationId = intent.getIntExtra(EXTRA_NOTIFICATION_ID, DEFAULT_NOTIFICATION_ID)

        if (player?.isPlaying == true && activeSoundName == soundName) return START_NOT_STICKY

        startForegroundCompat(notificationId, buildNotification(title, body, notificationId))
        releasePlayer()

        val resId = resources.getIdentifier(soundName, "raw", packageName)
        if (resId == 0) {
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf(startId)
            return START_NOT_STICKY
        }

        try {
            val asset = resources.openRawResourceFd(resId)
                ?: throw IllegalStateException("Unable to open pre-prayer asset: $soundName")
            val newPlayer = MediaPlayer()
            newPlayer.setWakeMode(applicationContext, PowerManager.PARTIAL_WAKE_LOCK)
            newPlayer.setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build()
            )
            asset.use {
                newPlayer.setDataSource(it.fileDescriptor, it.startOffset, it.length)
            }
            newPlayer.isLooping = false
            newPlayer.setOnCompletionListener {
                if (player === newPlayer) {
                    releasePlayer()
                    stopForeground(STOP_FOREGROUND_REMOVE)
                    stopSelf()
                }
            }
            newPlayer.setOnErrorListener { _, _, _ ->
                if (player === newPlayer) {
                    releasePlayer()
                    stopForeground(STOP_FOREGROUND_REMOVE)
                    stopSelf()
                }
                true
            }
            newPlayer.prepare()
            player = newPlayer
            activeSoundName = soundName
            acquireWakeLock()
            newPlayer.start()
        } catch (_: Exception) {
            releasePlayer()
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf(startId)
        }
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        releasePlayer()
        releaseWakeLock()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun startForegroundCompat(notificationId: Int, notification: Notification) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                notificationId,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
            )
        } else {
            startForeground(notificationId, notification)
        }
    }

    private fun acquireWakeLock() {
        if (wakeLock?.isHeld == true) return
        val pm = getSystemService(POWER_SERVICE) as PowerManager
        wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "Aqim:PrePrayerAudio").apply {
            setReferenceCounted(false)
            acquire()
        }
    }

    private fun releaseWakeLock() {
        try { wakeLock?.release() } catch (_: Exception) {}
        wakeLock = null
    }

    private fun releasePlayer() {
        val current = player ?: run {
            activeSoundName = null
            return
        }
        try { current.setOnCompletionListener(null) } catch (_: Exception) {}
        try { current.setOnErrorListener(null) } catch (_: Exception) {}
        try { if (current.isPlaying) current.stop() } catch (_: Exception) {}
        try { current.reset() } catch (_: Exception) {}
        try { current.release() } catch (_: Exception) {}
        player = null
        activeSoundName = null
        releaseWakeLock()
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "منبه قبل الصلاة",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "تنبيه صوتي قبل وقت الصلاة"
            setSound(null, null)
            enableVibration(true)
        }
        getSystemService(NotificationManager::class.java)?.createNotificationChannel(channel)
    }

    private fun buildNotification(title: String, body: String, notificationId: Int): Notification {
        val stopIntent = Intent(this, StopPrePrayerReceiver::class.java).apply {
            putExtra(StopPrePrayerReceiver.EXTRA_NOTIFICATION_ID, notificationId)
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
            .setSmallIcon(com.aqim.app.R.drawable.aqim_logo_transparent_512)
            .setContentTitle(title)
            .setContentText(body)
            .setOngoing(false)
            .setAutoCancel(true)
            .setDeleteIntent(stopPendingIntent)
            .setCategory(Notification.CATEGORY_ALARM)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .addAction(Notification.Action.Builder(null, "إيقاف التنبيه", stopPendingIntent).build())
            .build()
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