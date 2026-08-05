import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../ads/app_banner_ad.dart';
import '../models/prayer.dart';
import '../services/battery_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/gregorian_arabic.dart';
import '../utils/hijri_date.dart';
import '../widgets/day_arc.dart';
import '../widgets/prayer_window_icon.dart';
import 'nearby_mosques_screen.dart';
import 'pre_prayer_screen.dart';
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

  String _identityMessage(AppState state) {
    if (state.streak >= 21) return 'أنت من المحافظين على الصلاة';
    if (state.streak >= 7) return 'أنت شخص يحافظ على ${state.activePrayers.first.arabicName}';
    if (state.streak >= 1) return 'بداية موفقة — استمر بنفس الوتيرة';
    return 'اليوم فرصة جديدة للبدء';
  }

  String _locationLabel(AppState state) {
    if (!state.notificationsActive) return 'الإشعارات غير مفعّلة';
    if (state.timesLoading) return 'جارٍ تحديد موقعك...';
    return state.cityName ?? 'اضغط لتفعيل تحديد المدينة';
  }

  /// نص العدّاد التنازلي حتى الصلاة القادمة بصيغة سّ:د، أو null إن لم
  /// تتوفّر أوقات حقيقية بعد.
  String? _countdownLabel(AppState state, Prayer next) {
    final real = state.realTimes?[next];
    if (real == null) return null;
    final diff = real.difference(DateTime.now());
    if (diff.isNegative) return null;
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    if (hours > 0) return 'باقي $hours س $minutes د';
    return 'باقي $minutes د';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final next = state.nextPrayer;
    final period = currentDayPeriod();

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
          child: Column(
            children: [
              _TopRow(state: state),
              const SizedBox(height: 10),
              _TitleBlock(state: state, locationLabel: _locationLabel(state)),
              const SizedBox(height: 10),
              DayArc(
                prayers: state.activePrayers,
                status: state.todayStatus,
                timeLabelFor: state.displayTimeFor,
              ),
              const Spacer(),
              if (next != null)
                _NextPrayerCard(
                  state: state,
                  next: next,
                  period: period,
                  countdown: _countdownLabel(state, next),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    border: Border.all(color: AppColors.gold.withOpacity(0.35)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'أتممت صلوات اليوم المستهدفة 🎉',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 12),
              _PillButton(
                label: _identityMessage(state),
                onTap: null,
                filled: false,
              ),
              const SizedBox(height: 10),
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

class _NextPrayerCard extends StatelessWidget {
  final AppState state;
  final Prayer next;
  final DayPeriod period;
  final String? countdown;

  const _NextPrayerCard({
    required this.state,
    required this.next,
    required this.period,
    required this.countdown,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PrePrayerScreen(prayer: next)),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          border: Border.all(color: AppColors.gold.withOpacity(0.45)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'الصلاة القادمة',
                    style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    next.arabicName,
                    style: GoogleFonts.amiri(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.goldSoft),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    state.displayTimeFor(next),
                    style: GoogleFonts.tajawal(fontSize: 30, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  if (countdown != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.hourglass_bottom, size: 13, color: AppColors.gold),
                        const SizedBox(width: 4),
                        Text(countdown!, style: const TextStyle(fontSize: 12.5, color: AppColors.gold, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Container(
              width: 1,
              height: 70,
              color: AppColors.gold.withOpacity(0.3),
              margin: const EdgeInsets.symmetric(horizontal: 12),
            ),
            SizedBox(
              width: 84,
              height: 84,
              child: PrayerWindowIcon(period: period),
            ),
          ],
        ),
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
