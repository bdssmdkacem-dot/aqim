from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

# Keep this migration idempotent: normalize the current adhan contract
# instead of relying on exact older function bodies.

pubspec = ROOT / 'pubspec.yaml'
s = pubspec.read_text(encoding='utf-8')
if '    - assets/adhan/' not in s:
    if '  assets:\n' not in s:
        raise SystemExit('assets section not found in pubspec.yaml')
    s = s.replace('  assets:\n', '  assets:\n    - assets/adhan/\n', 1)
    pubspec.write_text(s, encoding='utf-8')

settings = ROOT / 'lib/screens/settings_screen.dart'
ss = settings.read_text(encoding='utf-8')

# The actual repository filename contains a capital F and a space before
# .mp3: assets/adhan/azan-Fajr-madina .mp3. Keep that filename unchanged.
ss = ss.replace("'azanfajrmadina': 'أذان المدينة'", "'azan-Fajr-madina ': 'أذان المدينة'")
settings.write_text(ss, encoding='utf-8')

required_settings = (
    '_fajrAdhanSounds',
    "'adhan_fajr_sound'",
    "'adhan_alert_mode'",
    "'pre_prayer_alert_mode'",
    '_prePrayerModes',
    '_adhanModes',
    'تشغيل أذان الفجر',
    'تشغيل الأذان',
    "'azan-Fajr-madina '",
)
missing = [item for item in required_settings if item not in ss]
if missing:
    raise SystemExit('adhan settings contract incomplete: ' + ', '.join(missing))

notification = ROOT / 'lib/services/notification_service.dart'
ns = notification.read_text(encoding='utf-8')

# Migrate the old stored preference value, if a tester already has it saved.
ns = ns.replace(
    "final selectedSound = prayer == Prayer.fajr ? (prefs.getString('adhan_fajr_sound') ?? 'azan-fajr') : (prefs.getString('adhan_sound') ?? 'azan_maroc_1');",
    "final selectedSound = prayer == Prayer.fajr ? ((prefs.getString('adhan_fajr_sound') ?? 'azan-fajr') == 'azanfajrmadina' ? 'azan-Fajr-madina ' : (prefs.getString('adhan_fajr_sound') ?? 'azan-fajr')) : (prefs.getString('adhan_sound') ?? 'azan_maroc_1');",
)
notification.write_text(ns, encoding='utf-8')

required_notification = (
    'Future<void> _scheduleWakeAlarm',
    "prefs.getString('pre_prayer_alert_mode')",
    'RawResourceAndroidNotificationSound(selectedSound)',
    'Future<void> _scheduleAdhan',
    "prefs.getString('adhan_alert_mode')",
    "prefs.getString('adhan_fajr_sound')",
    'RawResourceAndroidNotificationSound(notificationSound)',
)
missing = [item for item in required_notification if item not in ns]
if missing:
    raise SystemExit('notification contract incomplete: ' + ', '.join(missing))

adhan_dir = ROOT / 'assets/adhan'
required_assets = (
    'azan-fajr.mp3',
    'azan-Fajr-madina .mp3',
    'azan-fajr-maghribi.mp3',
)
missing_assets = [name for name in required_assets if not (adhan_dir / name).exists()]
if missing_assets:
    raise SystemExit('missing Fajr adhan asset(s): ' + ', '.join(missing_assets))

print('Aqim adhan selection contract OK')
