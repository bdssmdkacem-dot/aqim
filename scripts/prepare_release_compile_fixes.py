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
if "package:provider/provider.dart" not in text:
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

# Keep the original home content/design, but make the weekly report the only
# action that uses the interstitial. The Qibla action must open directly.
home = ROOT / 'lib/screens/home_screen.dart'
text = home.read_text(encoding='utf-8')
old_qibla = "onTap: () => AppInterstitialAd.showThen(() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QiblaScreen())))"
new_qibla = "onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QiblaScreen()))"
text = text.replace(old_qibla, new_qibla, 1)
old_hero = "nextRealTime: state.realTimes?[next!]"
new_hero = "nextRealTime: state.nextPrayerTime"
text = text.replace(old_hero, new_hero, 1)
home.write_text(text, encoding='utf-8')

# Notification correctness fixes. Do not change notification text/content.
notifications = ROOT / 'lib/services/notification_service.dart'
text = notifications.read_text(encoding='utf-8')
# Never move a pre-prayer/adhan notification two minutes late merely because
# exact-alarm access is unavailable. The service already selects an inexact
# Android schedule mode in that case.
text = text.replace(
    "  DateTime _safeFallbackDate(DateTime scheduledDate) => exactAlarmPermissionGranted ? scheduledDate : scheduledDate.add(const Duration(minutes: 2));",
    "  DateTime _safeFallbackDate(DateTime scheduledDate) => scheduledDate;",
    1,
)
# Query DND policy access instead of leaving the cached value false.
text = text.replace(
    "  Future<bool> refreshNotificationPolicyAccess() async { await init(); return notificationPolicyAccessGranted; }",
    "  Future<bool> refreshNotificationPolicyAccess() async {\n    await init();\n    final android = _android;\n    if (android == null) return false;\n    try {\n      notificationPolicyAccessGranted = await android.hasNotificationPolicyAccess() ?? false;\n    } catch (_) {}\n    return notificationPolicyAccessGranted;\n  }",
    1,
)
# Fix the Fajr resource-name typo (trailing whitespace) without changing the
# user's selected sound or any notification wording.
text = text.replace("'azan-Fajr-madina '", "'azan-Fajr-madina'", 1)
# Keep DND state current before creating alarm channels.
text = text.replace(
    "    await refreshExactAlarmPermission();\n    if (!exactAlarmPermissionGranted)",
    "    await refreshExactAlarmPermission();\n    await refreshNotificationPolicyAccess();\n    if (!exactAlarmPermissionGranted)",
    1,
)
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
