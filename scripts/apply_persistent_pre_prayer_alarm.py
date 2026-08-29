from pathlib import Path

# IMPORTANT: pre-prayer alerts must stay on the existing
# flutter_local_notifications path. This patch is ONLY for the adhan that
# starts at the actual prayer time.
path = Path("lib/services/notification_service.dart")
text = path.read_text(encoding="utf-8")

if "package:flutter/services.dart" not in text:
    text = text.replace(
        "import 'package:flutter/material.dart';\n",
        "import 'package:flutter/material.dart';\nimport 'package:flutter/services.dart';\n",
        1,
    )

if "static const MethodChannel _nativeAdhanChannel" not in text:
    marker = "  static final NotificationService instance = NotificationService._();\n"
    text = text.replace(
        marker,
        marker + "  static const MethodChannel _nativeAdhanChannel = MethodChannel('aqim/pre_prayer_alarm');\n",
        1,
    )

start = text.index("  Future<void> _scheduleAdhan({")
end = text.index("\n  Future<void> _scheduleCheckIn", start)

replacement = '''  Future<void> _scheduleAdhan({required Prayer prayer, required int id, required String title, required String body, required DateTime scheduledDate, required String payload}) async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('adhan_alert_mode') ?? 'adhan';
    if (mode == 'vibrate') {
      await _scheduleExact(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        payload: payload,
        details: NotificationDetails(
          android: AndroidNotificationDetails(
            'aqim_adhan_${_channelVersion}_vibrate',
            'الأذان',
            channelDescription: 'تنبيه وقت الصلاة بالاهتزاز فقط',
            importance: Importance.max,
            priority: Priority.max,
            category: AndroidNotificationCategory.alarm,
            fullScreenIntent: true,
            playSound: false,
            enableVibration: true,
            visibility: NotificationVisibility.public,
          ),
        ),
      );
      return;
    }

    if (mode == 'ringtone') {
      await _scheduleExact(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        payload: payload,
        details: _alarmDetails(
          channelId: 'aqim_adhan_${_channelVersion}_ringtone',
          channelName: 'الأذان',
          channelDescription: 'تنبيه وقت الصلاة برنة الهاتف',
          category: AndroidNotificationCategory.alarm,
        ),
      );
      return;
    }

    final selectedSound = prayer == Prayer.fajr
        ? ((prefs.getString('adhan_fajr_sound') ?? 'azan-fajr') == 'azanfajrmadina'
            ? 'azan-Fajr-madina'
            : (prefs.getString('adhan_fajr_sound') ?? 'azan-fajr'))
        : (prefs.getString('adhan_sound') ?? 'azan_maroc_1');

    final safeDate = _safeFallbackDate(scheduledDate);
    if (!safeDate.isAfter(DateTime.now())) return;

    // The adhan is the actual prayer-time audio. Use the native exact alarm
    // receiver + foreground MediaPlayer so Android plays the whole file.
    await _nativeAdhanChannel.invokeMethod('cancel', {'id': id});
    await _nativeAdhanChannel.invokeMethod('scheduleAdhan', {
      'id': id,
      'timeMillis': safeDate.millisecondsSinceEpoch,
      'soundName': selectedSound,
      'title': title,
      'body': body,
      'notificationId': 10000 + id,
    });
  }
'''

text = text[:start] + replacement + text[end:]
path.write_text(text, encoding="utf-8")
print("Verified: pre-prayer alerts remain unchanged; prayer-time adhan uses persistent native audio")
