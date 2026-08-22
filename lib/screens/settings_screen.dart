import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  bool _batteryReady = false;
  bool _checkingBattery = true;
  static const _adhanSounds = <String, String>{
    'azan_maroc_1': 'الأذان المغربي 1',
    'azan_1': 'الأذان 1',
    'azan_2': 'الأذان 2',
    'azan_3': 'الأذان 3',
    'azan_abdebast': 'الأذان — عبد الباسط',
    'azan_maroc_2': 'الأذان المغربي 2',
  };
  String _selectedAdhan = 'azan_maroc_1';
  bool _loadingAdhan = true;
  bool _playingAdhan = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkBattery();
    _loadAdhanSelection();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().refreshNotificationStatus();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkBattery();
      if (mounted) context.read<AppState>().refreshNotificationStatus();
    }
  }


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

  Future<void> _checkBattery() async {
    if (mounted) setState(() => _checkingBattery = true);
    final ready = await BatteryService.isFullyExempted();
    if (mounted) setState(() { _batteryReady = ready; _checkingBattery = false; });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            _StatusCard(state: state),
            const SizedBox(height: 20),
            Text('توقيت التذكيرات', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('التذكير قبل الصلاة', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: _beforeOptions.map((m) {
                    final selected = state.beforeMinutes == m;
                    return ChoiceChip(label: Text('$m دقيقة'), selected: selected, onSelected: (_) => state.updateReminderTiming(before: m), selectedColor: AppColors.gold.withOpacity(.25), labelStyle: TextStyle(color: selected ? AppColors.ink : AppColors.inkSoft, fontWeight: selected ? FontWeight.w700 : FontWeight.w500));
                  }).toList()),
                  const SizedBox(height: 18),
                  const Text('تذكير «هل صليت؟» بعد الصلاة', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: _afterOptions.map((m) {
                    final selected = state.afterMinutes == m;
                    return ChoiceChip(label: Text('$m دقيقة'), selected: selected, onSelected: (_) => state.updateReminderTiming(after: m), selectedColor: AppColors.gold.withOpacity(.25), labelStyle: TextStyle(color: selected ? AppColors.ink : AppColors.inkSoft, fontWeight: selected ? FontWeight.w700 : FontWeight.w500));
                  }).toList()),
                ]),
              ),
            ),
            const SizedBox(height: 20),
            Text('الأذان', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 8),
            Card(
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
            ),
            const SizedBox(height: 20),
            Text('التشغيل في الخلفية', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 8),
            _BatteryCard(
              ready: _batteryReady,
              checking: _checkingBattery,
              onCheck: _checkBattery,
              onOpenAll: () async { await BatteryService.openSettings(); await _checkBattery(); },
              onOpenAutoStart: () async { await BatteryService.openAutoStartSettings(); await _checkBattery(); },
              onOpenManufacturer: () async { await BatteryService.openManufacturerSettings(); await _checkBattery(); },
            ),
            const SizedBox(height: 16),
            Card(
              color: AppColors.sage.withOpacity(.06),
              child: const ListTile(
                leading: Icon(Icons.favorite_rounded, color: AppColors.gold),
                title: Text('أقم مجاني للجميع'),
                subtitle: Text('لا توجد رسوم لإزالة الإعلانات ولا اشتراك مدفوع. كل الميزات الأساسية متاحة مجانًا.', style: TextStyle(fontSize: 12, height: 1.5)),
              ),
            ),
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
    final ok = ready && !checking;
    return Card(
      color: ok ? AppColors.sage.withOpacity(.07) : AppColors.ember.withOpacity(.07),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Icon(ok ? Icons.verified_user_rounded : Icons.battery_alert_rounded, color: ok ? AppColors.sage : AppColors.gold),
            const SizedBox(width: 10),
            Expanded(child: Text(checking ? 'جارٍ فحص إعدادات البطارية...' : (ok ? 'التشغيل في الخلفية مفعّل' : 'السماح لأقم بالعمل في الخلفية'), style: TextStyle(fontWeight: FontWeight.w800, color: ok ? AppColors.sage : AppColors.gold))),
          ]),
          const SizedBox(height: 8),
          Text(ok ? 'يمكن لأقم متابعة تذكيرات الصلاة وورد القرآن حتى عند إغلاق الشاشة.' : 'إذا كان هاتفك يقيّد التطبيق، قد تتأخر التذكيرات. فعّل السماح الكامل ثم ارجع إلى أقم للتحقق مرة أخرى.', style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.5)),
          if (!ok) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(onPressed: checking ? null : onOpenAll, icon: const Icon(Icons.battery_saver_rounded), label: const Text('السماح بالتشغيل الكامل')),
            const SizedBox(height: 8),
            OutlinedButton.icon(onPressed: onOpenAutoStart, icon: const Icon(Icons.autorenew_rounded), label: const Text('تفعيل التشغيل التلقائي')),
            const SizedBox(height: 8),
            TextButton.icon(onPressed: onOpenManufacturer, icon: const Icon(Icons.settings_suggest_rounded, size: 18), label: const Text('إعدادات الشركة المصنّعة')),
          ],
          TextButton.icon(onPressed: onCheck, icon: const Icon(Icons.refresh_rounded, size: 18), label: const Text('فحص الحالة الآن')),
        ]),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final AppState state;
  const _StatusCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final active = state.notificationsActive;
    final loading = state.timesLoading;
    return Card(
      color: active ? AppColors.sage.withOpacity(.08) : AppColors.ember.withOpacity(.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(active ? Icons.check_circle : Icons.error_outline, color: active ? AppColors.sage : AppColors.ember, size: 20), const SizedBox(width: 8), Expanded(child: Text(active ? 'الإشعارات مفعّلة' : 'الإشعارات غير مفعّلة', style: TextStyle(fontWeight: FontWeight.w700, color: active ? AppColors.sage : AppColors.ember)))]),
          if (state.cityName != null) ...[
            const SizedBox(height: 8),
            Row(children: [const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textMuted), const SizedBox(width: 4), Text(state.cityName!, style: Theme.of(context).textTheme.bodyMedium)]),
          ],
          if (active && state.usingOfflineTimes) ...[
            const SizedBox(height: 8),
            Text('الأوقات محسوبة محليًا (بلا إنترنت) — قد تختلف بضع دقائق عن الطريقة الرسمية.', style: Theme.of(context).textTheme.bodyMedium),
          ],
          if (!active) ...[
            const SizedBox(height: 8),
            Text(state.notificationIssue ?? 'تعذّر تفعيل الإشعارات لسبب غير معروف.', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: loading ? null : () => state.loadPrayerTimes(), icon: loading ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh, size: 18), label: Text(loading ? 'جارٍ المحاولة...' : 'إعادة المحاولة'))),
          ],
        ]),
      ),
    );
  }
}
