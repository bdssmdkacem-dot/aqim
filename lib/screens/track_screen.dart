import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

const _weekdayLabels = ['إث', 'ثل', 'أر', 'خم', 'جم', 'سب', 'أح'];
const _monthNames = [
  'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
  'يوليوز', 'غشت', 'شتنبر', 'أكتوبر', 'نونبر', 'دجنبر',
];

class TrackScreen extends StatefulWidget {
  const TrackScreen({super.key});

  @override
  State<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends State<TrackScreen> {
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(title: const Text('تتبع الالتزام')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          children: [
            _StatsRow(state: state),
            const SizedBox(height: 18),
            _MonthNavigator(
              month: _visibleMonth,
              onPrev: () => _shiftMonth(-1),
              onNext: () => _shiftMonth(1),
            ),
            const SizedBox(height: 12),
            _MonthGrid(month: _visibleMonth, state: state),
            const SizedBox(height: 20),
            _WeeklyBars(state: state),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final AppState state;
  const _StatsRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final overall = state.overallCommitmentPercent;
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'أطول سلسلة',
            value: '${state.longestStreak}',
            unit: 'يومًا',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _CircleStatCard(
            label: 'الالتزام العام',
            percent: overall,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'الصلوات المفوّتة',
            value: '${state.missTally.values.fold<int>(0, (a, b) => a + b)}',
            unit: 'صلاة',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  const _StatCard({required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border.all(color: AppColors.paperLine),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.gold)),
          const SizedBox(height: 2),
          Text(unit, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
          const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _CircleStatCard extends StatelessWidget {
  final String label;
  final int? percent;
  const _CircleStatCard({required this.label, required this.percent});

  @override
  Widget build(BuildContext context) {
    final value = (percent ?? 0) / 100;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border.all(color: AppColors.paperLine),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: CircularProgressIndicator(
                    value: value,
                    strokeWidth: 5,
                    backgroundColor: AppColors.paperLine,
                    valueColor: const AlwaysStoppedAnimation(AppColors.gold),
                  ),
                ),
                Text(
                  percent == null ? '—' : '$percent%',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _MonthNavigator extends StatelessWidget {
  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  const _MonthNavigator({required this.month, required this.onPrev, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_right, color: AppColors.gold)),
        Text(
          '${_monthNames[month.month - 1]} ${month.year}',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_left, color: AppColors.gold)),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final AppState state;
  const _MonthGrid({required this.month, required this.state});

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Dart weekday: Monday=1..Sunday=7 — نبدأ الأسبوع بالإثنين.
    final leadingBlanks = firstDay.weekday - 1;
    final totalCells = leadingBlanks + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border.all(color: AppColors.paperLine),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: _weekdayLabels
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          for (var r = 0; r < rows; r++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: List.generate(7, (c) {
                  final cellIndex = r * 7 + c;
                  final dayNum = cellIndex - leadingBlanks + 1;
                  if (dayNum < 1 || dayNum > daysInMonth) {
                    return const Expanded(child: SizedBox(height: 34));
                  }
                  final date = DateTime(month.year, month.month, dayNum);
                  final isFuture = date.isAfter(DateTime.now());
                  final pct = isFuture ? null : state.percentForDate(date);
                  return Expanded(child: _DayCell(day: dayNum, percent: pct));
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final int? percent;
  const _DayCell({required this.day, required this.percent});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color textColor = Colors.white;
    if (percent == null) {
      bg = Colors.transparent;
      textColor = AppColors.textMuted;
    } else if (percent! >= 80) {
      bg = AppColors.sage;
    } else if (percent! > 0) {
      bg = AppColors.gold.withOpacity(0.5);
    } else {
      bg = AppColors.ember.withOpacity(0.55);
    }

    return SizedBox(
      height: 34,
      child: Center(
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Text('$day', style: TextStyle(fontSize: 11.5, color: textColor, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

class _WeeklyBars extends StatelessWidget {
  final AppState state;
  const _WeeklyBars({required this.state});

  @override
  Widget build(BuildContext context) {
    const dayLabels = ['س', 'أ', 'ن', 'ث', 'ر', 'خ', 'ج'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border.all(color: AppColors.paperLine),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('إحصائيات هذا الأسبوع', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 14),
          SizedBox(
            height: 80,
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
                          height: (v * 0.55).clamp(4, 55).toDouble(),
                          decoration: BoxDecoration(
                            color: done ? AppColors.sage : AppColors.gold.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(dayLabels[i], style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
