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
    if (!state.notificationsActive) {
      return 'الإشعارات غير مفعّلة — اضغط لمعرفة السبب';
    }
    if (state.timesLoading) return 'جارٍ تحديد موقعك...';
    return state.cityName ?? 'اضغط لتفعيل تحديد المدينة';
  }

  /// نص العدّاد التنازلي حتى الصلاة القادمة (مثلاً "باقي ١ س ١٥ د")، أو
  /// null إن لم تتوفّر أوقات حقيقية بعد.
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('أقم'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'سلسلة ${state.streak} 🔥',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'الإعدادات',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    GregorianArabic.format(DateTime.now()),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    HijriDate.fromGregorian(DateTime.now()).formatted,
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
                child: Row(
                  children: [
                    Icon(
                      !state.notificationsActive
                          ? Icons.error_outline
                          : Icons.location_on_outlined,
                      size: 15,
                      color: !state.notificationsActive ? AppColors.ember : AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _locationLabel(state),
                        style: TextStyle(
                          fontSize: 12,
                          color: !state.notificationsActive ? AppColors.ember : AppColors.textMuted,
                          fontWeight: !state.notificationsActive ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            DayArc(
              prayers: state.activePrayers,
              status: state.todayStatus,
              timeLabelFor: state.displayTimeFor,
            ),
            const SizedBox(height: 8),
            if (next != null)
              Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => PrePrayerScreen(prayer: next)),
                  ),
                  child: SizedBox(
                    height: 190,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assets/images/prayer_banner.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.surfaceDark, AppColors.ink],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.05),
                                Colors.black.withOpacity(0.78),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 14,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'الصلاة القادمة',
                                style: TextStyle(fontSize: 11.5, color: Colors.white70, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    next.arabicName,
                                    style: GoogleFonts.amiri(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.goldSoft,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    state.displayTimeFor(next),
                                    style: GoogleFonts.tajawal(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              if (_countdownLabel(state, next) != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _countdownLabel(state, next)!,
                                  style: const TextStyle(fontSize: 12, color: AppColors.gold, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'أتممت صلوات اليوم المستهدفة 🎉',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                border: Border.all(color: AppColors.gold.withOpacity(0.35)),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                _identityMessage(state),
                textAlign: TextAlign.center,
                style: GoogleFonts.amiri(
                  color: AppColors.gold,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const WeekReportScreen()),
                    ),
                    child: const Text('التقرير الأسبوعي'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NearbyMosquesScreen()),
                    ),
                    icon: const Icon(Icons.mosque_outlined, size: 18),
                    label: const Text('أقرب مسجد'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!state.adsRemoved) const Center(child: AppBannerAd()),
          ],
        ),
      ),
    );
  }
}
