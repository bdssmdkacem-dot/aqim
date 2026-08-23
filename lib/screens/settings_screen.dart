import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ads/app_banner_ad.dart';
import '../models/prayer.dart';
import '../services/audio_service.dart';
import '../services/battery_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

const _beforeOptions = [5, 10, 15, 20, 30];
const _afterOptions = [10, 15, 20, 30, 45];

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  static const _adhanSounds = <String, String>{
    'azan_maroc_1': 'الأذان المغربي 1',
    'azan_maroc_2': 'الأذان المغربي 2',
    'azan_1': 'أذان 1',
    'azan_2': 'أذان 2',
    'azan_3': 'أذان 3',
    'azan_abdebast': 'أذان عبد الباسط',
  };

  static const _alertModes = <String, String>{
    'adhan': 'تنبيه صوتي',
    'ringtone': 'رنة الهاتف',
    'vibrate': 'هزاز فقط',
  };

  static const _prayerNames = <Prayer, String>{
    Prayer.fajr: 'الفجر',
    Prayer.dhuhr: 'الظهر',
    Prayer.asr: 'العصر',
    Prayer.maghrib: 'المغرب',
    Prayer.isha: 'العشاء',
  };

  bool _batteryReady = false;
  bool _checkingBattery = true;
  bool _prePrayerEnabled = true;
  String _prePrayerMode = 'adhan';
  Set<String> _prePrayerPrayers = Prayer.values.map((p) => p.name).toSet();
  String _selectedAdhan = 'azan_maroc_1';
  bool _loadingAudio = true;
  bool _playingAdhan = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPreferences();
    _checkBattery();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().refreshNotificationStatus();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AudioService.instance.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkBattery();
      if (mounted) context.read<AppState>().refreshNotificationStatus();
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _prePrayerEnabled = prefs.getBool('pre_prayer_enabled') ?? true;
      _prePrayerMode = prefs.getString('pre_prayer_alert_mode') ?? 'adhan';
      _selectedAdhan = prefs.getString('adhan_sound') ?? 'azan_maroc_1';
      final saved = prefs.getStringList('pre_prayer_prayers');
      _prePrayerPrayers = saved == null || saved.isEmpty
          ? Prayer.values.map((p) => p.name).toSet()
          : saved.toSet();
      _loadingAudio = false;
    });
  }

  Future<void> _savePrePrayerSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pre_prayer_enabled', _prePrayerEnabled);
    await prefs.setString('pre_prayer_alert_mode', _prePrayerMode);
    await prefs.setStringList('pre_prayer_prayers', _prePrayerPrayers.toList());
    if (mounted) await context.read<AppState>().loadPrayerTimes();
  }

  Future<void> _selectAdhan(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('adhan_sound', value);
    if (!mounted) return;
    setState(() => _selectedAdhan = value);
    await context.read<AppState>().loadPrayerTimes();
  }

  Future<void> _previewAdhan() async {
    if (_playingAdhan) {
      await AudioService.instance.stop();
      if (mounted) setState(() => _playingAdhan = false);
      return;
    }

    if (_loadingAudio) return;
    setState(() => _playingAdhan = true);

    try {
      await AudioService.instance.playAsset(
        context,
        'adhan/$_selectedAdhan.mp3',
      );
    } finally {
      if (mounted) setState(() => _playingAdhan = false);
    }
  }

  Future<void> _checkBattery() async {
    if (mounted) setState(() => _checkingBattery = true);
    final ready = await BatteryService.isFullyExempted();
    if (mounted) {
      setState(() {
        _batteryReady = ready;
        _checkingBattery = false;
      });
    }
  }

  void _togglePrayer(Prayer prayer) {
    setState(() {
      if (_prePrayerPrayers.contains(prayer.name)) {
        _prePrayerPrayers.remove(prayer.name);
      } else {
        _prePrayerPrayers.add(prayer.name);
      }
    });
    _savePrePrayerSettings();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات'), centerTitle: true),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
                children: [
                  _StatusCard(state: state),
                  const SizedBox(height: 22),
                  const _SectionTitle(
                    icon: Icons.notifications_active_rounded,
                    title: 'تنبيهات أقم',
                    subtitle: 'اجعل أقم يذكّرك بالصلاة بالطريقة التي تناسبك.',
                  ),
                  const SizedBox(height: 10),
                  _buildTimingCard(state),
                  const SizedBox(height: 12),
                  _buildPrePrayerCard(),
                  const SizedBox(height: 12),
                  _buildAdhanCard(state),
                  const SizedBox(height: 22),
                  const _SectionTitle(
                    icon: Icons.battery_saver_rounded,
                    title: 'العمل في الخلفية',
                    subtitle: 'يساعد ذلك أقم على إرسال التنبيهات في وقتها.',
                  ),
                  const SizedBox(height: 10),
                  _BatteryCard(
                    ready: _batteryReady,
                    checking: _checkingBattery,
                    onCheck: _checkBattery,
                    onOpenAll: () async {
                      await BatteryService.openSettings();
                      await _checkBattery();
                    },
                    onOpenAutoStart: () async {
                      await BatteryService.openAutoStartSettings();
                      await _checkBattery();
                    },
                    onOpenManufacturer: () async {
                      await BatteryService.openManufacturerSettings();
                      await _checkBattery();
                    },
                  ),
                  const SizedBox(height: 12),
                  const _AqimBrandCard(),
                ],
              ),
            ),
            if (!state.adsRemoved) const AppBannerAd(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimingCard(AppState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('وقت التذكير قبل الصلاة', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('متى تريد أن يذكّرك أقم بالاستعداد؟', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _beforeOptions.map((minutes) {
                final selected = state.beforeMinutes == minutes;
                return ChoiceChip(
                  label: Text('$minutes د'),
                  selected: selected,
                  onSelected: (_) => state.updateReminderTiming(before: minutes),
                );
              }).toList(),
            ),
            const Divider(height: 28),
            const Text('تذكير «هل صليت؟»', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _afterOptions.map((minutes) {
                final selected = state.afterMinutes == minutes;
                return ChoiceChip(
                  label: Text('$minutes د'),
                  selected: selected,
                  onSelected: (_) => state.updateReminderTiming(after: minutes),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrePrayerCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
        child: Column(
          children: [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _prePrayerEnabled,
              onChanged: (value) async {
                setState(() => _prePrayerEnabled = value);
                await _savePrePrayerSettings();
              },
              title: const Text('تنبيه صوتي قبل الصلاة', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: const Text('اختر الصلوات وطريقة التنبيه التي تناسبك.', style: TextStyle(fontSize: 12)),
            ),
            if (_prePrayerEnabled) ...[
              const Divider(height: 20),
              const Align(
                alignment: Alignment.centerRight,
                child: Text('الصلاة التي تريد التنبيه لها', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: _prayerNames.entries.map((entry) {
                  final selected = _prePrayerPrayers.contains(entry.key.name);
                  return FilterChip(
                    label: Text(entry.value),
                    selected: selected,
                    onSelected: (_) => _togglePrayer(entry.key),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _prePrayerMode,
                decoration: const InputDecoration(
                  labelText: 'طريقة التنبيه قبل الصلاة',
                  prefixIcon: Icon(Icons.volume_up_rounded),
                ),
                items: _alertModes.entries.map((entry) {
                  return DropdownMenuItem(value: entry.key, child: Text(entry.value));
                }).toList(),
                onChanged: (value) async {
                  if (value == null) return;
                  setState(() => _prePrayerMode = value);
                  await _savePrePrayerSettings();
                },
              ),
              const SizedBox(height: 8),
              Text(
                _prePrayerMode == 'adhan'
                    ? 'سيستخدم الأذان الذي اخترته في قسم الأذان أدناه.'
                    : _prePrayerMode == 'ringtone'
                        ? 'سيستخدم رنة الإشعارات الافتراضية للهاتف.'
                        : 'سيكون التنبيه بالاهتزاز فقط دون صوت.',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdhanCard(AppState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: state.adhanEnabled,
              onChanged: state.setAdhanEnabled,
              title: const Text('الأذان عند دخول وقت الصلاة', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: const Text('يمكنك إيقاف الأذان مع إبقاء التنبيه قبل الصلاة.', style: TextStyle(fontSize: 12)),
            ),
            const Divider(height: 20),
            const Text('صوت الأذان', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            if (_loadingAudio)
              const LinearProgressIndicator()
            else
              DropdownButtonFormField<String>(
                initialValue: _selectedAdhan,
                decoration: const InputDecoration(
                  labelText: 'اختر صوت الأذان',
                  prefixIcon: Icon(Icons.mosque_rounded),
                ),
                items: _adhanSounds.entries.map((entry) {
                  return DropdownMenuItem(value: entry.key, child: Text(entry.value));
                }).toList(),
                onChanged: (value) {
                  if (value != null) _selectAdhan(value);
                },
              ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _loadingAudio ? null : _previewAdhan,
              icon: Icon(_playingAdhan ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded),
              label: Text(_playingAdhan ? 'إيقاف التنبيه الصوتي' : 'تجربة التنبيه الصوتي'),
            ),
            const SizedBox(height: 6),
            const Text(
              'اضغط للتأكد من الصوت قبل اعتماده. يمكنك إيقافه في أي وقت.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _AqimBrandCard extends StatelessWidget {
  const _AqimBrandCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                'assets/images/aqim_logo_transparent_512.png',
                width: 64,
                height: 64,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'أقم',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'رفيقك للصلاة في وقتها',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionTitle({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.gold, size: 22),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  final AppState state;
  const _StatusCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final active = state.notificationsActive;
    return Card(
      color: active ? AppColors.sage.withOpacity(.08) : AppColors.ember.withOpacity(.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(active ? Icons.notifications_active_rounded : Icons.notifications_off_rounded, color: active ? AppColors.sage : AppColors.ember, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(active ? 'تنبيهات أقم تعمل' : 'تنبيهات أقم تحتاج إلى تفعيل', style: TextStyle(fontWeight: FontWeight.w900, color: active ? AppColors.sage : AppColors.ember)),
                  const SizedBox(height: 4),
                  Text(state.cityName == null ? 'حدّد موقعك للحصول على أوقات الصلاة الدقيقة.' : 'الموقع: ${state.cityName}', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            IconButton(tooltip: 'تحديث', onPressed: state.loadPrayerTimes, icon: const Icon(Icons.refresh_rounded)),
          ],
        ),
      ),
    );
  }
}

class _BatteryCard extends StatelessWidget {
  final bool ready;
  final bool checking;
  final VoidCallback onCheck;
  final VoidCallback onOpenAll;
  final VoidCallback onOpenAutoStart;
  final VoidCallback onOpenManufacturer;

  const _BatteryCard({required this.ready, required this.checking, required this.onCheck, required this.onOpenAll, required this.onOpenAutoStart, required this.onOpenManufacturer});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(ready ? Icons.check_circle_rounded : Icons.warning_amber_rounded, color: ready ? AppColors.sage : AppColors.ember),
                const SizedBox(width: 10),
                Expanded(child: Text(ready ? 'إعدادات الخلفية مناسبة' : 'قد تتأخر التنبيهات', style: const TextStyle(fontWeight: FontWeight.w800))),
                if (checking) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) else IconButton(onPressed: onCheck, icon: const Icon(Icons.refresh_rounded)),
              ],
            ),
            const SizedBox(height: 8),
            Text(ready ? 'يمكن لأقم العمل في الخلفية وإرسال التنبيهات في وقتها.' : 'لضمان وصول تنبيهات الصلاة، اسمح لأقم بالعمل دون قيود من البطارية.', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: onOpenAll, icon: const Icon(Icons.settings_rounded), label: const Text('إعدادات البطارية')),
            const SizedBox(height: 8),
            OutlinedButton.icon(onPressed: onOpenAutoStart, icon: const Icon(Icons.play_arrow_rounded), label: const Text('التشغيل التلقائي')),
            const SizedBox(height: 8),
            OutlinedButton.icon(onPressed: onOpenManufacturer, icon: const Icon(Icons.phone_android_rounded), label: const Text('إعدادات الشركة المصنّعة')),
          ],
        ),
      ),
    );
  }
}
