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
import '../widgets/prayer_window_icon.dart';
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

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('لضمان وصول تذكيراتك فوقتها'),
        content: const Text(
          'بعض الهواتف (خصوصًا Xiaomi وHuawei وOppo) توقف التطبيقات في الخلفية تلقائيًا. '
          'فعّل الإعدادات التالية كي تصلك تذكيرات الصلاة دون انقطاع.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('لاحقًا'),
          ),
          ElevatedButton(
            onPressed: () {
              BatteryService.openSettings();
              Navigator.of(context).pop();
            },
            child: const Text('فتح الإعدادات'),
          ),
        ],
      ),
    );
    await state.markBatteryPromptShown();
  }

  String _locationLabel(AppState state) {
    if (!state.notificationsActive) return 'الإشعارات غير مفعّلة';
    if (state.timesLoading) return 'جارٍ تحديد موقعك...';
    return state.cityName ?? 'اضغط لتفعيل تحديد المدينة';
  }

  String? _shortCountdown(AppState state, Prayer next) {
    final real = state.realTimes?[next];
    if (real == null) return null;
    final diff = real.difference(DateTime.now());
    if (diff.isNegative) return null;
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    if (hours > 0) return '$hours س $minutes د';
    return '$minutes د';
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
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
          child: Column(
            children: [
              _TopRow(state: state),
              const SizedBox(height: 10),
              _TitleBlock(state: state, locationLabel: _locationLabel(state)),
              const SizedBox(height: 14),
              _MainCard(
                state: state,
                next: next,
                period: period,
                shortCountdown: next == null ? null : _shortCountdown(state, next),
                remaining: next == null ? null : _remaining(state, next),
              ),
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
                const SizedBox(height: 10),
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
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.gold.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'سلسلة ${state.streak} 🔥',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ),
        const Spacer(),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.gold.withOpacity(0.5)),
        ),
        child: Icon(icon, size: 19, color: Colors.white),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              Text(
                'أقم',
                style: GoogleFonts.amiri(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'لأجل صلاة في وقتها',
                style: TextStyle(fontSize: 12.5, color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              GregorianArabic.format(DateTime.now()),
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white),
              textAlign: TextAlign.end,
            ),
            const SizedBox(height: 2),
            Text(
              HijriDate.fromGregorian(DateTime.now()).formatted,
              style: const TextStyle(fontSize: 10.5, color: Colors.white70),
            ),
            const SizedBox(height: 4),
            InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    locationLabel,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: state.notificationsActive ? Colors.white70 : AppColors.goldSoft,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    state.notificationsActive ? Icons.location_on_outlined : Icons.error_outline,
                    size: 12,
                    color: state.notificationsActive ? Colors.white70 : AppColors.goldSoft,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MainCard extends StatefulWidget {
  final AppState state;
  final Prayer? next;
  final PrayerDayPeriod period;
  final String? shortCountdown;
  final Duration? remaining;

  const _MainCard({
    required this.state,
    required this.next,
    required this.period,
    required this.shortCountdown,
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
        color: AppColors.surfaceDark,
        border: Border.all(color: AppColors.gold.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(26),
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
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 6),
              child: Text(
                'أتممت صلوات اليوم المستهدفة 🎉',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
          if (next != null && _dismissedPrayer != next)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
              child: InAppPrayerNotification(
                prayer: next,
                timeLabel: widget.state.displayTimeFor(next),
                remaining: widget.remaining,
                beforeMinutes: widget.state.beforeMinutes,
                onDismiss: () => setState(() => _dismissedPrayer = next),
                onOpenAdhkar: _openAdhkar,
              ),
            ),
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

  const _PillButton({required this.label, this.icon, required this.onTap, this.filled = true});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
        decoration: BoxDecoration(
          color: filled ? AppColors.surfaceDark : Colors.transparent,
          border: Border.all(color: AppColors.gold.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 17, color: AppColors.gold),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.amiri(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.goldSoft),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
