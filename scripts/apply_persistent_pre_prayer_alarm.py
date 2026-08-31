from pathlib import Path

# IMPORTANT: pre-prayer alerts stay on the existing flutter_local_notifications
# path. This patch is ONLY for the adhan that starts at the actual prayer time.
# Native adhan alarms are also cancelled before every daily reschedule so old
# AlarmManager entries cannot survive a location/time refresh.
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

schedule_marker = "    await _plugin.cancelAll();\n"
if "cancelAllAdhanAlarms" not in text:
    text = text.replace(
        schedule_marker,
        "    // Stage 3: clear native prayer-time alarms before rebuilding today's schedule.\n    await _nativeAdhanChannel.invokeMethod('cancelAllAdhanAlarms');\n    await _plugin.cancelAll();\n",
        1,
    )

start = text.index("  Future<void> _scheduleAdhan({")
end = text.index("\n  Future<void> _scheduleCheckIn", start)

replacement = '''  Future<void> _scheduleAdhan({required Prayer prayer, required int id, required String title, required String body, required DateTime scheduledDate, required String payload}) async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('adhan_alert_mode') ?? 'adhan';

    if (mode != 'adhan') {
      if (mode == 'vibrate') {
        await _scheduleExact(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          payload: payload,
          details: const NotificationDetails(
            android: AndroidNotificationDetails(
              'aqim_adhan_v14_vibrate',
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
      } else {
        await _scheduleExact(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          payload: payload,
          details: _alarmDetails(
            channelId: 'aqim_adhan_v14_ringtone',
            channelName: 'الأذان',
            channelDescription: 'تنبيه وقت الصلاة برنة الهاتف',
            category: AndroidNotificationCategory.alarm,
          ),
        );
      }
      return;
    }

    final selectedSound = prayer == Prayer.fajr
        ? ((prefs.getString('adhan_fajr_sound') ?? 'azan-fajr') == 'azanfajrmadina'
            ? 'azan-Fajr-madina'
            : (prefs.getString('adhan_fajr_sound') ?? 'azan-fajr'))
        : (prefs.getString('adhan_sound') ?? 'azan_maroc_1');

    final safeDate = _safeFallbackDate(scheduledDate);
    if (!safeDate.isAfter(DateTime.now())) return;

    // Stage 1: actual prayer-time adhan has its own native receiver/service.
    // Stage 2: the native service ignores duplicate delivery while the same
    // adhan is already playing, preventing a restart from the beginning.
    await _nativeAdhanChannel.invokeMethod('cancelAdhan', {'id': id});
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
print("Applied stages 1-3: dedicated native adhan lifecycle, duplicate-playback protection, and native alarm cancellation before rescheduling")
