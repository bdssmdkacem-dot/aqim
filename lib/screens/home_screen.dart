import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../ads/app_banner_ad.dart';
import '../models/prayer.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/day_arc.dart';
import 'pre_prayer_screen.dart';
import 'week_report_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _identityMessage(AppState state) {
    if (state.streak >= 21) return 'أنت من المحافظين على الصلاة';
    if (state.streak >= 7) return 'أنت شخص يحافظ على ${state.activePrayers.first.arabicName}';
    if (state.streak >= 1) return 'بداية موفقة — استمر بنفس الوتيرة';
    return 'اليوم فرصة جديدة للبدء';
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
            padding: const EdgeInsets.only(left: 16),
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
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            DayArc(prayers: state.activePrayers, status: state.todayStatus),
            const SizedBox(height: 8),
            if (next != null)
              Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => PrePrayerScreen(prayer: next)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('الصلاة القادمة', style: Theme.of(context).textTheme.labelSmall),
                              const SizedBox(height: 4),
                              Text('صلاة ${next.arabicName}', style: Theme.of(context).textTheme.titleMedium),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.textMuted),
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
                color: AppColors.ink,
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
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const WeekReportScreen()),
              ),
              child: const Text('عرض التقرير الأسبوعي'),
            ),
            const SizedBox(height: 16),
            const Center(child: AppBannerAd()),
          ],
        ),
      ),
    );
  }
}
