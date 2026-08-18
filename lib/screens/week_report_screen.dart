import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ads/app_banner_ad.dart';
import '../models/prayer.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

const _dayLabels = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];

class WeekReportScreen extends StatelessWidget {
  const WeekReportScreen({super.key});

  DateTime _weekStart(DateTime date) {
    final daysFromSaturday = (date.weekday + 1) % 7;
    final d = DateTime(date.year, date.month, date.day);
    return d.subtract(Duration(days: daysFromSaturday));
  }

  String _dayName(DateTime date) => _dayLabels[date.weekday % 7];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final weakest = state.weakestPrayer;
    final today = DateTime.now();
    final start = _weekStart(today);
    final weekDates = List.generate(7, (i) => start.add(Duration(days: i)));
    final todayPercent = state.percentForDate(today) ?? 0;
    final weekPercents = weekDates.map((d) => state.percentForDate(d) ?? 0).toList();
    final average = weekPercents.isEmpty ? 0 : (weekPercents.reduce((a, b) => a + b) / weekPercents.length).round();
    final completedDays = weekPercents.where((v) => v >= 80).length;

    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(title: const Text('لوحة الحياة'), centerTitle: true, backgroundColor: AppColors.ink),
      body: SafeArea(
        child: Column(children: [
          Expanded(child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [AppColors.surfaceElevated, AppColors.surfaceDark]), borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.gold.withOpacity(.38))),
                child: Row(children: [
                  Container(
                    width: 52,
                    height: 52,
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.gold.withOpacity(.10), border: Border.all(color: AppColors.gold.withOpacity(.55))),
                    child: ClipOval(child: Image.asset('assets/images/aqim_logo_transparent_512.png', fit: BoxFit.contain)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('رحلتك مع أقم', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 3), Text('تابع صلاتك يومًا بيوم، وخطوة بخطوة.', style: Theme.of(context).textTheme.bodySmall)])),
                ]),
              ),
              const SizedBox(height: 14),
              Row(children: [Expanded(child: _StatCard(title: 'متوسط الأسبوع', value: '$average%', icon: Icons.insights_rounded)), const SizedBox(width: 9), Expanded(child: _StatCard(title: 'أيام مكتملة', value: '$completedDays / 7', icon: Icons.check_circle_outline_rounded))]),
              const SizedBox(height: 16),
              Text('هذا الأسبوع', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
                decoration: BoxDecoration(color: AppColors.surfaceDark, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.paperLine.withOpacity(.75))),
                child: Row(children: weekDates.map((date) {
                  final percent = state.percentForDate(date) ?? 0;
                  final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
                  final complete = percent >= 80;
                  return Expanded(child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(children: [
                      Text(_dayName(date), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(fontSize: 9.5, fontWeight: isToday ? FontWeight.w800 : FontWeight.w600, color: isToday ? AppColors.goldSoft : AppColors.inkSoft)),
                      const SizedBox(height: 2),
                      Text('${date.day}/${date.month}', style: TextStyle(fontSize: 9, fontWeight: isToday ? FontWeight.w800 : FontWeight.w500, color: isToday ? AppColors.gold : AppColors.inkSoft)),
                      const SizedBox(height: 7),
                      Container(width: 34, height: 54, alignment: Alignment.bottomCenter, decoration: BoxDecoration(color: AppColors.ink.withOpacity(.28), borderRadius: BorderRadius.circular(12), border: Border.all(color: isToday ? AppColors.gold : AppColors.paperLine)), child: FractionallySizedBox(heightFactor: (percent / 100).clamp(.08, 1.0).toDouble(), child: Container(decoration: BoxDecoration(color: complete ? AppColors.sage : AppColors.gold.withOpacity(.55), borderRadius: BorderRadius.circular(10))))),
                      const SizedBox(height: 6),
                      Text('$percent%', style: TextStyle(fontSize: 9, color: isToday ? AppColors.goldSoft : AppColors.inkSoft)),
                    ]),
                  ));
                }).toList()),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(color: AppColors.surfaceDark, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.gold.withOpacity(.24))),
                child: Row(children: [const Icon(Icons.today_rounded, color: AppColors.goldSoft, size: 25), const SizedBox(width: 10), Expanded(child: Text('إنجاز اليوم: $todayPercent% — ${_dayName(today)} ${today.day}/${today.month}', style: Theme.of(context).textTheme.bodyMedium))]),
              ),
              const SizedBox(height: 14),
              Card(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Column(children: state.activePrayers.map((p) {
                final s = state.todayStatus[p];
                final isDone = s == PrayerStatus.done;
                final isMissed = s == PrayerStatus.missed;
                return ListTile(dense: true, title: Text(p.arabicName, style: Theme.of(context).textTheme.titleMedium), trailing: CircleAvatar(radius: 12, backgroundColor: isDone ? AppColors.sage : isMissed ? AppColors.ember : AppColors.paperLine, child: Text(isDone ? '✓' : (isMissed ? '✕' : ''), style: const TextStyle(fontSize: 11, color: Colors.white)));
              }).toList()))),
              if (weakest != null) ...[
                const SizedBox(height: 12),
                Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.ember.withOpacity(0.06), border: Border.all(color: AppColors.ember.withOpacity(0.25)), borderRadius: BorderRadius.circular(18)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('ملاحظة من أقم', style: TextStyle(fontSize: 11, color: AppColors.ember, fontWeight: FontWeight.w700)), const SizedBox(height: 6), Text('لاحظنا أن ${weakest.arabicName} هي الصلاة التي تفوتك أكثر من غيرها. هدفك القادم: تحسينها.', style: Theme.of(context).textTheme.bodyMedium)])),
              ],
              const SizedBox(height: 16),
              ElevatedButton.icon(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back_rounded, size: 18), label: const Text('حسنًا، لنعمل عليها')),
            ],
          )),
          const AppBannerAd(),
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _StatCard({required this.title, required this.value, required this.icon});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.fromLTRB(12, 12, 12, 13), decoration: BoxDecoration(color: AppColors.surfaceDark, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.paperLine.withOpacity(.7))), child: Row(children: [Icon(icon, color: AppColors.goldSoft, size: 23), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.bodySmall), const SizedBox(height: 2), Text(value, style: Theme.of(context).textTheme.titleLarge)]))]));
}
