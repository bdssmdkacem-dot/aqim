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

class AdhanAlarmService : Service() {
    private var player: MediaPlayer? = null
    private var activeSoundName: String? = null
    private var activeNotificationId: Int? = null

    override fun onCreate() {
        super.onCreate()
        createChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val soundName = intent?.getStringExtra(EXTRA_SOUND)?.trim() ?: run {
            stopSelf(startId)
            return START_NOT_STICKY
        }
        val title = intent.getStringExtra(EXTRA_TITLE) ?: "حان وقت الصلاة"
        val body = intent.getStringExtra(EXTRA_BODY) ?: "حيّ على الصلاة، حيّ على الفلاح."
        val notificationId = intent.getIntExtra(EXTRA_NOTIFICATION_ID, AdhanAlarmReceiver.DEFAULT_NOTIFICATION_ID)

        // Duplicate delivery: never interrupt or restart an adhan already playing.
        if (player?.isPlaying == true && activeSoundName == soundName) {
            return START_NOT_STICKY
        }

        startForeground(notificationId, buildNotification(title, body, notificationId))
        releasePlayer()

        val resId = resources.getIdentifier(soundName, "raw", packageName)
        if (resId == 0) {
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf(startId)
            return START_NOT_STICKY
        }

        try {
            val afd = resources.openRawResourceFd(resId)
                ?: throw IllegalStateException("Audio resource descriptor unavailable")
            val newPlayer = MediaPlayer()
            newPlayer.setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build()
            )
            newPlayer.setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
            afd.close()
            newPlayer.prepare()
            newPlayer.isLooping = false
            newPlayer.setOnCompletionListener {
                // Natural completion is terminal: clean up and remove the foreground service.
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
            player = newPlayer
            activeSoundName = soundName
            activeNotificationId = notificationId
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
        activeNotificationId = null
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun releasePlayer() {
        val current = player ?: run {
            activeSoundName = null
            return
        }
        try {
            current.setOnCompletionListener(null)
            current.setOnErrorListener(null)
        } catch (_: Exception) {
        }
        try {
            if (current.isPlaying) current.stop()
        } catch (_: Exception) {
        }
        try {
            current.reset()
        } catch (_: Exception) {
        }
        try {
            current.release()
        } catch (_: Exception) {
        }
        player = null
        activeSoundName = null
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "أذان أقم",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "تشغيل أذان وقت الصلاة بالكامل"
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

    companion object {
        const val EXTRA_SOUND = "sound_name"
        const val EXTRA_TITLE = "title"
        const val EXTRA_BODY = "body"
        const val EXTRA_NOTIFICATION_ID = "notification_id"
        private const val CHANNEL_ID = "aqim_adhan_audio_service_v1"
    }
}
