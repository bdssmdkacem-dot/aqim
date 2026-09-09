from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]

pubspec = ROOT / 'pubspec.yaml'
s = pubspec.read_text(encoding='utf-8')
if '    - assets/adhan/' not in s:
    lines = s.splitlines()
    top_level_flutter = next((i for i, line in enumerate(lines) if line == 'flutter:'), None)
    if top_level_flutter is not None:
        insert_at = top_level_flutter + 1
        lines.insert(insert_at, '  assets:')
        lines.insert(insert_at + 1, '    - assets/adhan/')
    else:
        if not s.endswith('\n'):
            s += '\n'
        s += '\nflutter:\n  assets:\n    - assets/adhan/\n'
    pubspec.write_text(s, encoding='utf-8')

settings = ROOT / 'lib/screens/settings_screen.dart'
ss = settings.read_text(encoding='utf-8')
# The real repository asset has no trailing space. Normalize legacy preference keys
# while accepting the old value when upgrading an existing installation.
ss = ss.replace("'azan-Fajr-madina ': 'أذان المدينة'", "'azan-Fajr-madina': 'أذان المدينة'")
ss = ss.replace("'azanfajrmadina': 'أذان المدينة'", "'azan-Fajr-madina': 'أذان المدينة'")
ss = ss.replace("'azan-Fajr-madina '", "'azan-Fajr-madina'")
settings.write_text(ss, encoding='utf-8')

required_settings = (
    '_fajrAdhanSounds', "'adhan_fajr_sound'", "'adhan_alert_mode'",
    "'pre_prayer_alert_mode'", '_prePrayerModes', '_adhanModes',
    'تشغيل أذان الفجر', 'تشغيل الأذان', "'azan-Fajr-madina'",
)
missing = [item for item in required_settings if item not in ss]
if missing:
    raise SystemExit('adhan settings contract incomplete: ' + ', '.join(missing))

notification = ROOT / 'lib/services/notification_service.dart'
ns = notification.read_text(encoding='utf-8')
ns = ns.replace(
    "final selectedSound = prayer == Prayer.fajr ? (prefs.getString('adhan_fajr_sound') ?? 'azan-fajr') : (prefs.getString('adhan_sound') ?? 'azan_maroc_1');",
    "final selectedSound = prayer == Prayer.fajr ? ((prefs.getString('adhan_fajr_sound') ?? 'azan-fajr').trim() == 'azanfajrmadina' ? 'azan-Fajr-madina' : (prefs.getString('adhan_fajr_sound') ?? 'azan-fajr').trim()) : (prefs.getString('adhan_sound') ?? 'azan_maroc_1').trim();",
)

# Collapse accidental duplicate native cancellation passes to one pass.
pattern = (
    r"(?:    for \(final id in <int>\[0, 3, 4, 10, 20, 30, 40\]\) \{\n"
    r"      await _nativeAdhanChannel\n"
    r"          \.invokeMethod\('cancel', <String, dynamic>\{'id': id\}\);\n"
    r"    \}\n)+"
)
replacement = (
    "    for (final id in <int>[0, 3, 4, 10, 20, 30, 40]) {\n"
    "      await _nativeAdhanChannel\n"
    "          .invokeMethod('cancel', <String, dynamic>{'id': id});\n"
    "    }\n"
)
ns = re.sub(pattern, replacement, ns)
notification.write_text(ns, encoding='utf-8')

required_notification = (
    'Future<void> _scheduleWakeAlarm', "prefs.getString('pre_prayer_alert_mode')",
    'Future<void> _scheduleAdhan', "prefs.getString('adhan_alert_mode')",
    "prefs.getString('adhan_fajr_sound')",
)
missing = [item for item in required_notification if item not in ns]
if missing:
    raise SystemExit('notification contract incomplete: ' + ', '.join(sorted(set(missing))))

adhan_dir = ROOT / 'assets/adhan'
required_assets = ('azan-fajr.mp3', 'azan-Fajr-madina.mp3', 'azan-fajr-maghribi.mp3')
missing_assets = [name for name in required_assets if not (adhan_dir / name).exists()]
if missing_assets:
    raise SystemExit('missing Fajr adhan asset(s): ' + ', '.join(missing_assets))

print('Aqim adhan selection contract OK')
