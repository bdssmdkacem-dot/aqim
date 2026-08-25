from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]

# Keep this migration idempotent. It normalizes the notification/settings
# contract so pre-prayer alarms never use the selected adhan.

pubspec = ROOT / 'pubspec.yaml'
s = pubspec.read_text(encoding='utf-8')
if '    - assets/adhan/\n' not in s and '  assets:\n' in s:
    s = s.replace('  assets:\n', '  assets:\n    - assets/adhan/\n', 1)
    pubspec.write_text(s, encoding='utf-8')

settings = ROOT / 'lib/screens/settings_screen.dart'
s = settings.read_text(encoding='utf-8')

# Pre-prayer choices are strictly alarm/ringtone/vibration. They must never
# reuse the selected adhan.
s = s.replace("  static const _alertModes = <String, String>{\n    'adhan': 'تنبيه صوتي',\n    'ringtone': 'رنة الهاتف',\n    'vibrate': 'هزاز فقط',\n  };", "  static const _prePrayerModes = <String, String>{\n    'alarm': 'منبه الصلاة',\n    'ringtone': 'رنة الهاتف',\n    'vibrate': 'هزاز فقط',\n  };\n\n  static const _adhanModes = <String, String>{\n    'adhan': 'صوت المؤذن',\n    'ringtone': 'رنة الهاتف',\n    'vibrate': 'هزاز فقط',\n  };")
s = s.replace("  String _prePrayerMode = 'adhan';", "  String _prePrayerMode = 'alarm';")
s = s.replace("  String _selectedAdhan = 'azan_maroc_1';\n  bool _loadingAudio", "  String _selectedAdhan = 'azan_maroc_1';\n  String _adhanAlertMode = 'adhan';\n  bool _loadingAudio")
s = s.replace("      _prePrayerMode = prefs.getString('pre_prayer_alert_mode') ?? 'adhan';\n      _selectedAdhan = prefs.getString('adhan_sound') ?? 'azan_maroc_1';", "      _prePrayerMode = prefs.getString('pre_prayer_alert_mode') ?? 'alarm';\n      _selectedAdhan = prefs.getString('adhan_sound') ?? 'azan_maroc_1';\n      _adhanAlertMode = prefs.getString('adhan_alert_mode') ?? 'adhan';")
s = s.replace("    await prefs.setString('pre_prayer_alert_mode', _prePrayerMode);\n    await prefs.setStringList", "    await prefs.setString('pre_prayer_alert_mode', _prePrayerMode);\n    await prefs.setStringList")

# Add a dedicated adhan-mode persistence method.
anchor = """  Future<void> _selectAdhan(String value) async {\n    final prefs = await SharedPreferences.getInstance();\n    await prefs.setString('adhan_sound', value);\n    if (!mounted) return;\n    setState(() => _selectedAdhan = value);\n    await context.read<AppState>().loadPrayerTimes();\n  }\n"""
replacement = anchor + """\n  Future<void> _selectAdhanMode(String value) async {\n    final prefs = await SharedPreferences.getInstance();\n    await prefs.setString('adhan_alert_mode', value);\n    if (!mounted) return;\n    setState(() => _adhanAlertMode = value);\n    await context.read<AppState>().loadPrayerTimes();\n  }\n"""
if anchor in s and '_selectAdhanMode' not in s:
    s = s.replace(anchor, replacement, 1)

s = s.replace("                items: _alertModes.entries.map((entry) {", "                items: _prePrayerModes.entries.map((entry) {")
s = s.replace("                _prePrayerMode == 'adhan'\n                    ? 'سيستخدم الأذان الذي اخترته في قسم الأذان أدناه.'", "                _prePrayerMode == 'alarm'\n                    ? 'سيستخدم المنبه الصوتي المخصص للصلاة القادمة، وليس الأذان.'")

# Add the independent adhan mode selector before the adhan sound selector.
adhan_anchor = """            const Divider(height: 20),\n            const Text('صوت الأذان', style: TextStyle(fontWeight: FontWeight.w800)),\n"""
adhan_replacement = """            const Divider(height: 20),\n            DropdownButtonFormField<String>(\n              initialValue: _adhanAlertMode,\n              decoration: const InputDecoration(\n                labelText: 'طريقة تنبيه وقت الصلاة',\n                prefixIcon: Icon(Icons.notifications_active_rounded),\n              ),\n              items: _adhanModes.entries.map((entry) {\n                return DropdownMenuItem(value: entry.key, child: Text(entry.value));\n              }).toList(),\n              onChanged: (value) {\n                if (value != null) _selectAdhanMode(value);\n              },\n            ),\n            const SizedBox(height: 12),\n            if (_adhanAlertMode == 'adhan') ...[\n              const Text('صوت المؤذن', style: TextStyle(fontWeight: FontWeight.w800)),\n"""
if adhan_anchor in s:
    s = s.replace(adhan_anchor, adhan_replacement, 1)

# Close the conditional block immediately after the preview/description area.
old_tail = """            const Text(\n              'اضغط للتأكد من الصوت قبل اعتماده. يمكنك إيقافه في أي وقت.',\n              textAlign: TextAlign.center,\n              style: TextStyle(fontSize: 11, color: AppColors.textMuted),\n            ),\n"""
new_tail = old_tail + """            ] else\n              Text(\n                _adhanAlertMode == 'ringtone'\n                    ? 'سيستخدم رنة الإشعارات الافتراضية للهاتف.'\n                    : 'سيكون التنبيه بالاهتزاز فقط دون صوت.',\n                textAlign: TextAlign.center,\n                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),\n              ),\n"""
if old_tail in s and "_adhanAlertMode == 'ringtone'" not in s:
    s = s.replace(old_tail, new_tail, 1)
s = s.replace("onPressed: _loadingAudio ? null : _previewAdhan,", "onPressed: _loadingAudio || _adhanAlertMode != 'adhan' ? null : _previewAdhan,")

# Remove the unfinished ads-removal offer from Settings for now.
premium_title = """                  const _SectionTitle(\n                    icon: Icons.workspace_premium_rounded,\n                    title: 'أقم بدون إعلانات',\n                    subtitle: 'تجربة هادئة ومركّزة على الصلاة.',\n                  ),\n                  const SizedBox(height: 10),\n                  _buildPremiumCard(state),\n                  const SizedBox(height: 22),\n"""
s = s.replace(premium_title, '')
s = re.sub(r"\n  Widget _buildPremiumCard\(AppState state\) \{.*?\n  \}\n\}\n\nclass _SectionTitle", "\n}\n\nclass _SectionTitle", s, flags=re.S)

# Replace the old version/location footer with the Aqim mark only.
s = re.sub(
    r"\n                  Card\(\n                    child: ListTile\(\n                      leading: const Icon\(Icons.info_outline_rounded, color: AppColors.gold\),.*?\n                  \),",
    """\n                  const SizedBox(height: 8),\n                  Center(\n                    child: Column(\n                      children: [\n                        Image.asset(\n                          'assets/images/aqim_logo_transparent_512.png',\n                          width: 74,\n                          height: 74,\n                          fit: BoxFit.contain,\n                        ),\n                        const SizedBox(height: 4),\n                        const Text(\n                          'أقم — لأجل صلاة في وقتها',\n                          style: TextStyle(fontSize: 11, color: AppColors.textMuted),\n                        ),\n                      ],\n                    ),\n                  ),\n""",
    s,
    flags=re.S,
)
settings.write_text(s, encoding='utf-8')

notification = ROOT / 'lib/services/notification_service.dart'
ns = notification.read_text(encoding='utf-8')
ns = ns.replace("prefs.getString('prayer_alert_mode')", "prefs.getString('pre_prayer_alert_mode')")

# Pre-prayer notification: only the prayer-specific alarm, phone ringtone,
# or vibration. Never the selected adhan.
old_wake = """  Future<void> _scheduleWakeAlarm({required int id, required String title, required String body, required DateTime scheduledDate, required String soundName, required String payload}) async {\n    final details = NotificationDetails(\n      android: AndroidNotificationDetails(\n        'aqim_pre_prayer_${_channelVersion}',\n        'التنبيه قبل الصلاة',\n        channelDescription: 'تنبيه صوتي قبل الصلاة — ليس أذانًا',\n        importance: Importance.max,\n        priority: Priority.max,\n        category: AndroidNotificationCategory.alarm,\n        fullScreenIntent: true,\n        playSound: true,\n        sound: null,\n        audioAttributesUsage: AudioAttributesUsage.alarm,\n        channelBypassDnd: notificationPolicyAccessGranted,\n        enableVibration: true,\n        visibility: NotificationVisibility.public,\n      ),\n    );\n    await _scheduleExact(\n      id: id,\n      title: title,\n      body: body,\n      scheduledDate: scheduledDate,\n      payload: payload,\n      details: details,\n    );\n  }"""
new_wake = """  Future<void> _scheduleWakeAlarm({required int id, required String title, required String body, required DateTime scheduledDate, required String soundName, required String payload}) async {\n    final prefs = await SharedPreferences.getInstance();\n    final mode = prefs.getString('pre_prayer_alert_mode') ?? 'alarm';\n    final bool playSound = mode != 'vibrate';\n    final bool vibration = true;\n    final String? selectedSound = mode == 'alarm' ? soundName : null;\n    final channelSuffix = mode == 'alarm' ? 'alarm_$soundName' : mode;\n    final details = NotificationDetails(\n      android: AndroidNotificationDetails(\n        'aqim_pre_prayer_${_channelVersion}_$channelSuffix',\n        'التنبيه قبل الصلاة',\n        channelDescription: mode == 'alarm'\n            ? 'منبه صوتي قبل الصلاة — ليس أذانًا'\n            : mode == 'ringtone'\n                ? 'تنبيه قبل الصلاة برنة الهاتف'\n                : 'تنبيه قبل الصلاة بالاهتزاز فقط',\n        importance: Importance.max,\n        priority: Priority.max,\n        category: AndroidNotificationCategory.alarm,\n        fullScreenIntent: true,\n        playSound: playSound,\n        sound: selectedSound == null\n            ? null\n            : RawResourceAndroidNotificationSound(selectedSound),\n        audioAttributesUsage: AudioAttributesUsage.alarm,\n        channelBypassDnd: notificationPolicyAccessGranted,\n        enableVibration: vibration,\n        visibility: NotificationVisibility.public,\n      ),\n    );\n    await _scheduleExact(\n      id: id,\n      title: title,\n      body: body,\n      scheduledDate: scheduledDate,\n      payload: payload,\n      details: details,\n    );\n  }"""
if old_wake not in ns:
    raise SystemExit('current pre-prayer function not found')
ns = ns.replace(old_wake, new_wake, 1)

# Prayer-time notification: selected mu'adhin, phone ringtone, or vibration.
old_adhan = """  Future<void> _scheduleAdhan({required int id, required String title, required String body, required DateTime scheduledDate, required String payload}) async {\n    final prefs = await SharedPreferences.getInstance();\n    final selectedSound = prefs.getString('adhan_sound') ?? 'azan_maroc_1';\n    await _scheduleExact(\n      id: id,\n      title: title,\n      body: body,\n      scheduledDate: scheduledDate,\n      payload: payload,\n      details: NotificationDetails(\n        android: AndroidNotificationDetails(\n          'aqim_adhan_${_channelVersion}_$selectedSound',\n          'الأذان',\n          channelDescription: 'الأذان عند دخول وقت الصلاة — الصوت المختار من الإعدادات',\n          importance: Importance.max,\n          priority: Priority.max,\n          category: AndroidNotificationCategory.alarm,\n          fullScreenIntent: true,\n          playSound: true,\n          sound: RawResourceAndroidNotificationSound(selectedSound),\n          audioAttributesUsage: AudioAttributesUsage.alarm,\n          channelBypassDnd: notificationPolicyAccessGranted,\n          enableVibration: true,\n          visibility: NotificationVisibility.public,\n        ),\n      ),\n    );\n  }"""
new_adhan = """  Future<void> _scheduleAdhan({required int id, required String title, required String body, required DateTime scheduledDate, required String payload}) async {\n    final prefs = await SharedPreferences.getInstance();\n    final mode = prefs.getString('adhan_alert_mode') ?? 'adhan';\n    final selectedSound = prefs.getString('adhan_sound') ?? 'azan_maroc_1';\n    final bool playSound = mode != 'vibrate';\n    final String? notificationSound = mode == 'adhan' ? selectedSound : null;\n    final channelSuffix = mode == 'adhan' ? 'adhan_$selectedSound' : mode;\n    await _scheduleExact(\n      id: id,\n      title: title,\n      body: body,\n      scheduledDate: scheduledDate,\n      payload: payload,\n      details: NotificationDetails(\n        android: AndroidNotificationDetails(\n          'aqim_adhan_${_channelVersion}_$channelSuffix',\n          'الأذان',\n          channelDescription: mode == 'adhan'\n              ? 'الأذان عند دخول وقت الصلاة — المؤذن المختار'\n              : mode == 'ringtone'\n                  ? 'تنبيه وقت الصلاة برنة الهاتف'\n                  : 'تنبيه وقت الصلاة بالاهتزاز فقط',\n          importance: Importance.max,\n          priority: Priority.max,\n          category: AndroidNotificationCategory.alarm,\n          fullScreenIntent: true,\n          playSound: playSound,\n          sound: notificationSound == null\n              ? null\n              : RawResourceAndroidNotificationSound(notificationSound),\n          audioAttributesUsage: AudioAttributesUsage.alarm,\n          channelBypassDnd: notificationPolicyAccessGranted,\n          enableVibration: true,\n          visibility: NotificationVisibility.public,\n        ),\n      ),\n    );\n  }"""
if old_adhan not in ns:
    raise SystemExit('current adhan function not found')
ns = ns.replace(old_adhan, new_adhan, 1)
notification.write_text(ns, encoding='utf-8')

# Keep the existing monthly agenda migration.
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
    """              Text('أجندة هذا الشهر', style: Theme.of(context).textTheme.titleMedium),\n              const SizedBox(height: 8),\n              const MonthlyAgenda(),\n              if (upcomingEvents.isNotEmpty) ...[""",
    r,
    count=1,
    flags=re.S,
)
report.write_text(r, encoding='utf-8')

print('Aqim notification separation migration completed successfully.')
