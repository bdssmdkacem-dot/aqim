package com.comptaflow.aqim

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val batteryChannel = "aqim/battery"
    private val prePrayerAlarmChannel = "aqim/pre_prayer_alarm"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, batteryChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "isIgnoringBatteryOptimizations" -> result.success(isIgnoringBatteryOptimizations())
                "requestIgnoreBatteryOptimizations" -> { requestIgnoreBatteryOptimizations(); result.success(true) }
                "openBatterySettings" -> { try { startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)); result.success(true) } catch (_: Exception) { try { startActivity(Intent(Settings.ACTION_SETTINGS)); result.success(true) } catch (_: Exception) { result.success(false) } } }
                else -> result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, prePrayerAlarmChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "schedule" -> {
                    val id = call.argument<Int>("id") ?: return@setMethodCallHandler result.error("ARG", "Missing id", null)
                    val timeMillis = call.argument<Long>("timeMillis") ?: return@setMethodCallHandler result.error("ARG", "Missing timeMillis", null)
                    val soundName = call.argument<String>("soundName") ?: return@setMethodCallHandler result.error("ARG", "Missing soundName", null)
                    schedulePrePrayerAlarm(id, timeMillis, soundName, call.argument<String>("title") ?: "استعد للصلاة", call.argument<String>("body") ?: "حان وقت الاستعداد للصلاة.")
                    result.success(true)
                }
                "scheduleAdhan" -> {
                    val id = call.argument<Int>("id") ?: return@setMethodCallHandler result.error("ARG", "Missing id", null)
                    val timeMillis = call.argument<Long>("timeMillis") ?: return@setMethodCallHandler result.error("ARG", "Missing timeMillis", null)
                    val soundName = call.argument<String>("soundName") ?: return@setMethodCallHandler result.error("ARG", "Missing soundName", null)
                    val title = call.argument<String>("title") ?: "حان وقت الصلاة"
                    val body = call.argument<String>("body") ?: "حيّ على الصلاة، حيّ على الفلاح."
                    val notificationId = call.argument<Int>("notificationId") ?: (10000 + id)
                    scheduleAdhanAlarm(id, timeMillis, soundName, title, body, notificationId)
                    AdhanAlarmScheduler.persist(this, id, timeMillis, soundName, title, body, notificationId)
                    result.success(true)
                }
                "cancel" -> {
                    val id = call.argument<Int>("id") ?: return@setMethodCallHandler result.error("ARG", "Missing id", null)
                    cancelPrePrayerAlarm(id); cancelAdhanAlarm(id); AdhanAlarmScheduler.remove(this, id); result.success(true)
                }
                "cancelAdhan" -> {
                    val id = call.argument<Int>("id") ?: return@setMethodCallHandler result.error("ARG", "Missing id", null)
                    cancelAdhanAlarm(id); AdhanAlarmScheduler.remove(this, id); result.success(true)
                }
                "cancelAllAdhanAlarms" -> { cancelAllAdhanAlarms(); AdhanAlarmScheduler.clearAll(this); result.success(true) }
                else -> result.notImplemented()
            }
        }
    }

    private fun schedulePrePrayerAlarm(id: Int, timeMillis: Long, soundName: String, title: String, body: String) {
        schedulePrePrayerAlarm(id, timeMillis, soundName, title, body, PrePrayerAlarmReceiver.DEFAULT_NOTIFICATION_ID)
    }
    private fun schedulePrePrayerAlarm(id: Int, timeMillis: Long, soundName: String, title: String, body: String, notificationId: Int) {
        val alarmManager = getSystemService(ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, PrePrayerAlarmReceiver::class.java).apply { putExtra(PrePrayerAlarmReceiver.EXTRA_SOUND, soundName); putExtra(PrePrayerAlarmReceiver.EXTRA_TITLE, title); putExtra(PrePrayerAlarmReceiver.EXTRA_BODY, body); putExtra(PrePrayerAlarmReceiver.EXTRA_NOTIFICATION_ID, notificationId) }
        val pendingIntent = PendingIntent.getBroadcast(this, id, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timeMillis, pendingIntent) else alarmManager.setExact(AlarmManager.RTC_WAKEUP, timeMillis, pendingIntent)
    }
    private fun scheduleAdhanAlarm(id: Int, timeMillis: Long, soundName: String, title: String, body: String, notificationId: Int) {
        val alarmManager = getSystemService(ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, AdhanAlarmReceiver::class.java).apply { putExtra(AdhanAlarmReceiver.EXTRA_SOUND, soundName); putExtra(AdhanAlarmReceiver.EXTRA_TITLE, title); putExtra(AdhanAlarmReceiver.EXTRA_BODY, body); putExtra(AdhanAlarmReceiver.EXTRA_NOTIFICATION_ID, notificationId) }
        val pendingIntent = PendingIntent.getBroadcast(this, id, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, timeMillis, pendingIntent) else alarmManager.setExact(AlarmManager.RTC_WAKEUP, timeMillis, pendingIntent)
    }
    private fun cancelPrePrayerAlarm(id: Int) { val am = getSystemService(ALARM_SERVICE) as AlarmManager; val pi = PendingIntent.getBroadcast(this, id, Intent(this, PrePrayerAlarmReceiver::class.java), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE); am.cancel(pi); pi.cancel() }
    private fun cancelAdhanAlarm(id: Int) { val am = getSystemService(ALARM_SERVICE) as AlarmManager; val pi = PendingIntent.getBroadcast(this, id, Intent(this, AdhanAlarmReceiver::class.java), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE); am.cancel(pi); pi.cancel() }
    private fun cancelAllAdhanAlarms() { for (prayerIndex in 0..4) cancelAdhanAlarm(prayerIndex * 10 + 2) }
    private fun isIgnoringBatteryOptimizations(): Boolean { if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true; val pm = getSystemService(POWER_SERVICE) as? PowerManager ?: return false; return pm.isIgnoringBatteryOptimizations(packageName) }
    private fun requestIgnoreBatteryOptimizations() { if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M || isIgnoringBatteryOptimizations()) return; try { startActivity(Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply { data = Uri.parse("package:$packageName") }) } catch (_: Exception) { try { startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)) } catch (_: Exception) { startActivity(Intent(Settings.ACTION_SETTINGS)) } } }
}
