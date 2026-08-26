from pathlib import Path

path = Path("lib/services/notification_service.dart")
text = path.read_text(encoding="utf-8")

if "package:flutter/services.dart" not in text:
    marker = "import 'package:flutter/material.dart';\n"
    text = text.replace(marker, marker + "import 'package:flutter/services.dart';\n", 1)

if "static const MethodChannel _nativePrePrayerAlarm" not in text:
    marker = "  static final NotificationService instance = NotificationService._();\n"
    text = text.replace(
        marker,
        marker + "  static const MethodChannel _nativePrePrayerAlarm = MethodChannel('aqim/pre_prayer_alarm');\n",
        1,
    )

start = text.index("  Future<void> _scheduleWakeAlarm({")
end = text.index("\n  Future<void> _scheduleFajrWakeAlarms", start)

replacement = '''  Future<void> _scheduleWakeAlarm({required int id, required String title, required String body, required DateTime scheduledDate, required String soundName, required String payload}) async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('pre_prayer_alert_mode') ?? 'alarm';

    // A notification sound is intentionally not used for the dedicated
    // "alarm" mode: Android notification sounds may be shortened by the OEM.
    // The native exact-alarm + foreground MediaPlayer path lets the selected
    // alarm audio play for its full duration while keeping ringtone/vibrate
    // modes on the existing notification path.
    if (mode == 'alarm' && exactAlarmPermissionGranted) {
      final safeDate = _safeFallbackDate(scheduledDate);
      if (!safeDate.isAfter(DateTime.now())) return;
      await _nativePrePrayerAlarm.invokeMethod('cancel', {'id': id});
      await _nativePrePrayerAlarm.invokeMethod('schedule', {
        'id': id,
        'timeMillis': safeDate.millisecondsSinceEpoch,
        'soundName': soundName,
        'title': title,
        'body': body,
      });
      return;
    }

    await _nativePrePrayerAlarm.invokeMethod('cancel', {'id': id});
    final selectedSound = mode == 'alarm' ? soundName : null;
    final channelSuffix = mode == 'alarm' ? 'alarm_$soundName' : mode;
    final details = NotificationDetails(android: AndroidNotificationDetails('aqim_pre_prayer_${_channelVersion}_$channelSuffix', 'التنبيه قبل الصلاة', channelDescription: mode == 'alarm' ? 'منبه صوتي قبل الصلاة — ليس أذانًا' : mode == 'ringtone' ? 'تنبيه قبل الصلاة برنة الهاتف' : 'تنبيه قبل الصلاة بالاهتزاز فقط', importance: Importance.max, priority: Priority.max, category: AndroidNotificationCategory.alarm, fullScreenIntent: true, playSound: mode != 'vibrate', sound: selectedSound == null ? null : RawResourceAndroidNotificationSound(selectedSound), audioAttributesUsage: AudioAttributesUsage.alarm, channelBypassDnd: notificationPolicyAccessGranted, enableVibration: true, visibility: NotificationVisibility.public));
    await _scheduleExact(id: id, title: title, body: body, scheduledDate: scheduledDate, payload: payload, details: details);
  }
'''

text = text[:start] + replacement + text[end:]
path.write_text(text, encoding="utf-8")
print("Persistent pre-prayer alarm patch applied")
