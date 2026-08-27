import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../ads/app_interstitial_ad.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'nearby_mosques_screen.dart';
import 'prayer_guide_screen.dart';
import 'qibla_screen.dart';
import 'settings_screen.dart';
import 'week_report_screen.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  @override
  void initState() {
    super.initState();
    // Keep the weekly-report interstitial warm while the user is in More.
    AppInterstitialAd.preload();
  }

  Future<void> _shareApp(BuildContext context) async {
    await SharePlus.instance.share(
      ShareParams(
        subject: 'تطبيق أقم',
        text:
            'شارك الخير مع عائلتك ❤️\n\n'
            'تطبيق أقم — لأجل صلاة في وقتها.\n'
            'يساعدك على متابعة أوقات الصلاة، القرآن الكريم، الأذكار والقبلة.\n\n'
            'حمّل تطبيق أقم وشاركه مع من تحب:\n'
            'https://play.google.com/store/apps/details?id=com.comptaflow.aqim',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(title: const Text('المزيد')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            _MenuTile(
              icon: Icons.explore_rounded,
              title: 'تحديد القبلة',
              subtitle: 'بوصلة حية',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QiblaScreen())),
            ),
            _MenuTile(
              icon: Icons.menu_book_rounded,
              title: 'كيف أقيم صلاتي؟',
              subtitle: 'من الوضوء إلى التسليم',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrayerGuideScreen())),
            ),
            _MenuTile(
              icon: Icons.mosque_outlined,
              title: 'أقرب مسجد',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NearbyMosquesScreen())),
            ),
            _MenuTile(
              icon: Icons.bar_chart_rounded,
              title: 'التقرير الأسبوعي',
              onTap: () {
                // Interstitials are intentionally restricted to this action.
                AppInterstitialAd.showIfReady();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WeekReportScreen()));
              },
            ),
            _MenuTile(
              icon: Icons.settings_outlined,
              title: 'الإعدادات',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
            _MenuTile(
              icon: Icons.family_restroom_rounded,
              title: 'شارك التطبيق مع عائلتك',
              subtitle: 'شارك الخير',
              onTap: () => _shareApp(context),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text('أقم — لأجل صلاة في وقتها', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _MenuTile({required this.icon, required this.title, this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(color: AppColors.surfaceDark, border: Border.all(color: AppColors.paperLine), borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Icon(icon, color: AppColors.gold, size: 21),
              const SizedBox(width: 14),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Flexible(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white))),
                    if (subtitle != null) ...[
                      const SizedBox(width: 10),
                      Flexible(child: Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.left, style: const TextStyle(fontSize: 10.5, color: AppColors.gold, fontWeight: FontWeight.w700))),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_back_ios_new, size: 13, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
