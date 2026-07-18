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
