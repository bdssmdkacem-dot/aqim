import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/adhkar.dart';
import '../theme/app_theme.dart';
import 'adhkar_flow_screen.dart';

class AdhkarHomeScreen extends StatelessWidget {
  const AdhkarHomeScreen({super.key});

  void _open(BuildContext context, String title, List<AdhkarItem> items, String category) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AdhkarFlowScreen(title: title, items: items, audioCategory: category)));
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
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [AppColors.surfaceDark, AppColors.ink.withOpacity(.94)]),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: AppColors.gold.withOpacity(.38)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.gold.withOpacity(.12), border: Border.all(color: AppColors.gold.withOpacity(.55))),
                    child: ClipOval(child: Image.asset('assets/images/aqim_logo_transparent_512.png', fit: BoxFit.contain)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('وردك مع أقم', style: GoogleFonts.amiri(fontSize: 23, color: AppColors.ivory, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 3),
                        Text('أذكار من الكتاب والسنة مرتبة حسب وقتها وحاجة المسلم.', style: GoogleFonts.cairo(fontSize: 11.5, color: AppColors.inkSoft, height: 1.55)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _sectionTitle('الأذكار اليومية'),
            _card(context, Icons.wb_sunny_rounded, 'أذكار الصباح', 'ابدأ يومك بورد الحفظ والطمأنينة', morningAdhkar, 'morning', true),
            _card(context, Icons.nightlight_round, 'أذكار المساء', 'ورد المساء والتحصين قبل الليل', eveningAdhkar, 'evening', true),
            _card(context, Icons.bedtime_rounded, 'أذكار النوم', 'ورد هادئ قبل النوم والتحصين', sleepAdhkar, 'sleep', false),
            _card(context, Icons.wb_twilight_rounded, 'أذكار الاستيقاظ', 'أول ما تقوله عند الاستيقاظ', wakingAdhkar, 'waking', false),
            const SizedBox(height: 14),
            _sectionTitle('أذكار مرتبطة بالصلاة'),
            _card(context, Icons.record_voice_over_rounded, 'ما بين الأذان والإقامة', 'ردّد خلف المؤذن ثم ادعُ بما تشاء', beforePrayerAdhkar, 'before', false),
            _card(context, Icons.check_circle_outline_rounded, 'ما بعد الصلاة', 'ورد متدرج مع عدّاد لكل ذكر', afterPrayerAdhkar, 'after', true),
            const SizedBox(height: 14),
            _sectionTitle('أذكار المواقف اليومية'),
            _card(context, Icons.home_rounded, 'دخول المنزل والخروج منه', 'ذكر الدخول والخروج والتوكل على الله', homeAdhkar, 'home', false),
            _card(context, Icons.mosque_rounded, 'المسجد', 'أذكار الذهاب والدخول والخروج', mosqueAdhkar, 'mosque', false),
            _card(context, Icons.water_drop_rounded, 'الخلاء والوضوء', 'أذكار قبل وبعد الوضوء ودخول الخلاء', bathroomWuduAdhkar, 'wudu', false),
            _card(context, Icons.restaurant_rounded, 'الطعام والشراب', 'ذكر الطعام وبعد الفراغ منه', foodAdhkar, 'food', false),
            _card(context, Icons.directions_car_rounded, 'السفر والركوب', 'دعاء الركوب والسفر والرجوع', travelAdhkar, 'travel', false),
            _card(context, Icons.shield_rounded, 'الحفظ والكرب', 'أذكار الاستعاذة والتوكل والتحصين', protectionAdhkar, 'protection', false),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 9, top: 2),
    child: Text(text, style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w800)),
  );

  Widget _card(BuildContext context, IconData icon, String title, String subtitle, List<AdhkarItem> items, String category, bool featured) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _open(context, title, items, category),
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: featured ? AppColors.gold.withOpacity(.45) : AppColors.paperLine),
            boxShadow: featured ? [BoxShadow(color: AppColors.gold.withOpacity(.06), blurRadius: 18)] : const [],
          ),
          child: Row(
            children: [
              Container(width: 56, height: 56, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.gold.withOpacity(.09), border: Border.all(color: AppColors.gold.withOpacity(.45))), child: Icon(icon, color: AppColors.gold, size: 27)),
              const SizedBox(width: 13),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: GoogleFonts.amiri(fontSize: 18, color: AppColors.ivory, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: GoogleFonts.cairo(fontSize: 10.8, color: AppColors.inkSoft)),
                  const SizedBox(height: 7),
                  Text('${items.length} أذكار', style: GoogleFonts.tajawal(fontSize: 10.5, color: AppColors.gold, fontWeight: FontWeight.w800)),
                ]),
              ),
              const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    ),
  );
}
