from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

pubspec = ROOT / 'pubspec.yaml'
s = pubspec.read_text(encoding='utf-8')
if '    - assets/adhan/\n' not in s:
    marker = '  assets:\n'
    s = s.replace(marker, marker + '    - assets/adhan/\n', 1)
    pubspec.write_text(s, encoding='utf-8')

settings = ROOT / 'lib/screens/settings_screen.dart'
s = settings.read_text(encoding='utf-8')
s = s.replace("import 'package:provider/provider.dart';", "import 'package:provider/provider.dart';\nimport 'package:shared_preferences/shared_preferences.dart';\nimport '../services/audio_service.dart';")
s = s.replace("  bool _checkingBattery = true;", "  bool _checkingBattery = true;\n  static const _adhanSounds = <String, String>{\n    'azan_maroc_1': 'الأذان المغربي 1',\n    'azan_1': 'الأذان 1',\n    'azan_2': 'الأذان 2',\n    'azan_3': 'الأذان 3',\n    'azan_abdebast': 'الأذان — عبد الباسط',\n    'azan_maroc_2': 'الأذان المغربي 2',\n  };\n  String _selectedAdhan = 'azan_maroc_1';\n  bool _loadingAdhan = true;\n  bool _playingAdhan = false;")
s = s.replace("    _checkBattery();\n    WidgetsBinding", "    _checkBattery();\n    _loadAdhanSelection();\n    WidgetsBinding", 1)
insert = """
  Future<void> _loadAdhanSelection() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _selectedAdhan = prefs.getString('adhan_sound') ?? 'azan_maroc_1';
      _loadingAdhan = false;
    });
  }

  Future<void> _selectAdhan(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('adhan_sound', value);
    if (!mounted) return;
    setState(() => _selectedAdhan = value);
    await context.read<AppState>().loadPrayerTimes();
  }

  Future<void> _previewAdhan() async {
    setState(() => _playingAdhan = true);
    await AudioService.instance.playAsset(
      context,
      'adhan/$_selectedAdhan.mp3',
    );
    if (mounted) setState(() => _playingAdhan = false);
  }

"""
s = s.replace("  Future<void> _checkBattery() async {", insert + "  Future<void> _checkBattery() async {", 1)
old = "Card(child: SwitchListTile(title: const Text('صوت الأذان عند وقت كل صلاة'), subtitle: const Text('إشعار بصوت الأذان لحظة دخول الوقت', style: TextStyle(fontSize: 12)), value: state.adhanEnabled, onChanged: state.setAdhanEnabled)),"
new = """Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('صوت الأذان عند وقت كل صلاة'),
                    subtitle: const Text('يعمل تلقائيًا عند دخول وقت الصلاة', style: TextStyle(fontSize: 12)),
                    value: state.adhanEnabled,
                    onChanged: state.setAdhanEnabled,
                  ),
                  const Divider(height: 24),
                  const Text('صوت الأذان', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  if (_loadingAdhan)
                    const LinearProgressIndicator()
                  else
                    DropdownButtonFormField<String>(
                      value: _selectedAdhan,
                      decoration: const InputDecoration(labelText: 'اختر الأذان المفضل'),
                      items: _adhanSounds.entries.map((entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      )).toList(),
                      onChanged: (value) {
                        if (value != null) _selectAdhan(value);
                      },
                    ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _loadingAdhan ? null : _previewAdhan,
                    icon: Icon(_playingAdhan ? Icons.stop_rounded : Icons.play_arrow_rounded),
                    label: Text(_playingAdhan ? 'إيقاف المعاينة' : 'تجربة الأذان'),
                  ),
                ]),
              ),
            ),"""
if old in s:
    s = s.replace(old, new, 1)
settings.write_text(s, encoding='utf-8')

notify = ROOT / 'lib/services/notification_service.dart'
s = notify.read_text(encoding='utf-8')
s = s.replace("static const _channelVersion = 'v9';", "static const _channelVersion = 'v10';", 1)
old = """  Future<void> _scheduleAdhan({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String payload,
  }) async {
    await _scheduleExact(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      payload: payload,
      details: _alarmDetails(
        channelId: 'aqim_adhan_${_channelVersion}',
        channelName: 'الأذان',
        channelDescription: 'الأذان عند دخول وقت الصلاة — صوت منبّه',
        soundName: 'adhan',
        category: AndroidNotificationCategory.alarm,
      ),
    );
  }"""
new = """  Future<void> _scheduleAdhan({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String payload,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final selectedSound = prefs.getString('adhan_sound') ?? 'azan_maroc_1';
    await _scheduleExact(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      payload: payload,
      details: _alarmDetails(
        channelId: 'aqim_adhan_${_channelVersion}_$selectedSound',
        channelName: 'الأذان',
        channelDescription: 'الأذان عند دخول وقت الصلاة — الصوت المختار من الإعدادات',
        soundName: selectedSound,
        category: AndroidNotificationCategory.alarm,
      ),
    );
  }"""
if old not in s:
    raise SystemExit('notification target not found')
s = s.replace(old, new, 1)
notify.write_text(s, encoding='utf-8')

# Make the Android raw-resource folder explicit in the source tree. The six MP3
# files must be present there for scheduled notification sounds.
raw = ROOT / 'android/app/src/main/res/raw'
raw.mkdir(parents=True, exist_ok=True)
keep = raw / '.gitkeep'
if not keep.exists(): keep.write_text('', encoding='utf-8')

print('Aqim adhan selection code applied.')
