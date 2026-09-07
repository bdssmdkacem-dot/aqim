from pathlib import Path

UNUSED_ACTION_IMPORT_FILES = [
    "lib/main.dart",
    "lib/navigation/bottom_nav_controller.dart",
    "lib/screens/home_screen.dart",
    "lib/screens/identity_screen.dart",
    "lib/screens/more_screen.dart",
    "lib/screens/nearby_mosques_screen.dart",
    "lib/screens/notification_inbox_screen.dart",
    "lib/screens/onboarding_screen.dart",
    "lib/screens/pre_prayer_screen.dart",
    "lib/screens/settings_screen.dart",
    "lib/widgets/notification_bell.dart",
]

IMPORT = "import '../state/app_state_actions.dart';\n"
for name in UNUSED_ACTION_IMPORT_FILES:
    path = Path(name)
    text = path.read_text()
    if IMPORT in text:
        text = text.replace(IMPORT, "", 1)
        path.write_text(text)

# These declarations are genuinely unused; removing them keeps analyzer output clean.
week_report = Path("lib/screens/week_report_screen.dart")
text = week_report.read_text()
block = "const _calendarDayLabels = [\n  'السبت',\n  'الأحد',\n  'الإثنين',\n  'الثلاثاء',\n  'الأربعاء',\n  'الخميس',\n  'الجمعة'\n];\n"
if block in text:
    week_report.write_text(text.replace(block, "", 1))

settings = Path("lib/screens/settings_screen.dart")
text = settings.read_text()
start = text.find("  void _navigate(BuildContext context, int index) {")
if start != -1:
    end = text.find("\n  @override\n  Widget build", start)
    if end == -1:
        raise SystemExit("settings _navigate end marker not found")
    text = text[:start] + text[end + 1:]
    settings.write_text(text)

qibla = Path("lib/screens/qibla_screen.dart")
text = qibla.read_text()
text = text.replace("accuracy!.toStringAsFixed(0)", "accuracy.toStringAsFixed(0)")
qibla.write_text(text)

print("Analyzer warning cleanup applied successfully.")
