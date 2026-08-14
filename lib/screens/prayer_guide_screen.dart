import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class PrayerGuideScreen extends StatelessWidget {
  const PrayerGuideScreen({super.key});

  static const _steps = <_PrayerStep>[
    _PrayerStep(
      '١',
      'الوضوء',
      'توضأ واستحضر النية، ثم اغسل الكفين، وتمضمض واستنشق، واغسل الوجه، واليدين إلى المرفقين، وامسح الرأس والأذنين، واغسل الرجلين.',
      Icons.water_drop_rounded,
    ),
    _PrayerStep(
      '٢',
      'الاستعداد للصلاة',
      'تأكد من دخول الوقت، وطهارة البدن والثوب والمكان، وستر العورة، واستقبال القبلة. واستحضر نية الصلاة في القلب.',
      Icons.explore_rounded,
    ),
    _PrayerStep(
      '٣',
      'تكبيرة الإحرام والقيام',
      'قف مستقبلاً القبلة، وارفع يديك وقل: «الله أكبر»، ثم ضع يديك في موضعهما واقرأ الفاتحة، ويُقرأ بعدها ما تيسر من القرآن في الركعتين الأوليين من الفرض.',
      Icons.accessibility_new_rounded,
    ),
    _PrayerStep(
      '٤',
      'الركوع والرفع منه',
      'قل «الله أكبر» واركع مطمئنًا، ثم ارفع قائلاً «سمع الله لمن حمده»، وبعد الاعتدال قل «ربنا ولك الحمد».',
      Icons.south_rounded,
    ),
    _PrayerStep(
      '٥',
      'السجود والجلوس بين السجدتين',
      'اسجد قائلاً «الله أكبر»، واطمئن في السجود، ثم ارفع قائلاً «الله أكبر» واجلس مطمئنًا، ثم اسجد السجدة الثانية.',
      Icons.keyboard_arrow_down_rounded,
    ),
    _PrayerStep(
      '٦',
      'الركعة التالية',
      'قم للركعة التالية قائلاً «الله أكبر»، وأدِّها بالطريقة نفسها. وفي الصلاة التي فيها تشهد أول، اجلس بعد الركعة الثانية للتشهد ثم قم لما بقي من الصلاة.',
      Icons.refresh_rounded,
    ),
    _PrayerStep(
      '٧',
      'التشهد الأخير',
      'في آخر الصلاة اجلس للتشهد الأخير، واقرأ التشهد والصلاة على النبي ﷺ، ثم استعد للتسليم.',
      Icons.menu_book_rounded,
    ),
    _PrayerStep(
      '٨',
      'التسليم وإنهاء الصلاة',
      'سلّم عن اليمين قائلاً «السلام عليكم ورحمة الله»، ثم عن اليسار قائلاً «السلام عليكم ورحمة الله». وهنا تنتهي الصلاة.',
      Icons.check_circle_outline_rounded,
    ),
    _PrayerStep(
      '٩',
      'أذكار ما بعد الصلاة',
      'بعد السلام يمكنك الانتقال إلى أذكار ما بعد الصلاة في أقم، وقراءتها بالترتيب مع عدد التكرارات المبيّن لكل ذكر.',
      Icons.auto_awesome_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        backgroundColor: AppColors.ink,
        title: Text('كيف أقيم صلاتي؟', style: GoogleFonts.amiri(fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [AppColors.surfaceDark, AppColors.ink.withOpacity(.96)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.gold.withOpacity(.32)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.mosque_rounded, color: AppColors.gold, size: 42),
                  const SizedBox(height: 10),
                  Text('دليل مبسط للصلاة', style: GoogleFonts.amiri(fontSize: 25, color: AppColors.ivory, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(
                    'من الوضوء والاستعداد إلى التسليم، ثم أذكار ما بعد الصلاة.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(fontSize: 12, color: AppColors.inkSoft, height: 1.7),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ..._steps.asMap().entries.map((entry) {
              final step = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark.withOpacity(.72),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.gold.withOpacity(.18)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.gold.withOpacity(.10),
                          border: Border.all(color: AppColors.gold.withOpacity(.45)),
                        ),
                        child: Center(child: Text(step.number, style: GoogleFonts.tajawal(color: AppColors.gold, fontWeight: FontWeight.w900))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(step.icon, color: AppColors.gold, size: 19),
                                const SizedBox(width: 7),
                                Expanded(child: Text(step.title, style: GoogleFonts.amiri(fontSize: 19, color: AppColors.ivory, fontWeight: FontWeight.w800))),
                              ],
                            ),
                            const SizedBox(height: 7),
                            Text(step.body, textAlign: TextAlign.right, style: GoogleFonts.cairo(fontSize: 12, color: AppColors.inkSoft, height: 1.8)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 4),
            Text(
              'تنبيه: قد تختلف بعض التفاصيل الجزئية في صفة الصلاة والوضوء باختلاف المذهب، وهذا الدليل مبسط للتذكير وليس بديلاً عن سؤال أهل العلم عند الحاجة.',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 10, color: AppColors.textMuted, height: 1.7),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerStep {
  final String number;
  final String title;
  final String body;
  final IconData icon;
  const _PrayerStep(this.number, this.title, this.body, this.icon);
}
