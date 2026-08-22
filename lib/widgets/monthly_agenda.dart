import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/prayer.dart';
import '../services/offline_prayer_times_service.dart';
import '../services/religious_events_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class MonthlyAgenda extends StatefulWidget {
  const MonthlyAgenda({super.key});

  @override
  State<MonthlyAgenda> createState() => _MonthlyAgendaState();
}

class _MonthlyAgendaState extends State<MonthlyAgenda> {
  late DateTime _month;
  DateTime? _selected;
  int _direction = 1;

  static const _weekdays = ['السبت', 'الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];
  static const _months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'ماي', 'يونيو', 'يوليوز', 'غشت', 'شتنبر', 'أكتوبر', 'نونبر', 'دجنبر'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  void _changeMonth(int delta) {
    setState(() {
      _direction = delta;
      _month = DateTime(_month.year, _month.month + delta);
      _selected = null;
    });
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  void _showDay(BuildContext context, DateTime date) {
    setState(() => _selected = date);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (_) => _DayDetails(date: date),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final today = DateTime.now();
    final first = DateTime(_month.year, _month.month, 1);
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final offset = (first.weekday + 1) % 7;
    final cells = List<DateTime?>.generate(offset, (_) => null)
      ..addAll(List.generate(days, (i) => DateTime(_month.year, _month.month, i + 1)));

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      decoration: BoxDecoration(color: AppColors.surfaceDark, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.paperLine.withOpacity(.75))),
      child: Column(children: [
        Row(children: [
          IconButton(onPressed: () => _changeMonth(-1), icon: const Icon(Icons.chevron_right_rounded), color: AppColors.gold),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              transitionBuilder: (child, animation) => SlideTransition(
                position: Tween<Offset>(begin: Offset(_direction > 0 ? 0.25 : -0.25, 0), end: Offset.zero).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: Text('${_months[_month.month - 1]} ${_month.year}', key: ValueKey('${_month.year}-${_month.month}'), textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.goldSoft, fontWeight: FontWeight.w900)),
            ),
          ),
          IconButton(onPressed: () => _changeMonth(1), icon: const Icon(Icons.chevron_left_rounded), color: AppColors.gold),
        ]),
        GestureDetector(
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity.abs() < 100) return;
            _changeMonth(velocity < 0 ? 1 : -1);
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, animation) => SlideTransition(position: Tween<Offset>(begin: Offset(_direction > 0 ? 0.18 : -0.18, 0), end: Offset.zero).animate(animation), child: FadeTransition(opacity: animation, child: child)),
            child: Column(key: ValueKey('${_month.year}-${_month.month}'), children: [
              Row(children: _weekdays.map((d) => Expanded(child: Text(d, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.clip, style: const TextStyle(fontSize: 8.5, color: AppColors.inkSoft, fontWeight: FontWeight.w700)))).toList()),
              const SizedBox(height: 6),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cells.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 5, crossAxisSpacing: 5, childAspectRatio: .88),
                itemBuilder: (_, index) {
                  final date = cells[index];
                  if (date == null) return const SizedBox.shrink();
                  final event = ReligiousEventsService.eventOn(date);
                  final isToday = _sameDay(date, today);
                  final isSelected = _selected != null && _sameDay(date, _selected!);
                  final percent = state.percentForDate(date) ?? 0;
                  final done = percent >= 80;
                  final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                  final history = state.dailyPrayerHistory.containsKey(key);
                  return InkWell(
                    onTap: () => _showDay(context, date),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      decoration: BoxDecoration(color: event != null ? AppColors.gold.withOpacity(.12) : done ? AppColors.sage.withOpacity(.16) : AppColors.ink.withOpacity(.24), borderRadius: BorderRadius.circular(10), border: Border.all(color: isSelected || isToday ? AppColors.gold : event != null ? AppColors.gold.withOpacity(.65) : AppColors.paperLine.withOpacity(.65), width: isSelected ? 2 : isToday ? 1.4 : 1)),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('${date.day}', style: TextStyle(fontSize: 11, fontWeight: isToday || isSelected ? FontWeight.w900 : FontWeight.w600, color: isToday || isSelected ? AppColors.gold : AppColors.ivory)),
                        const SizedBox(height: 2),
                        Icon(event != null ? Icons.event_available_rounded : history && done ? Icons.check_circle_rounded : history ? Icons.circle_rounded : Icons.remove_circle_outline, size: 10, color: event != null ? AppColors.gold : done ? AppColors.sage : history ? AppColors.gold : AppColors.textMuted),
                      ]),
                    ),
                  );
                },
              ),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.event_available_rounded, size: 11, color: AppColors.gold), SizedBox(width: 4), Text('مناسبة دينية', style: TextStyle(fontSize: 9, color: AppColors.inkSoft)), SizedBox(width: 12), Icon(Icons.touch_app_rounded, size: 11, color: AppColors.goldSoft), SizedBox(width: 4), Text('اضغط على اليوم', style: TextStyle(fontSize: 9, color: AppColors.inkSoft))]),
      ]),
    );
  }
}

class _DayDetails extends StatelessWidget {
  final DateTime date;
  const _DayDetails({required this.date});

  String _dayName(DateTime d) => const ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'][d.weekday % 7];

  String _monthName(int m) => const ['يناير', 'فبراير', 'مارس', 'أبريل', 'ماي', 'يونيو', 'يوليوز', 'غشت', 'شتنبر', 'أكتوبر', 'نونبر', 'دجنبر'][m - 1];

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final event = ReligiousEventsService.eventOn(date);
    final lat = state.lastKnownLatitude;
    final lng = state.lastKnownLongitude;
    final times = lat == null || lng == null ? null : OfflinePrayerTimesService.calculateForDate(date: date, latitude: lat, longitude: lng);
    final historyKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final history = state.dailyPrayerHistory[historyKey];

    return SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 42, height: 4, decoration: BoxDecoration(color: AppColors.paperLine, borderRadius: BorderRadius.circular(10))),
      const SizedBox(height: 16),
      Text('${_dayName(date)} ${date.day} ${_monthName(date.month)} ${date.year}', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.goldSoft, fontWeight: FontWeight.w900)),
      if (event != null) ...[
        const SizedBox(height: 12),
        Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppColors.gold.withOpacity(.10), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.gold.withOpacity(.55))), child: Column(children: [const Icon(Icons.event_available_rounded, color: AppColors.gold, size: 28), const SizedBox(height: 6), Text('${event.title} لسنة ${event.date.year}', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.goldSoft, fontWeight: FontWeight.w900)), const SizedBox(height: 4), Text('${event.hijri}${event.provisional ? ' • موعد متوقع' : ''}', style: Theme.of(context).textTheme.bodySmall)])),
      ],
      const SizedBox(height: 14),
      Align(alignment: Alignment.centerRight, child: Text('صلوات هذا اليوم', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
      const SizedBox(height: 6),
      if (times == null)
        const Padding(padding: EdgeInsets.all(12), child: Text('فعّل الموقع في أقم لعرض أوقات الصلوات لهذا اليوم.', textAlign: TextAlign.center))
      else
        ...Prayer.values.map((p) {
          final t = times[p]!;
          final status = history?[p];
          return ListTile(dense: true, leading: Icon(Icons.mosque_rounded, color: status == PrayerStatus.done ? AppColors.sage : AppColors.goldSoft), title: Text(p.arabicName, style: const TextStyle(fontWeight: FontWeight.w800)), trailing: Text('${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: AppColors.goldSoft, fontWeight: FontWeight.w900)));
        }),
    ])));
  }
}
