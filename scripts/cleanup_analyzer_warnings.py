from pathlib import Path

# Deterministic cleanup for imports that are known to be unused after the
# release-preparation scripts have finished mutating the Dart sources.
UNUSED_IMPORTS = {
    "lib/main.dart": ["import 'state/app_state_actions.dart';\n"],
    "lib/screens/home_screen.dart": ["import '../widgets/aqim_logo.dart';\n"],
    "lib/screens/settings_screen.dart": [
        "import '../widgets/aqim_bottom_nav.dart';\n",
        "import 'main_shell.dart';\n",
        "import 'pre_prayer_screen.dart';\n",
    ],
}

for name in [
    "lib/navigation/bottom_nav_controller.dart",
    "lib/screens/identity_screen.dart",
    "lib/screens/more_screen.dart",
    "lib/screens/nearby_mosques_screen.dart",
    "lib/screens/notification_inbox_screen.dart",
    "lib/screens/onboarding_screen.dart",
    "lib/screens/pre_prayer_screen.dart",
    "lib/widgets/notification_bell.dart",
]:
    UNUSED_IMPORTS.setdefault(name, []).append(
        "import '../state/app_state_actions.dart';\n"
    )

for name, imports in UNUSED_IMPORTS.items():
    path = Path(name)
    text = path.read_text()
    for unused_import in imports:
        text = text.replace(unused_import, "")
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
