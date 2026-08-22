from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]

# Keep this migration idempotent. The notification implementation now uses
# _scheduleAdhan(), so an older string-based patch must never fail CI.

pubspec = ROOT / 'pubspec.yaml'
s = pubspec.read_text(encoding='utf-8')
if '    - assets/adhan/\n' not in s and '  assets:\n' in s:
    s = s.replace('  assets:\n', '  assets:\n    - assets/adhan/\n', 1)
    pubspec.write_text(s, encoding='utf-8')

settings = ROOT / 'lib/screens/settings_screen.dart'
s = settings.read_text(encoding='utf-8')
s = s.replace("'adhan': 'الأذان المختار'", "'adhan': 'تنبيه صوتي'")
s = s.replace("'adhan'\n                    ? 'سيستخدم الأذان الذي اخترته في الأسفل.'", "'adhan'\n                    ? 'سيستخدم صوت الأذان الذي اخترته في قسم صوت الأذان.'")

# Remove the unfinished ads-removal offer from Settings for now.
premium_title = """                  const _SectionTitle(
                    icon: Icons.workspace_premium_rounded,
                    title: 'أقم بدون إعلانات',
                    subtitle: 'تجربة هادئة ومركّزة على الصلاة.',
                  ),
                  const SizedBox(height: 10),
                  _buildPremiumCard(state),
                  const SizedBox(height: 22),
"""
s = s.replace(premium_title, '')
s = re.sub(r"\n  Widget _buildPremiumCard\(AppState state\) \{.*?\n  \}\n\}\n\nclass _SectionTitle", "\n}\n\nclass _SectionTitle", s, flags=re.S)

# Replace the old version/location footer with the Aqim mark only.
s = re.sub(
    r"\n                  Card\(\n                    child: ListTile\(\n                      leading: const Icon\(Icons.info_outline_rounded, color: AppColors.gold\),.*?\n                  \),",
    """
                  const SizedBox(height: 8),
                  Center(
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/aqim_logo_transparent_512.png',
                          width: 74,
                          height: 74,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'أقم — لأجل صلاة في وقتها',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
""",
    s,
    flags=re.S,
)
settings.write_text(s, encoding='utf-8')

# Keep the stored preference key consistent between Settings and notifications.
notification = ROOT / 'lib/services/notification_service.dart'
ns = notification.read_text(encoding='utf-8')
ns = ns.replace("prefs.getString('prayer_alert_mode')", "prefs.getString('pre_prayer_alert_mode')")
notification.write_text(ns, encoding='utf-8')

# Upgrade the existing monthly agenda to an interactive month navigator.
report = ROOT / 'lib/screens/week_report_screen.dart'
r = report.read_text(encoding='utf-8')
if "../widgets/monthly_agenda.dart" not in r:
    r = r.replace("import '../theme/app_theme.dart';", "import '../theme/app_theme.dart';\nimport '../widgets/monthly_agenda.dart';")
r = re.sub(
    r"\n    final firstOfMonth = DateTime\(today\.year, today\.month, 1\);.*?\n    final calendarCells = .*?\n\n    return Scaffold",
    "\n    return Scaffold",
    r,
    flags=re.S,
)
r = re.sub(
    r"              Text\('أجندة هذا الشهر'.*?\n              if \(upcomingEvents\.isNotEmpty\) \.\.\.\[",
    """              Text('أجندة هذا الشهر', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              const MonthlyAgenda(),
              if (upcomingEvents.isNotEmpty) ...[""",
    r,
    count=1,
    flags=re.S,
)
report.write_text(r, encoding='utf-8')

print('Aqim settings and interactive monthly agenda migration completed successfully.')
