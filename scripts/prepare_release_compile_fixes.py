from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

# The AppState action extension must be imported by each library that calls its
# extension methods. Keep this as a build-time safety net for the current
# source layout without changing any runtime behavior.
for path in (ROOT / 'lib').rglob('*.dart'):
    text = path.read_text(encoding='utf-8')
    if "import 'state/app_state.dart';" in text and "import 'state/app_state_actions.dart';" not in text:
        text = text.replace(
            "import 'state/app_state.dart';",
            "import 'state/app_state.dart';\nimport 'state/app_state_actions.dart';",
            1,
        )
    if "import '../state/app_state.dart';" in text and "import '../state/app_state_actions.dart';" not in text:
        text = text.replace(
            "import '../state/app_state.dart';",
            "import '../state/app_state.dart';\nimport '../state/app_state_actions.dart';",
            1,
        )
    path.write_text(text, encoding='utf-8')

main = ROOT / 'lib/main.dart'
text = main.read_text(encoding='utf-8')
if "import 'package:provider/provider.dart'" not in text:
    text = text.replace(
        "import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;",
        "import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;\nimport 'package:provider/provider.dart';",
        1,
    )
main.write_text(text, encoding='utf-8')

ad = ROOT / 'lib/ads/app_interstitial_ad.dart'
text = ad.read_text(encoding='utf-8')
if 'static void showThen(' not in text:
    marker = "  static void showIfEligible() {"
    method = """  /// Shows the preloaded ad when available and runs [onComplete] after
  /// dismissal. If no ad is ready, continues immediately.
  static void showThen(void Function() onComplete) {
    final ad = _ad;
    if (ad == null) {
      preload();
      onComplete();
      return;
    }

    _ad = null;
    var completed = false;
    void complete() {
      if (completed) return;
      completed = true;
      onComplete();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        preload();
        complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Interstitial failed to show: $error');
        ad.dispose();
        preload();
        complete();
      },
    );
    ad.show();
  }

"""
    text = text.replace(marker, method + marker, 1)
ad.write_text(text, encoding='utf-8')

# Keep Qibla behind the existing interstitial. The weekly report remains an
# interstitial action as well; worship/prayer alerts are never monetized.
home = ROOT / 'lib/screens/home_screen.dart'
text = home.read_text(encoding='utf-8')
old_qibla_direct = "onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QiblaScreen()))"
new_qibla = "onTap: () => AppInterstitialAd.showThen(() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QiblaScreen())))"
text = text.replace(old_qibla_direct, new_qibla, 1)
home.write_text(text, encoding='utf-8')

# Notification correctness fixes. Do not change notification text/content.
notifications = ROOT / 'lib/services/notification_service.dart'
text = notifications.read_text(encoding='utf-8')
text = text.replace(
    "  DateTime _safeFallbackDate(DateTime scheduledDate) => exactAlarmPermissionGranted ? scheduledDate : scheduledDate.add(const Duration(minutes: 2));",
    "  DateTime _safeFallbackDate(DateTime scheduledDate) => scheduledDate;",
    1,
)
text = text.replace(
    "  Future<bool> refreshNotificationPolicyAccess() async { await init(); return notificationPolicyAccessGranted; }",
    "  Future<bool> refreshNotificationPolicyAccess() async {\n    await init();\n    final android = _android;\n    if (android == null) return false;\n    try {\n      notificationPolicyAccessGranted = await android.hasNotificationPolicyAccess() ?? false;\n    } catch (_) {}\n    return notificationPolicyAccessGranted;\n  }",
    1,
)
text = text.replace("'azan-Fajr-madina '", "'azan-Fajr-madina'", 1)
text = text.replace(
    "    await refreshExactAlarmPermission();\n    if (!exactAlarmPermissionGranted)",
    "    await refreshExactAlarmPermission();\n    await refreshNotificationPolicyAccess();\n    if (!exactAlarmPermissionGranted)",
    1,
)

# In pre-prayer `alarm` mode use the native foreground MediaPlayer path. A
# notification's RawResource sound is intentionally not used for this mode:
# Android can stop it after the short notification playback window, producing
# the reported ~1 second sound. Ringtone and vibrate modes remain unchanged.
old_wake = """  Future<void> _scheduleWakeAlarm({required int id, required String title, required String body, required DateTime scheduledDate, required String soundName, required String payload}) async {
    final prefs = await SharedPreferences.getInstance(); final mode = prefs.getString('pre_prayer_alert_mode') ?? 'alarm'; final selectedSound = mode == 'alarm' ? soundName : null; final channelSuffix = mode == 'alarm' ? 'alarm_$soundName' : mode;
    final details = NotificationDetails(android: AndroidNotificationDetails('aqim_pre_prayer_${_channelVersion}_$channelSuffix', 'التنبيه قبل الصلاة', channelDescription: mode == 'alarm' ? 'منبه صوتي قبل الصلاة — ليس أذانًا' : mode == 'ringtone' ? 'تنبيه قبل الصلاة برنة الهاتف' : 'تنبيه قبل الصلاة بالاهتزاز فقط', importance: Importance.max, priority: Priority.max, category: AndroidNotificationCategory.alarm, fullScreenIntent: true, playSound: mode != 'vibrate', sound: selectedSound == null ? null : RawResourceAndroidNotificationSound(selectedSound), audioAttributesUsage: AudioAttributesUsage.alarm, channelBypassDnd: notificationPolicyAccessGranted, enableVibration: true, visibility: NotificationVisibility.public));
    await _scheduleExact(id: id, title: title, body: body, scheduledDate: scheduledDate, payload: payload, details: details);
  }"""
new_wake = """  Future<void> _scheduleWakeAlarm({required int id, required String title, required String body, required DateTime scheduledDate, required String soundName, required String payload}) async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('pre_prayer_alert_mode') ?? 'alarm';
    if (mode == 'alarm') {
      if (!scheduledDate.isAfter(DateTime.now())) return;
      await _nativeAdhanChannel.invokeMethod('schedule', <String, dynamic>{
        'id': id,
        'timeMillis': scheduledDate.millisecondsSinceEpoch,
        'soundName': soundName,
        'title': title,
        'body': body,
      });
      return;
    }
    final details = NotificationDetails(android: AndroidNotificationDetails('aqim_pre_prayer_${_channelVersion}_$mode', 'التنبيه قبل الصلاة', channelDescription: mode == 'ringtone' ? 'تنبيه قبل الصلاة برنة الهاتف' : 'تنبيه قبل الصلاة بالاهتزاز فقط', importance: Importance.max, priority: Priority.max, category: AndroidNotificationCategory.alarm, fullScreenIntent: true, playSound: mode != 'vibrate', sound: null, audioAttributesUsage: AudioAttributesUsage.alarm, channelBypassDnd: notificationPolicyAccessGranted, enableVibration: true, visibility: NotificationVisibility.public));
    await _scheduleExact(id: id, title: title, body: body, scheduledDate: scheduledDate, payload: payload, details: details);
  }"""
if old_wake in text:
    text = text.replace(old_wake, new_wake, 1)
else:
    # The native pre-prayer implementation is already present. Do not fail CI
    # just because this safety-net script is being run a second time.
    if "invokeMethod('schedule', <String, dynamic>{" not in text:
        raise SystemExit('Expected _scheduleWakeAlarm source was not found and native replacement is absent; refusing to write a partial fix.')

# Native pre-prayer alarms use AlarmManager, so cancel those alarms explicitly
# before rebuilding today's schedule. This prevents stale alarms after a
# settings/location/timezone refresh.
needle = "    await _nativeAdhanChannel.invokeMethod('cancelAllAdhanAlarms');\n"
replacement = needle + "    for (final id in <int>[0, 3, 4, 10, 20, 30, 40]) {\n      await _nativeAdhanChannel.invokeMethod('cancel', <String, dynamic>{'id': id});\n    }\n"
if needle in text and replacement not in text:
    text = text.replace(needle, replacement, 1)
notifications.write_text(text, encoding='utf-8')

# Android 12+ requires a system-intent receiver to be exported when it has a
# BOOT_COMPLETED intent filter. This allows scheduled notifications to be
# restored after reboot/update on modern Android versions.
manifest = ROOT / 'android/app/src/main/AndroidManifest.xml'
if manifest.exists():
    text = manifest.read_text(encoding='utf-8')
    text = text.replace(
        '<receiver\n            android:exported="false"\n            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">',
        '<receiver\n            android:exported="true"\n            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">',
        1,
    )
    manifest.write_text(text, encoding='utf-8')

print('Release compile, prayer countdown, interstitial placement, and notification fixes prepared successfully.')
