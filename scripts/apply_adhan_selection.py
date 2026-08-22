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
settings.write_text(s, encoding='utf-8')

# Keep the stored preference key consistent between Settings and notifications.
notification = ROOT / 'lib/services/notification_service.dart'
ns = notification.read_text(encoding='utf-8')
ns = ns.replace("prefs.getString('prayer_alert_mode')", "prefs.getString('pre_prayer_alert_mode')")
notification.write_text(ns, encoding='utf-8')

print('Aqim adhan settings migration completed successfully.')
