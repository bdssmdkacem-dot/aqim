import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ads/app_banner_ad.dart';
import '../models/prayer.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

const _dayLabels = ['س', 'أ', 'ن', 'ث', 'ر', 'خ', 'ج'];

class WeekReportScreen extends StatelessWidget {
  const WeekReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final weakest = state.weakestPrayer;

    return Scaffold(
      appBar: AppBar(title: const Text('لوحة الحياة')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
          children: [
            Text('هذا الأسبوع', style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 14),
            SizedBox(
              height: 90,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (i) {
                  final v = state.weekHistory[i];
                  final done = v >= 80;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: (v * 0.6).clamp(6, 60).toDouble(),
                            decoration: BoxDecoration(
                              color: done ? AppColors.sage : AppColors.paperLine,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(_dayLabels[i], style: Theme.of(context).textTheme.labelSmall),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: state.activePrayers.map((p) {
                    final s = state.todayStatus[p];
                    final isDone = s == PrayerStatus.done;
                    final isMissed = s == PrayerStatus.missed;
                    return ListTile(
                      dense: true,
                      title: Text(p.arabicName, style: Theme.of(context).textTheme.titleMedium),
                      trailing: CircleAvatar(
                        radius: 11,
                        backgroundColor: isDone
                            ? AppColors.sage
                            : isMissed
                                ? AppColors.ember
                                : AppColors.paperLine,
                        child: Text(
                          isDone ? '✓' : (isMissed ? '✕' : ''),
                          style: const TextStyle(fontSize: 11, color: Colors.white),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            if (weakest != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.ember.withOpacity(0.06),
                  border: Border.all(color: AppColors.ember.withOpacity(0.25)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ملاحظة', style: TextStyle(fontSize: 11, color: AppColors.ember, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(
                      'لاحظنا أن ${weakest.arabicName} هي أكثر صلاة يصعب عليك المحافظة عليها. هدف الأسبوع القادم: تحسينها فقط.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('حسنًا، لنعمل عليها'),
            ),
            const SizedBox(height: 16),
            const Center(child: AppBannerAd()),
          ],
        ),
      ),
    );
  }
}
