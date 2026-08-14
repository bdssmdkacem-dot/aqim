import 'package:flutter/material.dart';
import '../models/adhkar.dart';
import '../theme/app_theme.dart';
import 'adhkar_flow_screen.dart';

/// شاشة تصفّح الأذكار — نقطة دخول دائمة (تبويب) لمن يريد قراءة الأذكار
/// فـ أي وقت، منفصلة عن التدفّق المرتبط بصلاة معيّنة.
class AdhkarHomeScreen extends StatelessWidget {
  const AdhkarHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(title: const Text('الأذكار')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            const Text(
              'اختر مجموعة الأذكار التي تريد قراءتها الآن.',
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 18),
            _AdhkarCategoryCard(
              icon: Icons.brightness_5_outlined,
              title: 'أذكار ما بين الأذان والإقامة',
              subtitle: '${beforePrayerAdhkar.length} أذكار',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AdhkarFlowScreen(
                    title: 'أذكار ما بين الأذان والإقامة',
                    items: beforePrayerAdhkar,
                    audioCategory: 'before',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _AdhkarCategoryCard(
              icon: Icons.nights_stay_outlined,
              title: 'أذكار ما بعد الصلاة',
              subtitle: '${afterPrayerAdhkar.length} أذكار',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AdhkarFlowScreen(
                    title: 'أذكار ما بعد الصلاة',
                    items: afterPrayerAdhkar,
                    audioCategory: 'after',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdhkarCategoryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AdhkarCategoryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          border: Border.all(color: AppColors.paperLine),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.gold, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.arrow_back_ios_new, size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
