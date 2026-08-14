import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/prayer.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'reason_screen.dart';

/// شاشة مباشرة من إشعار الصلاة الفائتة: قرار واحد فقط، ثم يتم تحديث السجل
/// وإلغاء إشعار الصلاة الفائتة عند اختيار «صليتها».
class MissedPrayerResponseScreen extends StatelessWidget {
  final Prayer prayer;

  const MissedPrayerResponseScreen({super.key, required this.prayer});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();

    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        title: Text('صلاة ${prayer.arabicName}', style: GoogleFonts.amiri(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: AppColors.ember.withOpacity(.65), width: 1.2),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.ember.withOpacity(.12),
                      border: Border.all(color: AppColors.ember.withOpacity(.7)),
                    ),
                    child: const Icon(Icons.notifications_active_rounded, color: AppColors.ember, size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text('فاتتك صلاة ${prayer.arabicName}', textAlign: TextAlign.center, style: GoogleFonts.amiri(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.ivory)),
                  const SizedBox(height: 7),
                  Text('اختر حالتها مرة واحدة ليُحدَّث سجل أقم.', textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 12.5, color: AppColors.inkSoft)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text('ماذا حدث؟', style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _ChoiceButton(
              icon: Icons.check_circle_rounded,
              title: 'صليت',
              subtitle: 'تمت الصلاة — سيُغلق تذكيرها الفائت.',
              color: AppColors.sage,
              onTap: () async {
                await state.markDone(prayer);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 10),
            _ChoiceButton(
              icon: Icons.schedule_rounded,
              title: 'لم أصلِّ بعد',
              subtitle: 'سجّل سبب التأخير واختر الخطوة التالية.',
              color: AppColors.ember,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ReasonScreen(prayer: prayer)),
                );
              },
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.paper.withOpacity(.035),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.paperLine),
              ),
              child: Text(
                'لن يظهر لك زوج آخر من أزرار «صليت / لم أصلِّ بعد» في نفس الشاشة.',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 10.5, color: AppColors.textMuted, height: 1.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ChoiceButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(.45)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.cairo(fontSize: 17, color: AppColors.ivory, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: GoogleFonts.cairo(fontSize: 10.5, color: AppColors.textMuted)),
                  ],
                ),
              ),
              Icon(Icons.arrow_back_ios_new_rounded, color: color.withOpacity(.75), size: 15),
            ],
          ),
        ),
      ),
    );
  }
}
