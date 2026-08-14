import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/adhkar.dart';
import '../theme/app_theme.dart';
import 'adhkar_flow_screen.dart';

/// نقطة دخول الأذكار في أقم، بنفس هوية الصفحة الرئيسية: أخضر داكن، ذهبي
/// وبطاقات هادئة، مع إبراز الأذكار المرتبطة بالصلاة أولًا.
class AdhkarHomeScreen extends StatelessWidget {
  const AdhkarHomeScreen({super.key});

  void _open(BuildContext context, String title, List<AdhkarItem> items, String category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdhkarFlowScreen(
          title: title,
          items: items,
          audioCategory: category,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        title: Text('الأذكار', style: GoogleFonts.amiri(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [AppColors.surfaceDark, AppColors.ink.withOpacity(.94)],
                ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: AppColors.gold.withOpacity(.38)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.gold.withOpacity(.12),
                          border: Border.all(color: AppColors.gold.withOpacity(.55)),
                        ),
                        child: const Icon(Icons.menu_book_rounded, color: AppColors.gold, size: 27),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('وردك مع أقم', style: GoogleFonts.amiri(fontSize: 23, color: AppColors.ivory, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text('أذكار مرتبة لتكون قريبة منك قبل الصلاة وبعدها.', style: GoogleFonts.cairo(fontSize: 11.5, color: AppColors.inkSoft)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _StatChip(label: '${afterPrayerAdhkar.length}', caption: 'بعد الصلاة'),
                      const SizedBox(width: 8),
                      _StatChip(label: '${beforePrayerAdhkar.length}', caption: 'قبل الصلاة'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('أذكار مرتبطة بالصلاة', style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w700)),
            const SizedBox(height: 9),
            _AdhkarCategoryCard(
              icon: Icons.record_voice_over_rounded,
              accent: AppColors.gold,
              title: 'أذكار ما بين الأذان والإقامة',
              subtitle: 'ردّد خلف المؤذن ثم ادعُ بما تشاء',
              count: beforePrayerAdhkar.length,
              onTap: () => _open(context, 'أذكار ما بين الأذان والإقامة', beforePrayerAdhkar, 'before'),
            ),
            const SizedBox(height: 11),
            _AdhkarCategoryCard(
              icon: Icons.nightlight_round,
              accent: AppColors.gold,
              title: 'أذكار ما بعد الصلاة',
              subtitle: 'ورد قصير متدرج مع عدّاد لكل ذكر',
              count: afterPrayerAdhkar.length,
              featured: true,
              onTap: () => _open(context, 'أذكار ما بعد الصلاة', afterPrayerAdhkar, 'after'),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark.withOpacity(.72),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.paperLine),
              ),
              child: Row(
                children: [
                  const Icon(Icons.touch_app_rounded, color: AppColors.gold, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'داخل الذكر اضغط على النص أو الدائرة للتكرار، واستمع للصوت إذا كان متوفرًا.',
                      style: GoogleFonts.cairo(fontSize: 11.5, color: AppColors.inkSoft, height: 1.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String caption;
  const _StatChip({required this.label, required this.caption});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.gold.withOpacity(.06),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.gold.withOpacity(.18)),
        ),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(text: '$label  ', style: GoogleFonts.tajawal(color: AppColors.gold, fontWeight: FontWeight.w800)),
              TextSpan(text: caption, style: GoogleFonts.cairo(color: AppColors.inkSoft, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdhkarCategoryCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final int count;
  final bool featured;
  final VoidCallback onTap;

  const _AdhkarCategoryCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.onTap,
    this.featured = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: featured ? accent.withOpacity(.48) : AppColors.paperLine),
            boxShadow: featured
                ? [BoxShadow(color: accent.withOpacity(.08), blurRadius: 22, spreadRadius: 1)]
                : const [],
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withOpacity(.10),
                  border: Border.all(color: accent.withOpacity(.52)),
                ),
                child: Icon(icon, color: accent, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.amiri(fontSize: 19, color: AppColors.ivory, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(subtitle, style: GoogleFonts.cairo(fontSize: 11, color: AppColors.inkSoft)),
                    const SizedBox(height: 8),
                    Text('$count أذكار', style: GoogleFonts.tajawal(fontSize: 10.5, color: accent, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
