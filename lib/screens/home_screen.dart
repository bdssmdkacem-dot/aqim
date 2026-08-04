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

  class _PillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool filled;

  const _PillButton({
    super.key,
    required this.label,
    this.icon,
    required this.onTap,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: 13,
          horizontal: 14,
        ),
        decoration: BoxDecoration(
          color: filled
              ? AppColors.surfaceDark.withOpacity(0.7)
              : Colors.transparent,
          border: Border.all(
            color: AppColors.gold.withOpacity(0.5),
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon!,
                size: 17,
                color: AppColors.gold,
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.amiri(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldSoft,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
