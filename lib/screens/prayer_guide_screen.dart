import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class PrayerGuideScreen extends StatelessWidget {
  const PrayerGuideScreen({super.key});

  static const _steps = <_PrayerStep>[
    _PrayerStep('١', 'الوضوء', 'استحضر النية، واغسل الكفين، وتمضمض واستنشق، واغسل الوجه، ثم اليدين إلى المرفقين، وامسح الرأس والأذنين، واغسل الرجلين. احرص على إتمام الوضوء بهدوء وطهارة.', Icons.water_drop_rounded),
    _PrayerStep('٢', 'الاستعداد للصلاة', 'تأكد من دخول وقت الصلاة، وطهارة البدن والثوب والمكان، وستر العورة، واستقبال القبلة. النية محلها القلب ولا تحتاج إلى التلفظ بها.', Icons.checkroom_rounded),
    _PrayerStep('٣', 'تكبيرة الإحرام', 'قف مستقبل القبلة، وارفع يديك وقل: «الله أكبر»، ثم ضع اليدين في موضعهما واقرأ الفاتحة. ويُقرأ بعدها ما تيسر من القرآن في الركعتين الأوليين من الفرض.', Icons.accessibility_new_rounded),
    _PrayerStep('٤', 'الركوع', 'بعد القراءة قل «الله أكبر» واركع مطمئنًا، واجعل ظهرك مستويًا قدر الاستطاعة، وسبّح ربك في الركوع. لا تعجل في الانتقال بين الأركان.', Icons.south_rounded),
    _PrayerStep('٥', 'الرفع من الركوع', 'ارفع من الركوع قائلاً «سمع الله لمن حمده»، ثم اعتدل قائمًا وقل «ربنا ولك الحمد». انتظر حتى يستقر البدن قبل الانتقال للسجود.', Icons.north_rounded),
    _PrayerStep('٦', 'السجود', 'قل «الله أكبر» واسجد مطمئنًا، ثم ادعُ الله في سجودك. ارفع قائلاً «الله أكبر» واجلس بين السجدتين مطمئنًا، ثم اسجد السجدة الثانية.', Icons.keyboard_arrow_down_rounded),
    _PrayerStep('٧', 'الركعة الثانية وما بعدها', 'قم للركعة التالية قائلاً «الله أكبر»، وأدِّها بالطريقة نفسها. في الصلاة ذات التشهد الأول، اجلس بعد الركعة الثانية للتشهد ثم قم لما بقي من الصلاة.', Icons.refresh_rounded),
    _PrayerStep('٨', 'التشهد الأخير', 'في آخر الصلاة اجلس للتشهد الأخير، واقرأ التشهد والصلاة على النبي ﷺ، ثم استعد للتسليم. في الصلاة الثنائية يكون هذا التشهد في الركعة الثانية.', Icons.menu_book_rounded),
    _PrayerStep('٩', 'التسليم', 'سلّم عن اليمين قائلاً «السلام عليكم ورحمة الله»، ثم عن اليسار قائلاً «السلام عليكم ورحمة الله». وبذلك تنتهي الصلاة.', Icons.check_circle_outline_rounded),
    _PrayerStep('١٠', 'أذكار ما بعد الصلاة', 'بعد السلام يمكنك الانتقال إلى أذكار ما بعد الصلاة في أقم، وقراءتها بالترتيب مع عدد التكرارات المبيّن لكل ذكر.', Icons.auto_awesome_rounded),
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
          physics: const BouncingScrollPhysics(),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [AppColors.surfaceDark, AppColors.ink.withOpacity(.96)]),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.gold.withOpacity(.35)),
              ),
              child: Column(children: [
                Container(width: 64, height: 64, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.gold.withOpacity(.10), border: Border.all(color: AppColors.gold.withOpacity(.55))), child: const Icon(Icons.mosque_rounded, color: AppColors.gold, size: 34)),
                const SizedBox(height: 10),
                Text('كيف أقيم صلاتي؟', style: GoogleFonts.amiri(fontSize: 26, color: AppColors.ivory, fontWeight: FontWeight.w800)),
                const SizedBox(height: 5),
                Text('دليل عملي من الوضوء والاستعداد، مرورًا بأركان الصلاة، حتى التسليم وأذكار ما بعد الصلاة.', textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 11.5, color: AppColors.inkSoft, height: 1.75)),
              ]),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              decoration: BoxDecoration(color: AppColors.surface.withOpacity(.7), borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.paperLine.withOpacity(.65))),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.goldSoft, size: 21),
                const SizedBox(width: 8),
                Expanded(child: Text('للقبلة يمكنك فتح «تحديد القبلة» من الصفحة الرئيسية قبل بدء الصلاة.', textAlign: TextAlign.right, style: GoogleFonts.cairo(fontSize: 10.5, color: AppColors.inkSoft, height: 1.6))),
              ]),
            ),
            const SizedBox(height: 14),
            ..._steps.map((step) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 15),
                decoration: BoxDecoration(color: AppColors.surfaceDark.withOpacity(.78), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.gold.withOpacity(.18))),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: 45, height: 45, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.gold.withOpacity(.10), border: Border.all(color: AppColors.gold.withOpacity(.45))), child: Center(child: Text(step.number, style: GoogleFonts.tajawal(color: AppColors.gold, fontWeight: FontWeight.w900)))),
                  const SizedBox(width: 11),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [Icon(step.icon, color: AppColors.gold, size: 19), const SizedBox(width: 7), Expanded(child: Text(step.title, style: GoogleFonts.amiri(fontSize: 19, color: AppColors.ivory, fontWeight: FontWeight.w800)))]),
                    const SizedBox(height: 6),
                    Text(step.body, textAlign: TextAlign.right, style: GoogleFonts.cairo(fontSize: 12, color: AppColors.inkSoft, height: 1.85)),
                  ])),
                ]),
              ),
            )),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.ink.withOpacity(.55), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.paperLine.withOpacity(.5))),
              child: Text('تنبيه: قد تختلف بعض التفاصيل الجزئية في صفة الصلاة والوضوء باختلاف المذهب. هذا الدليل مبسط للتذكير والتعليم العام، وليس بديلاً عن سؤال أهل العلم عند الحاجة.', textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 9.5, color: AppColors.textMuted, height: 1.7)),
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
