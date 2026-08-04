import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum PrayerDayPeriod { dawn, day, sunset, night }

/// يحدّد فترة اليوم الحالية من ساعة الجهاز، لتلوين الخلفية والأيقونة
/// المصغّرة بما يناسب (فجر/نهار/غروب/ليل) — بلا حاجة لصور متعددة.
PrayerDayPeriod currentPrayerDayPeriod([DateTime? now]) {
  final hour = (now ?? DateTime.now()).hour;
  if (hour >= 5 && hour < 7) return PrayerDayPeriod.dawn;
  if (hour >= 7 && hour < 17) return PrayerDayPeriod.day;
  if (hour >= 17 && hour < 19) return PrayerDayPeriod.sunset;
  return PrayerDayPeriod.night;
}

/// تدرّج شفاف يُوضَع فوق صورة المسجد ليعطي إحساس الفترة الزمنية
/// الحالية (فجر/نهار/غروب/ليل) بلا الحاجة لعدّة صور خلفية.
LinearGradient tintForPeriod(PrayerDayPeriod period) {
  switch (period) {
    case PrayerDayPeriod.dawn:
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF3A2A4A).withOpacity(0.35),
          const Color(0xFFB56B4A).withOpacity(0.25),
          Colors.black.withOpacity(0.80),
        ],
      );
    case PrayerDayPeriod.day:
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF1B3A52).withOpacity(0.20),
          const Color(0xFF0F3D2E).withOpacity(0.30),
          Colors.black.withOpacity(0.78),
        ],
      );
    case PrayerDayPeriod.sunset:
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF7A3A2A).withOpacity(0.30),
          const Color(0xFFB5654A).withOpacity(0.25),
          Colors.black.withOpacity(0.82),
        ],
      );
    case PrayerDayPeriod.night:
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF0C1B33).withOpacity(0.55),
          const Color(0xFF0C2E24).withOpacity(0.45),
          Colors.black.withOpacity(0.85),
        ],
      );
  }
}

/// أيقونة مصغّرة داخل إطار مقوّس (محراب) — مسجد + هلال/نجوم ليلًا، أو
/// مسجد + شمس نهارًا، مرسومة بالكامل بالكود (بلا صورة خارجية).
class PrayerWindowIcon extends StatelessWidget {
  final PrayerDayPeriod period;
  final double size;

  const PrayerWindowIcon({super.key, required this.period, this.size = 84});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _WindowPainter(period: period),
    );
  }
}

class _WindowPainter extends CustomPainter {
  final PrayerDayPeriod period;
  _WindowPainter({required this.period});

  bool get _isNight => period == PrayerDayPeriod.night || period == PrayerDayPeriod.dawn;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final gold = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final goldFill = Paint()..color = AppColors.gold;

    // إطار المحراب (قوس فوق مستطيل)
    final archPath = Path();
    final archTop = h * 0.10;
    final sideMargin = w * 0.08;
    archPath.moveTo(sideMargin, h * 0.92);
    archPath.lineTo(sideMargin, h * 0.42);
    archPath.arcToPoint(
      Offset(w - sideMargin, h * 0.42),
      radius: Radius.circular(w * 0.42),
      clockwise: true,
    );
    archPath.lineTo(w - sideMargin, h * 0.92);
    canvas.drawPath(archPath, gold);
    canvas.drawLine(Offset(sideMargin, h * 0.92), Offset(w - sideMargin, h * 0.92), gold);

    // هلال ونجوم ليلًا/فجرًا، أو شمس مشعّة نهارًا/عند الغروب
    if (_isNight) {
      final moonCenter = Offset(w * 0.42, archTop + h * 0.10);
      final moonR = w * 0.09;
      canvas.saveLayer(Rect.fromCircle(center: moonCenter, radius: moonR + 2), Paint());
      canvas.drawCircle(moonCenter, moonR, goldFill);
      canvas.drawCircle(
        Offset(moonCenter.dx + moonR * 0.55, moonCenter.dy - moonR * 0.25),
        moonR * 0.85,
        Paint()..blendMode = BlendMode.clear,
      );
      canvas.restore();

      final starPaint = Paint()..color = AppColors.goldSoft;
      canvas.drawCircle(Offset(w * 0.66, archTop + h * 0.04), 1.4, starPaint);
      canvas.drawCircle(Offset(w * 0.74, archTop + h * 0.14), 1.0, starPaint);
      canvas.drawCircle(Offset(w * 0.60, archTop + h * 0.18), 1.0, starPaint);
    } else {
      final sunCenter = Offset(w * 0.5, archTop + h * 0.08);
      canvas.drawCircle(sunCenter, w * 0.075, goldFill);
      final rayPaint = Paint()
        ..color = AppColors.gold
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 8; i++) {
        final angle = (i / 8) * 2 * math.pi;
        final inner = Offset(
          sunCenter.dx + (w * 0.11) * math.cos(angle),
          sunCenter.dy + (w * 0.11) * math.sin(angle),
        );
        final outer = Offset(
          sunCenter.dx + (w * 0.16) * math.cos(angle),
          sunCenter.dy + (w * 0.16) * math.sin(angle),
        );
        canvas.drawLine(inner, outer, rayPaint);
      }
    }

    // مسجد بسيط أسفل المحراب: قبة + مئذنة
    final baseY = h * 0.86;
    final domeCenter = Offset(w * 0.46, baseY - h * 0.22);
    final domeR = w * 0.14;
    canvas.drawArc(
      Rect.fromCircle(center: domeCenter, radius: domeR),
      math.pi,
      math.pi,
      false,
      gold,
    );
    canvas.drawLine(Offset(domeCenter.dx - domeR, domeCenter.dy), Offset(domeCenter.dx - domeR, baseY), gold);
    canvas.drawLine(Offset(domeCenter.dx + domeR, domeCenter.dy), Offset(domeCenter.dx + domeR, baseY), gold);
    canvas.drawLine(Offset(domeCenter.dx - domeR, baseY), Offset(domeCenter.dx + domeR, baseY), gold);

    // مئذنة
    final minaretX = w * 0.72;
    canvas.drawLine(Offset(minaretX, baseY), Offset(minaretX, baseY - h * 0.32), gold);
    canvas.drawLine(
      Offset(minaretX - w * 0.03, baseY - h * 0.32),
      Offset(minaretX + w * 0.03, baseY - h * 0.32),
      gold,
    );
    canvas.drawCircle(Offset(minaretX, baseY - h * 0.36), 2, goldFill);
  }

  @override
  bool shouldRepaint(covariant _WindowPainter oldDelegate) => oldDelegate.period != period;
}
