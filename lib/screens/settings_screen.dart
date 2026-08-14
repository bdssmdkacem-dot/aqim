import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkBattery();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkBattery();
  }

  Future<void> _checkBattery() async {
    if (mounted) setState(() => _checkingBattery = true);
    final ready = await BatteryService.isFullyExempted();
    if (mounted) setState(() {
      _batteryReady = ready;
      _checkingBattery = false;
    });
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('التذكير قبل الصلاة', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _beforeOptions.map((m) {
                        final selected = state.beforeMinutes == m;
                        return ChoiceChip(
                          label: Text('$m دقيقة'),
                          selected: selected,
                          onSelected: (_) => state.updateReminderTiming(before: m),
                          selectedColor: AppColors.gold.withOpacity(.25),
                          labelStyle: TextStyle(color: selected ? AppColors.ink : AppColors.inkSoft, fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    const Text('تذكير «هل صليت؟» بعد الصلاة', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _afterOptions.map((m) {
                        final selected = state.afterMinutes == m;
                        return ChoiceChip(
                          label: Text('$m دقيقة'),
                          selected: selected,
                          onSelected: (_) => state.updateReminderTiming(after: m),
                          selectedColor: AppColors.gold.withOpacity(.25),
                          labelStyle: TextStyle(color: selected ? AppColors.ink : AppColors.inkSoft, fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('الأذان', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 8),
            Card(
              child: SwitchListTile(
                title: const Text('صوت الأذان عند وقت كل صلاة'),
                subtitle: const Text('إشعار بصوت الأذان لحظة دخول الوقت', style: TextStyle(fontSize: 12)),
                value: state.adhanEnabled,
                onChanged: state.setAdhanEnabled,
              ),
            ),
            const SizedBox(height: 20),
            Text('التشغيل في الخلفية', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 8),
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
            const SizedBox(height: 20),
            Text('الإعلانات', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 8),
            _RemoveAdsCard(state: state),
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

  const _BatteryCard({
    required this.ready,
    required this.checking,
    required this.onCheck,
    required this.onOpenAll,
    required this.onOpenAutoStart,
    required this.onOpenManufacturer,
  });

  @override
  Widget build(BuildContext context) {
    final ok = ready && !checking;
    return Card(
      color: ok ? AppColors.sage.withOpacity(.07) : AppColors.ember.withOpacity(.07),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(ok ? Icons.verified_user_rounded : Icons.battery_alert_rounded, color: ok ? AppColors.sage : AppColors.gold),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    checking ? 'جارٍ فحص إعدادات البطارية...' : (ok ? 'التشغيل في الخلفية مفعّل' : 'السماح لأقم بالعمل في الخلفية'),
                    style: TextStyle(fontWeight: FontWeight.w800, color: ok ? AppColors.sage : AppColors.gold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              ok
                  ? 'يمكن لأقم متابعة تذكيرات الصلاة حتى عند إغلاق الشاشة.'
                  : 'إذا كان هاتفك يقيّد التطبيق، قد تتأخر التذكيرات. فعّل السماح الكامل ثم ارجع إلى أقم للتحقق مرة أخرى.',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.5),
            ),
            if (!ok) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: checking ? null : onOpenAll,
                icon: const Icon(Icons.battery_saver_rounded),
                label: const Text('السماح بالتشغيل الكامل'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onOpenAutoStart,
                icon: const Icon(Icons.autorenew_rounded),
                label: const Text('تفعيل التشغيل التلقائي'),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: onOpenManufacturer,
                icon: const Icon(Icons.settings_suggest_rounded, size: 18),
                label: const Text('إعدادات الشركة المصنّعة'),
              ),
            ],
            TextButton.icon(
              onPressed: onCheck,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('فحص الحالة الآن'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RemoveAdsCard extends StatelessWidget {
  final AppState state;
  const _RemoveAdsCard({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.adsRemoved) {
      return Card(
        color: AppColors.sage.withOpacity(.08),
        child: const ListTile(
          leading: Icon(Icons.check_circle, color: AppColors.sage),
          title: Text('الإعلانات مُزالة'),
          subtitle: Text('شكرًا لدعمك 🌙', style: TextStyle(fontSize: 12)),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.workspace_premium_rounded, color: AppColors.gold),
                const SizedBox(width: 10),
                const Expanded(child: Text('إزالة الإعلانات نهائيًا', style: TextStyle(fontWeight: FontWeight.w800))),
                Text(state.removeAdsPriceLabel, style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 7),
            const Text('دفعة واحدة بلا اشتراك — تختفي الإعلانات من التطبيق مدى الحياة.', style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.5)),
            const SizedBox(height: 13),
            ElevatedButton.icon(
              onPressed: () => state.buyRemoveAds(),
              icon: const Icon(Icons.remove_circle_outline_rounded),
              label: Text('إزالة الإعلانات — ${state.removeAdsPriceLabel}'),
            ),
            TextButton(
              onPressed: () => state.restorePurchases(),
              child: const Text('استعادة المشتريات'),
            ),
          ],
        ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(active ? Icons.check_circle : Icons.error_outline, color: active ? AppColors.sage : AppColors.ember, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    active ? 'الإشعارات مفعّلة' : 'الإشعارات غير مفعّلة',
                    style: TextStyle(fontWeight: FontWeight.w700, color: active ? AppColors.sage : AppColors.ember),
                  ),
                ),
              ],
            ),
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
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: loading ? null : () => state.loadPrayerTimes(),
                  icon: loading ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh, size: 18),
                  label: Text(loading ? 'جارٍ المحاولة...' : 'إعادة المحاولة'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
