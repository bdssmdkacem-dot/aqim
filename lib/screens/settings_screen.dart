import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/battery_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

const _beforeOptions = [5, 10, 15, 20, 30];
const _afterOptions = [10, 15, 20, 30, 45];

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            _StatusCard(state: state),
            const SizedBox(height: 24),
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
                          selectedColor: AppColors.gold.withOpacity(0.25),
                          labelStyle: TextStyle(
                            color: selected ? AppColors.ink : AppColors.inkSoft,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    const Text('تذكير "هل صليت؟" بعد الصلاة', style: TextStyle(fontWeight: FontWeight.w700)),
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
                          selectedColor: AppColors.gold.withOpacity(0.25),
                          labelStyle: TextStyle(
                            color: selected ? AppColors.ink : AppColors.inkSoft,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('الأذان', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 8),
            Card(
              child: SwitchListTile(
                title: const Text('صوت الأذان عند وقت كل صلاة'),
                subtitle: const Text(
                  'إشعار بصوت الأذان لحظة دخول الوقت',
                  style: TextStyle(fontSize: 12),
                ),
                value: state.adhanEnabled,
                onChanged: state.setAdhanEnabled,
              ),
            ),
            const SizedBox(height: 24),
            Text('البطارية', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.battery_charging_full, color: AppColors.gold),
                title: const Text('تحسين إعدادات البطارية'),
                subtitle: const Text(
                  'مهم على هواتف Xiaomi وHuawei وOppo كي تصل التذكيرات فوقتها',
                  style: TextStyle(fontSize: 12),
                ),
                onTap: BatteryService.openSettings,
              ),
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
      color: active ? AppColors.sage.withOpacity(0.08) : AppColors.ember.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  active ? Icons.check_circle : Icons.error_outline,
                  color: active ? AppColors.sage : AppColors.ember,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    active ? 'الإشعارات مفعّلة' : 'الإشعارات غير مفعّلة',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: active ? AppColors.sage : AppColors.ember,
                    ),
                  ),
                ),
              ],
            ),
            if (state.cityName != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(state.cityName!, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ],
            if (!active) ...[
              const SizedBox(height: 8),
              Text(
                state.notificationIssue ?? 'تعذّر تفعيل الإشعارات لسبب غير معروف.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: loading ? null : () => state.loadPrayerTimes(),
                  icon: loading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, size: 18),
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
