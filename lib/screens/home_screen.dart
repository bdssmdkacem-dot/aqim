import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../ads/app_banner_ad.dart';
import '../models/adhkar.dart';
import '../models/prayer.dart';
import '../services/battery_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/gregorian_arabic.dart';
import '../utils/hijri_date.dart';
import '../widgets/day_arc.dart';
import '../widgets/in_app_prayer_notification.dart';
import '../widgets/missed_prayers_card.dart';
import '../widgets/prayer_arch_hero.dart';
import 'adhkar_flow_screen.dart';
import 'nearby_mosques_screen.dart';
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
        title: Text(
          'لضمان وصول تذكيراتك فوقتها',
          style: GoogleFonts.amiri(
            color: AppColors.ivory,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'بعض الهواتف (خصوصًا Xiaomi وHuawei وOppo) توقف التطبيقات في الخلفية تلقائيًا. فعّل السماح لأقم بالعمل في الخلفية والتشغيل التلقائي حتى تصلك تذكيرات الصلاة في وقتها.',
          style: GoogleFonts.cairo(
            color: AppColors.inkSoft,
            height: 1.7,
            fontSize: 13.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('لاحقًا', style: GoogleFonts.cairo(color: AppColors.inkSoft)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('تحسين البطارية'),
          ),
        ],
      ),
    );

    if (openSettings == true) {
      await BatteryService.openSettings();
      final granted = await BatteryService.isFullyExempted();
      if (granted && mounted) {
        await state.markBatteryPromptShown();
      }
    }
  }

  String _locationLabel(AppState state) {
    if (!state.notificationsActive) return 'الإشعارات غير مفعّلة';
    if (state.timesLoading) return 'جارٍ تحديد موقعك...';
    return state.cityName ?? 'اضغط لتفعيل تحديد المدينة';
  }

  Duration? _remaining(AppState state, Prayer next) {
    final real = state.realTimes?[next];
    if (real == null) return null;
    final diff = real.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            children: [
              _TopRow(state: state),
              const SizedBox(height: 12),
              _TitleBlock(state: state, locationLabel: _locationLabel(state)),
              const SizedBox(height: 16),
              _MainCard(
                state: state,
                next: next,
                period: period,
                remaining: next == null ? null : _remaining(state, next),
              ),
              const SizedBox(height: 12),
              const MissedPrayersCard(),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _PillButton(
                      icon: Icons.mosque_outlined,
                      label: 'أقرب مسجد',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const NearbyMosquesScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PillButton(
                      icon: Icons.bar_chart_rounded,
                      label: 'التقرير الأسبوعي',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const WeekReportScreen()),
                      ),
                    ),
                  ),
                ],
              ),
              if (!state.adsRemoved) ...[
                const SizedBox(height: 14),
                const AppBannerAd(),
              ],
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
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleIconButton(
          icon: Icons.settings_outlined,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
        ),
        const SizedBox(width: 9),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.surfaceElevated,
                AppColors.surfaceDark,
              ],
            ),
            border: Border.all(color: AppColors.gold.withOpacity(0.38)),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_fire_department_rounded, size: 15, color: AppColors.goldSoft),
              const SizedBox(width: 5),
              Text(
                'سلسلة ${state.streak}',
                style: GoogleFonts.tajawal(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ivory,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Text(
          'أَقِم',
          style: GoogleFonts.amiri(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: AppColors.goldSoft,
          ),
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceDark,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.gold.withOpacity(0.42)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(Icons.settings_outlined, size: 19, color: AppColors.ivory),
        ),
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  final AppState state;
  final String locationLabel;
  const _TitleBlock({required this.state, required this.locationLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withOpacity(0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.paperLine.withOpacity(0.8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'أقم',
                  style: GoogleFonts.amiri(
                    fontSize: 35,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldSoft,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'لأجل صلاة في وقتها',
                  style: GoogleFonts.cairo(
                    fontSize: 11.5,
                    color: AppColors.inkSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                GregorianArabic.format(DateTime.now()),
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ivory,
                ),
                textAlign: TextAlign.end,
              ),
              const SizedBox(height: 2),
              Text(
                HijriDate.fromGregorian(DateTime.now()).formatted,
                style: GoogleFonts.cairo(fontSize: 10, color: AppColors.inkSoft),
              ),
              const SizedBox(height: 5),
              InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        state.notificationsActive ? Icons.location_on_outlined : Icons.error_outline,
                        size: 12,
                        color: state.notificationsActive ? AppColors.gold : AppColors.goldSoft,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        locationLabel,
                        style: GoogleFonts.cairo(
                          fontSize: 10,
                          color: state.notificationsActive ? AppColors.inkSoft : AppColors.goldSoft,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MainCard extends StatefulWidget {
  final AppState state;
  final Prayer? next;
  final PrayerDayPeriod period;
  final Duration? remaining;

  const _MainCard({
    required this.state,
    required this.next,
    required this.period,
    required this.remaining,
  });

  @override
  State<_MainCard> createState() => _MainCardState();
}

class _MainCardState extends State<_MainCard> {
  Prayer? _dismissedPrayer;

  @override
  void didUpdateWidget(covariant _MainCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.next != _dismissedPrayer) {
      _dismissedPrayer = null;
    }
  }

  void _openAdhkar() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AdhkarFlowScreen(
          title: 'أذكار ما بين الأذان والإقامة',
          items: beforePrayerAdhkar,
          audioCategory: 'before',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final next = widget.next;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.surfaceElevated,
            AppColors.surfaceDark,
          ],
        ),
        border: Border.all(color: AppColors.gold.withOpacity(0.46)),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
          BoxShadow(
            color: AppColors.gold.withOpacity(0.035),
            blurRadius: 28,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 14),
      child: Column(
        children: [
          if (next != null)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
              child: PrayerArchHero(
                next: next,
                nextRealTime: widget.state.realTimes?[next],
                timeLabel: widget.state.displayTimeFor(next),
                period: widget.period,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 24, 18, 8),
              child: Text(
                'أتممت صلوات اليوم المستهدفة 🎉',
                style: GoogleFonts.amiri(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldSoft,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          if (next != null && _dismissedPrayer != next)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 2),
              child: InAppPrayerNotification(
                prayer: next,
                timeLabel: widget.state.displayTimeFor(next),
                remaining: widget.remaining,
                beforeMinutes: widget.state.beforeMinutes,
                onDismiss: () => setState(() => _dismissedPrayer = next),
                onOpenAdhkar: _openAdhkar,
              ),
            ),
          const SizedBox(height: 4),
          DayArc(
            prayers: widget.state.activePrayers,
            status: widget.state.todayStatus,
            timeLabelFor: widget.state.displayTimeFor,
            period: widget.period,
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool filled;

  const _PillButton({
    required this.label,
    this.icon,
    required this.onTap,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
          decoration: BoxDecoration(
            gradient: filled
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.surface, AppColors.surfaceDark],
                  )
                : null,
            color: filled ? null : Colors.transparent,
            border: Border.all(color: AppColors.gold.withOpacity(0.34)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 17, color: AppColors.goldSoft),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.amiri(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ivory,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
