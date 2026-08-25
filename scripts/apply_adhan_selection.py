from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

# This workflow used to patch exact older function bodies. The notification
# service has since evolved, so exact-text replacement made the CI fail with
# "current pre-prayer function not found" even when the desired implementation
# was already present. Keep this migration idempotent: normalize assets and
# validate the current contract instead of rewriting unrelated code.

pubspec = ROOT / 'pubspec.yaml'
s = pubspec.read_text(encoding='utf-8')
if '    - assets/adhan/' not in s:
    if '  assets:\n' not in s:
        raise SystemExit('assets section not found in pubspec.yaml')
    s = s.replace('  assets:\n', '  assets:\n    - assets/adhan/\n', 1)
    pubspec.write_text(s, encoding='utf-8')

settings = ROOT / 'lib/screens/settings_screen.dart'
ss = settings.read_text(encoding='utf-8')
required_settings = (
    '_fajrAdhanSounds',
    "'adhan_fajr_sound'",
    "'adhan_alert_mode'",
    "'pre_prayer_alert_mode'",
    '_prePrayerModes',
    '_adhanModes',
    'تشغيل أذان الفجر',
    'تشغيل الأذان',
)
missing = [item for item in required_settings if item not in ss]
if missing:
    raise SystemExit('adhan settings contract incomplete: ' + ', '.join(missing))

notification = ROOT / 'lib/services/notification_service.dart'
ns = notification.read_text(encoding='utf-8')
required_notification = (
    'Future<void> _scheduleWakeAlarm',
    "prefs.getString('pre_prayer_alert_mode')",
    "RawResourceAndroidNotificationSound(selectedSound)",
    'Future<void> _scheduleAdhan',
    "prefs.getString('adhan_alert_mode')",
    "prefs.getString('adhan_fajr_sound')",
    "RawResourceAndroidNotificationSound(notificationSound)",
)
missing = [item for item in required_notification if item not in ns]
if missing:
    raise SystemExit('notification contract incomplete: ' + ', '.join(missing))

# The three Fajr assets are intentionally named without spaces so Flutter can
# reference them directly. The Madina file is checked by the workflow before
# build; keep the old spaced file out of the Dart asset contract.
adhan_dir = ROOT / 'assets/adhan'
required_assets = ('azan-fajr.mp3', 'azan-fajr-maghribi.mp3')
missing_assets = [name for name in required_assets if not (adhan_dir / name).exists()]
if missing_assets:
    raise SystemExit('missing Fajr adhan asset(s): ' + ', '.join(missing_assets))

print('Aqim adhan selection contract OK')
