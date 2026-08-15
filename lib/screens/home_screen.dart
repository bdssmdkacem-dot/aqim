import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/prayer.dart';
import '../services/battery_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/gregorian_arabic.dart';
import '../utils/hijri_date.dart';
import '../widgets/day_arc.dart';
import '../widgets/prayer_arch_hero.dart';
import '../widgets/prayer_window_icon.dart' show PrayerDayPeriod, currentPrayerDayPeriod;

import 'missed_prayer_response_screen.dart';
import 'nearby_mosques_screen.dart';
import 'qibla_screen.dart';
import 'settings_screen.dart';
import 'week_report_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePromptBatterySettings());
  }

  Future<void> _maybePromptBatterySettings() async {
    final state = context.read<AppState>();
    if (state.batteryPromptShown) return;
    final exempted = await BatteryService.isFullyExempted();
    if (exempted) {
      await state.markBatteryPromptShown();
      return;
    }
    if (!mounted) return;
    final openSettings = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: Text('لضمان وصول تذكيراتك فوقتها', style: GoogleFonts.amiri(color: AppColors.ivory, fontSize: 20, fontWeight: FontWeight.w700)),
        content: Text('بعض الهواتف (خصوصًا Xiaomi وHuawei وOppo) توقف التطبيقات في الخلفية تلقائيًا. فعّل السماح لأقم بالعمل في الخلفية والتشغيل التلقائي حتى تصلك تذكيرات الصلاة في وقتها.', style: GoogleFonts.cairo(color: AppColors.inkSoft, height: 1.7, fontSize: 13.5)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('لاحقًا', style: GoogleFonts.cairo(color: AppColors.inkSoft))),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('تحسين البطارية')),
        ],
      ),
    );
    if (openSettings == true) {
      await BatteryService.openSettings();
      final granted = await BatteryService.isFullyExempted();
      if (granted && mounted) await state.markBatteryPromptShown();
    }
  }

  String _locationLabel(AppState state) {
    if (state.timesLoading && state.cityName == null) return 'جارٍ تحديد موقعك...';
    if (state.cityName != null) return state.cityName!;
    return 'لم يتم تحديد المدينة — اضغط للإعدادات';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final next = state.nextPrayer;
    final period = currentPrayerDayPeriod();
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 18),
          child: Column(
            children: [
              _TopRow(state: state),
              const SizedBox(height: 10),
              _TitleBlock(state: state, locationLabel: _locationLabel(state)),
              if (state.missedTodayCount > 0) ...[
                const SizedBox(height: 10),
                _MissedPrayerNotice(state: state),
              ],
              const SizedBox(height: 12),
              _HeroCard(state: state, next: next, period: period),
              const SizedBox(height: 8),
              const _QuickActions(),
              const SizedBox(height: 8),
              const _QiblaQuickAction(),
              const SizedBox(height: 2),
              if (next != null) DayArc(prayers: state.activePrayers, status: state.todayStatus, timeLabelFor: state.displayTimeFor, period: period),
              const SizedBox(height: 2),
              _WeeklyProgressCard(state: state),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopRow extends StatelessWidget {
  final AppState state;
  const _TopRow({required this.state});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 46,
    child: Row(children: [
      Text('أَقِم', style: GoogleFonts.amiri(fontSize: 25, height: 1, fontWeight: FontWeight.w700, color: AppColors.goldSoft)),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.surfaceElevated, AppColors.surfaceDark]), border: Border.all(color: AppColors.gold.withOpacity(0.38)), borderRadius: BorderRadius.circular(22)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.local_fire_department_rounded, size: 15, color: AppColors.goldSoft), const SizedBox(width: 5), Text('سلسلة ${state.streak}', style: GoogleFonts.tajawal(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.ivory))]),
      ),
      const SizedBox(width: 10),
      _CircleIconButton(icon: Icons.settings_outlined, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()))),
    ]),
  );
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surfaceDark,
    shape: const CircleBorder(),
    child: InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.gold.withOpacity(0.42))), child: Icon(icon, size: 19, color: AppColors.ivory)),
    ),
  );
}

class _TitleBlock extends StatelessWidget {
  final AppState state;
  final String locationLabel;
  const _TitleBlock({required this.state, required this.locationLabel});
  @override
  Widget build(BuildContext context) {
    final locationReady = state.cityName != null;
    return Container(
      height: 104,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 9),
      decoration: BoxDecoration(color: AppColors.surfaceDark.withOpacity(0.72), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.paperLine.withOpacity(0.8))),
      child: Row(children: [
        Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(GregorianArabic.format(DateTime.now()), style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.ivory)),
          const SizedBox(height: 5),
          Text(HijriDate.fromGregorian(DateTime.now()).formatted, style: GoogleFonts.cairo(fontSize: 10.5, color: AppColors.inkSoft)),
          const Spacer(),
          InkWell(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
            borderRadius: BorderRadius.circular(8),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(locationReady ? Icons.location_on_outlined : Icons.error_outline, size: 13, color: locationReady ? AppColors.gold : AppColors.goldSoft),
              const SizedBox(width: 4),
              Text(locationLabel, style: GoogleFonts.cairo(fontSize: 10, color: locationReady ? AppColors.inkSoft : AppColors.goldSoft, fontWeight: FontWeight.w600)),
            ]),
          ),
        ])),
        const SizedBox(width: 12),
        Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [Text('أقم', style: GoogleFonts.amiri(fontSize: 39, height: .9, fontWeight: FontWeight.w700, color: AppColors.goldSoft)), const SizedBox(height: 6), Text('لأجل صلاة في وقتها', style: GoogleFonts.cairo(fontSize: 10.5, color: AppColors.inkSoft, fontWeight: FontWeight.w600))]),
      ]),
    );
  }
}

class _MissedPrayerNotice extends StatelessWidget {
  final AppState state;
  const _MissedPrayerNotice({required this.state});

  @override
  Widget build(BuildContext context) {
    final missed = state.missedTodayPrayers;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (missed.length == 1) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => MissedPrayerResponseScreen(prayer: missed.first)));
            return;
          }
          if (missed.isNotEmpty) {
            showModalBottomSheet<void>(
              context: context,
              backgroundColor: AppColors.surfaceDark,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              builder: (_) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('الصلوات الفائتة', style: GoogleFonts.amiri(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ivory)),
                    const SizedBox(height: 10),
                    ...missed.map((p) => ListTile(
                      leading: const Icon(Icons.error_outline_rounded, color: AppColors.ember),
                      title: Text('فاتتك صلاة ${p.arabicName}', style: GoogleFonts.cairo(color: AppColors.ember, fontWeight: FontWeight.w800)),
                      trailing: const Icon(Icons.chevron_left_rounded, color: AppColors.goldSoft),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => MissedPrayerResponseScreen(prayer: p)));
                      },
                    )),
                  ]),
                ),
              ),
            );
          }
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark.withOpacity(.96),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.ember.withOpacity(.88), width: 1.3),
            boxShadow: [BoxShadow(color: AppColors.ember.withOpacity(.10), blurRadius: 18, spreadRadius: 1)],
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Container(width: 58, height: 58, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.ember.withOpacity(.10), border: Border.all(color: AppColors.ember.withOpacity(.85), width: 1.2)), child: const Icon(Icons.notifications_active_rounded, color: AppColors.ember, size: 31)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('تنبيه الصلاة الفائتة', style: GoogleFonts.amiri(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ember)),
              const SizedBox(height: 3),
              ...missed.map((prayer) => Text('فاتتك صلاة ${prayer.arabicName}', style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ivory, height: 1.35))),
              const SizedBox(height: 5),
              Text('اضغط هنا للإجابة مباشرة: هل صليتها أم لا؟', style: GoogleFonts.cairo(fontSize: 10.5, color: AppColors.inkSoft, height: 1.35)),
            ])),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_left_rounded, color: AppColors.ember, size: 31),
          ]),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final AppState state;
  final Prayer? next;
  final PrayerDayPeriod period;
  const _HeroCard({required this.state, required this.next, required this.period});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: AppColors.surfaceDark, border: Border.all(color: AppColors.gold.withOpacity(0.38)), borderRadius: BorderRadius.circular(22)),
    clipBehavior: Clip.antiAlias,
    child: next == null ? const SizedBox(height: 150) : PrayerArchHero(next: next!, nextRealTime: state.realTimes?[next!], timeLabel: state.displayTimeFor(next!), period: period),
  );
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: _QuickActionCard(icon: Icons.mosque_rounded, title: 'أقرب مسجد', subtitle: 'ابحث عن أقرب مسجد', button: 'عرض الخريطة', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NearbyMosquesScreen())))),
    const SizedBox(width: 8),
    Expanded(child: _QuickActionCard(icon: Icons.bar_chart_rounded, title: 'التقرير الأسبوعي', subtitle: 'متابعة التقدم الأسبوعي', button: 'عرض التقرير', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WeekReportScreen())))),
  ]);
}

class _QiblaQuickAction extends StatelessWidget {
  const _QiblaQuickAction();
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QiblaScreen())),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.centerRight, end: Alignment.centerLeft, colors: [AppColors.surface, AppColors.surfaceDark]),
          border: Border.all(color: AppColors.gold.withOpacity(.30)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.gold.withOpacity(.10), border: Border.all(color: AppColors.gold.withOpacity(.45))), child: const Icon(Icons.explore_rounded, color: AppColors.goldSoft, size: 24)),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('تحديد القبلة', style: GoogleFonts.amiri(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ivory)),
            Text('بوصلة حية باتجاه الكعبة من موقعك', style: GoogleFonts.cairo(fontSize: 10.5, color: AppColors.inkSoft)),
          ])),
          const Icon(Icons.chevron_left_rounded, color: AppColors.gold, size: 28),
        ]),
      ),
    ),
  );
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String button;
  final VoidCallback onTap;
  const _QuickActionCard({required this.icon, required this.title, required this.subtitle, required this.button, required this.onTap});
  @override
  Widget build(BuildContext context) => Container(
    height: 126,
    padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
    decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.surface, AppColors.surfaceDark]), border: Border.all(color: AppColors.gold.withOpacity(0.28)), borderRadius: BorderRadius.circular(18)),
    child: Column(children: [
      Row(children: [Icon(icon, size: 30, color: AppColors.goldSoft), const SizedBox(width: 7), Expanded(child: Text(title, textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.amiri(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ivory)))]),
      const SizedBox(height: 2),
      Align(alignment: Alignment.centerRight, child: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.cairo(fontSize: 9.5, color: AppColors.inkSoft))),
      const Spacer(),
      SizedBox(width: double.infinity, height: 30, child: OutlinedButton(onPressed: onTap, style: OutlinedButton.styleFrom(foregroundColor: AppColors.goldSoft, side: BorderSide(color: AppColors.gold.withOpacity(0.55)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), padding: EdgeInsets.zero), child: Text(button, style: GoogleFonts.cairo(fontSize: 10.5, fontWeight: FontWeight.w700)))),
    ]),
  );
}

class _WeeklyProgressCard extends StatelessWidget {
  final AppState state;
  const _WeeklyProgressCard({required this.state});
  static const _days = ['السبت', 'الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];
  int get _todayDone => state.activePrayers.where((p) => state.todayStatus[p] == PrayerStatus.done).length;
  @override
  Widget build(BuildContext context) {
    final total = state.activePrayers.length;
    final done = _todayDone;
    final progress = total == 0 ? 0.0 : done / total;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(color: AppColors.surfaceDark, border: Border.all(color: AppColors.paperLine.withOpacity(0.75)), borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        Row(children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.gold.withOpacity(0.75)), color: AppColors.gold.withOpacity(0.10)), child: const Icon(Icons.workspace_premium_rounded, color: AppColors.goldSoft, size: 22)),
          const SizedBox(width: 9),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('الإنجاز هذا الأسبوع', style: GoogleFonts.amiri(fontSize: 15.5, fontWeight: FontWeight.w700, color: AppColors.ivory)), Text(done == total ? 'أحسنت، استمر' : 'أكمل صلواتك اليوم', style: GoogleFonts.cairo(fontSize: 9.5, color: AppColors.inkSoft))])),
          Text('$done / $total صلوات', style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.ivory)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: progress.clamp(0, 1), minHeight: 7, backgroundColor: Colors.white.withOpacity(0.10), valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold))),
        const SizedBox(height: 10),
        Row(children: List.generate(_days.length, (i) {
          final isToday = i == _days.length - 1;
          final completed = isToday ? done == total && total > 0 : state.weekHistory[i] >= 80;
          return Expanded(child: Column(children: [Text(_days[i], style: GoogleFonts.cairo(fontSize: 8.5, color: isToday ? AppColors.goldSoft : AppColors.inkSoft, fontWeight: isToday ? FontWeight.w700 : FontWeight.w500)), const SizedBox(height: 4), Container(width: 27, height: 27, decoration: BoxDecoration(shape: BoxShape.circle, color: completed ? AppColors.sage.withOpacity(0.80) : AppColors.ink.withOpacity(0.35), border: Border.all(color: isToday ? AppColors.gold : completed ? AppColors.sage : AppColors.paperLine, width: isToday ? 1.5 : 1)), child: completed ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null)]));
        })),
      ]),
    );
  }
}
