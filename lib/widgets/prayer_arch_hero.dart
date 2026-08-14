import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/prayer.dart';
import '../theme/app_theme.dart';
import 'prayer_window_icon.dart'
    show PrayerDayPeriod;

/// شكل "قوس المحراب" (مغربي/أندلسي — قوس حدوة حصان مدبَّب) الذي يظهر
/// أعلى الصفحة الرئيسية، ويحتضن صورة/رسمة المسجد ومعلومات الصلاة القادمة.
///
/// **بخصوص صورة الخلفية**: هذا الودجت يحاول أولًا تحميل صورة حقيقية من
/// `assets/images/arch_hero.jpg`. إن لم يُضَف الملف بعد (أو فشل تحميله)،
/// يعرض تلقائيًا رسمة بديلة مرسومة بالكامل بالكود (سماء + شمس/قمر +
/// مسجد + انعكاس فـ الماء) بلا أي كراش — لذا التطبيق يعمل ويبدو جيدًا
/// فورًا حتى بدون إضافة صورة.
///
/// **قياسات الصورة المطلوبة إن أردت استعمال صورة حقيقية بدل الرسمة**:
/// - الملف: `assets/images/arch_hero.jpg` (أو .png/.webp — عدّل الامتداد
///   فـ الكود إن غيّرت الصيغة).
/// - المقاس الموصى به: **1600×960px** كحدّ أدنى (نسبة عرض:ارتفاع ≈ 5:3،
///   أي 1.67)، ويُفضَّل **2400×1440px** لتغطية الشاشات عالية الكثافة
///   بجودة جيدة (يُعرَض العنصر بعرض الشاشة الكامل تقريبًا).
/// - المحتوى: ضع السماء/الأفق فـ النصف العلوي، والمسجد (قبة + مآذن)
///   فـ الثلث الأوسط تقريبًا مُتمركزًا أفقيًا (لأن قمة القوس المدبّبة
///   تقصّ أعلى المنتصف)، وأي انعكاس ماء أو أرض فـ الشُّريط السفلي.
///   الجزء الأيمن من الصورة سيُغطّى جزئيًا بتدرّج داكن كي يبقى النص
///   (اسم الصلاة والعدّاد) مقروءًا، فتجنّب وضع تفاصيل مهمة هناك.
/// - الصيغة: JPG بجودة عالية (أو WEBP لحجم أصغر). لا حاجة لخلفية شفافة.
/// - أضِف السطر التالي فـ `pubspec.yaml` تحت `flutter: assets:` إن لم
///   يكن موجودًا: `- assets/images/`
class PrayerArchHero extends StatefulWidget {
  final Prayer next;
  final DateTime? nextRealTime;
  final String timeLabel;
  final PrayerDayPeriod  period;

  const PrayerArchHero({
    super.key,
    required this.next,
    required this.nextRealTime,
    required this.timeLabel,
    required this.period,
  });

  @override
  State<PrayerArchHero> createState() => _PrayerArchHeroState();
}

class _PrayerArchHeroState extends State<PrayerArchHero> {
  Timer? _ticker;
  Duration? _remaining;

  @override
  void initState() {
    super.initState();
    _tick();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didUpdateWidget(covariant PrayerArchHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    _tick();
  }

  void _tick() {
    final real = widget.nextRealTime;
    if (real == null) {
      if (mounted) setState(() => _remaining = null);
      return;
    }
    final diff = real.difference(DateTime.now());
    if (mounted) setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  String? get _countdownText {
    final r = _remaining;
    if (r == null) return null;
    final h = _twoDigits(r.inHours);
    final m = _twoDigits(r.inMinutes % 60);
    final s = _twoDigits(r.inSeconds % 60);
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = width * 0.62;
        return Container(
          width: width,
          height: height,
          clipBehavior: Clip.none,
          child: Stack(
            children: [
              // الرسمة/الصورة داخل شكل القوس.
              ClipPath(
                clipper: _ArchClipper(),
                child: Image.asset(
                  'assets/images/arch_hero.jpg',
                  width: width,
                  height: height,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => CustomPaint(
                    size: Size(width, height),
                    painter: _ArchScenePainter(period: widget.period),
                  ),
                ),
              ),
              // تدرّج داكن يمينًا فقط، كي يبقى النص مقروءًا فوق الصورة.
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        stops: const [0.0, 0.46, 0.62, 1.0],
                       colors: [
  Colors.transparent,
  Colors.transparent,
  AppColors.ink.withValues(alpha: 0.55),
  AppColors.ink.withValues(alpha: 0.92),
],
                      ),
                    ),
                  ),
                ),
              ),
              // حدّ القوس الذهبي.
              Positioned.fill(
                child: CustomPaint(painter: _ArchBorderPainter()),
              ),
              // نص "الصلاة القادمة" + الاسم + العدّاد، فـ الجهة اليمنى.
              Positioned(
                top: height * 0.10,
                bottom: 0,
                right: width * 0.03,
                left: width * 0.46,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'الصلاة القادمة',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.next.arabicName,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.amiri(fontSize: 34, fontWeight: FontWeight.w700, color: AppColors.gold),
                    ),
                    const SizedBox(height: 10),
                    if (_countdownText != null) ...[
                      const Text(
                        'بعد',
                        style: TextStyle(fontSize: 12.5, color: Colors.white70, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _countdownText!,
                        style: GoogleFonts.tajawal(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'إن شاء الله',
                        style: TextStyle(fontSize: 11.5, color: Colors.white60, fontWeight: FontWeight.w500),
                      ),
                    ] else
                      Text(
                        widget.timeLabel,
                        style: GoogleFonts.tajawal(fontSize: 25, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// شكل قوس حدوة الحصان المدبَّب (مغربي/أندلسي) بدرجة صغيرة عند القاعدة
/// اليسرى، مبنيّ كنسب مئوية من عرض/ارتفاع الصندوق كي يبقى متجاوبًا مع
/// أي مقاس شاشة.
class _ArchClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return _archPath(size);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

Path _archPath(Size size) {
  final w = size.width;
  final h = size.height;
  final path = Path();

  // نقطة القمة فـ منتصف القوس تقريبًا.
  final apex = Offset(w * 0.50, 0);
  // نقطة "عنق" القوس حيث ينتهي الانحناء ويبدأ الخط شبه العمودي.
  final leftNeck = Offset(w * 0.055, h * 0.58);
  final rightNeck = Offset(w * 0.945, h * 0.58);
  // أقصى انتفاخ لقوس حدوة الحصان (يتجاوز عرض العنق قليلًا).
  final leftBulge = Offset(w * 0.015, h * 0.42);
  final rightBulge = Offset(w * 0.985, h * 0.42);
  // درجة صغيرة زخرفية عند القاعدة اليسرى (كما فـ صور المحاريب المغربية).
  final stepOuterX = w * 0.02;
  final stepInnerX = w * 0.075;
  final stepY1 = h * 0.62;
  final stepY2 = h * 0.68;

  path.moveTo(apex.dx, apex.dy);
  // من القمة إلى الانتفاخ الأيمن ثم إلى العنق الأيمن.
  path.quadraticBezierTo(w * 0.92, h * 0.02, rightBulge.dx, rightBulge.dy);
  path.quadraticBezierTo(w * 1.00, h * 0.52, rightNeck.dx, rightNeck.dy);
  path.lineTo(w * 0.945, h);
  path.lineTo(w * 0.02, h);
  // القاعدة اليسرى مع الدرجة الزخرفية.
  path.lineTo(stepInnerX, h);
  path.lineTo(stepInnerX, stepY2);
  path.lineTo(stepOuterX, stepY2);
  path.lineTo(stepOuterX, stepY1);
  path.lineTo(leftNeck.dx, leftNeck.dy);
  // من العنق الأيسر إلى الانتفاخ الأيسر ثم إلى القمة.
  path.quadraticBezierTo(w * 0.00, h * 0.52, leftBulge.dx, leftBulge.dy);
  path.quadraticBezierTo(w * 0.08, h * 0.02, apex.dx, apex.dy);
  path.close();
  return path;
}

class _ArchBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = _archPath(size);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = AppColors.gold
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ArchBorderPainter oldDelegate) => false;
}

/// رسمة بديلة (fallback) لمشهد مسجد عند الغروب/فترات اليوم المختلفة،
/// تُستعمل تلقائيًا حين لا يوجد ملف assets/images/arch_hero.jpg.
class _ArchScenePainter extends CustomPainter {
  final PrayerDayPeriod  period;
  _ArchScenePainter({required this.period});

  @override
  void paint(Canvas canvas, Size size) {
    final path = _archPath(size);
    canvas.save();
    canvas.clipPath(path);

    final w = size.width;
    final h = size.height;
    final rect = Rect.fromLTWH(0, 0, w, h);

    final skyColors = _skyColorsFor(period);
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: skyColors,
      ).createShader(rect);
    canvas.drawRect(rect, skyPaint);

    // الشمس/القمر
    final bodyCenter = Offset(w * 0.28, h * 0.32);
    final isNight = period == PrayerDayPeriod.night;
    if (isNight) {
      final moonR = w * 0.05;
      canvas.saveLayer(rect, Paint());
      canvas.drawCircle(bodyCenter, moonR, Paint()..color = const Color(0xFFEFE6C8));
      canvas.drawCircle(
        Offset(bodyCenter.dx + moonR * 0.5, bodyCenter.dy - moonR * 0.3),
        moonR * 0.85,
        Paint()..blendMode = BlendMode.clear,
      );
      canvas.restore();
      final starPaint = Paint()..color = Colors.white.withOpacity(0.8);
      for (final o in [
        Offset(w * 0.5, h * 0.12),
        Offset(w * 0.62, h * 0.22),
        Offset(w * 0.42, h * 0.20),
        Offset(w * 0.58, h * 0.08),
      ]) {
        canvas.drawCircle(o, 1.6, starPaint);
      }
    } else {
      final glow = Paint()
        ..color = const Color(0xFFFFE9B0).withOpacity(0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
      canvas.drawCircle(bodyCenter, w * 0.10, glow);
      canvas.drawCircle(bodyCenter, w * 0.055, Paint()..color = const Color(0xFFFFF3D2));
    }

    // انعكاس الشمس/القمر على الماء
    final reflectionPaint = Paint()
      ..color = (isNight ? const Color(0xFFEFE6C8) : const Color(0xFFFFE9B0)).withOpacity(0.35);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(bodyCenter.dx, h * 0.86), width: w * 0.10, height: h * 0.10),
      reflectionPaint,
    );

    // خط الماء/الأفق السفلي
    final waterPaint = Paint()..color = Colors.black.withOpacity(0.30);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.80, w, h * 0.20), waterPaint);

    // ظلال المسجد (قبة كبيرة + قبتان صغيرتان + مآذن)
    final silhouette = Paint()..color = Colors.black.withOpacity(0.55);
    final baseY = h * 0.80;

    void minaret(double cx, double topY, double width) {
      final rectPath = Path()
        ..moveTo(cx - width / 2, baseY)
        ..lineTo(cx - width / 2, topY + width * 1.4)
        ..lineTo(cx, topY)
        ..lineTo(cx + width / 2, topY + width * 1.4)
        ..lineTo(cx + width / 2, baseY)
        ..close();
      canvas.drawPath(rectPath, silhouette);
      canvas.drawCircle(Offset(cx, topY - width * 0.5), width * 0.28, silhouette);
    }

    void dome(double cx, double domeTop, double domeR) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, domeTop + domeR), radius: domeR),
        math.pi,
        math.pi,
        true,
        silhouette,
      );
      canvas.drawRect(
        Rect.fromLTWH(cx - domeR * 0.9, domeTop + domeR, domeR * 1.8, baseY - (domeTop + domeR)),
        silhouette,
      );
    }

    // مآذن جانبية بعيدة
    minaret(w * 0.30, h * 0.42, w * 0.03);
    minaret(w * 0.86, h * 0.40, w * 0.032);
    // قباب صغيرة
    dome(w * 0.72, h * 0.58, w * 0.06);
    dome(w * 0.94, h * 0.62, w * 0.045);
    // القبة الرئيسية الكبيرة + مئذنتاها
    minaret(w * 0.50, h * 0.30, w * 0.035);
    minaret(w * 0.66, h * 0.34, w * 0.03);
    dome(w * 0.585, h * 0.44, w * 0.11);

    canvas.restore();
  }

List<Color> _skyColorsFor(PrayerDayPeriod period) {
  switch (period) {
    case PrayerDayPeriod.dawn:
      return const [
        Color(0xFF35304A),
        Color(0xFF8A5A5A),
        Color(0xFFD9A15C),
      ];

    case PrayerDayPeriod.day:
      return const [
        Color(0xFF4A87B0),
        Color(0xFF9CC3D9),
        Color(0xFFE8DDB8),
      ];

    case PrayerDayPeriod.sunset:
      return const [
        Color(0xFF3B3350),
        Color(0xFFB06A45),
        Color(0xFFF0C36B),
      ];

    case PrayerDayPeriod.night:
      return const [
        Color(0xFF0B1330),
        Color(0xFF16264A),
        Color(0xFF203A52),
      ];
  }
}

  @override
  bool shouldRepaint(covariant _ArchScenePainter oldDelegate) => oldDelegate.period != period;
}
