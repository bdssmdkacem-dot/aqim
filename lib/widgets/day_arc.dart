import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/prayer.dart';
import '../theme/app_theme.dart';
<<<<<<< HEAD
import 'prayer_window_icon.dart' show DayPeriod;
=======
import 'prayer_window_icon.dart'
    show PrayerDayPeriod;
>>>>>>> 18ef8b7ca6fda35dd97059675b4b9b1de596e92a

/// "قوس اليوم": يمثل الصلوات الخمس كنقاط على مسار مقوّس يشبه مسار الشمس،
/// كل نقطة تُلوَّن بحسب حالتها (تمت / القادمة / لم يحن وقتها / فائتة لم
/// تُصلَّ بعد). الصلاة القادمة تُبرَز بدائرة ذهبية أكبر مع أيقونة
/// شمس/قمر واسمها بخط أكبر، وفوقها تلميح "الصلاة القادمة". الصلوات
/// الفائتة (التي مرّ وقتها ولم تُسجَّل كمُصلّاة) تظهر بعلامة ✕ ولون
/// نحاسي/أحمر مائل، واسمها بنفس اللون كي تُلفت الانتباه لتداركها.
class DayArc extends StatelessWidget {
  final List<Prayer> prayers;
  final Map<Prayer, PrayerStatus> status;
  final String Function(Prayer)? timeLabelFor;
<<<<<<< HEAD
  final DayPeriod period;
=======
  final PrayerDayPeriod  period;
>>>>>>> 18ef8b7ca6fda35dd97059675b4b9b1de596e92a

  const DayArc({
    super.key,
    required this.prayers,
    required this.status,
    this.timeLabelFor,
<<<<<<< HEAD
    this.period = DayPeriod.day,
=======
    this.period = PrayerDayPeriod.day,
>>>>>>> 18ef8b7ca6fda35dd97059675b4b9b1de596e92a
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: CustomPaint(
        painter: _DayArcPainter(
          prayers: prayers,
          status: status,
          timeLabelFor: timeLabelFor,
          period: period,
        ),
        child: Container(),
      ),
    );
  }
}

class _DayArcPainter extends CustomPainter {
  final List<Prayer> prayers;
  final Map<Prayer, PrayerStatus> status;
  final String Function(Prayer)? timeLabelFor;
<<<<<<< HEAD
  final DayPeriod period;
=======
  final PrayerDayPeriod  period;
>>>>>>> 18ef8b7ca6fda35dd97059675b4b9b1de596e92a

  _DayArcPainter({
    required this.prayers,
    required this.status,
    required this.period,
    this.timeLabelFor,
  });

  Color _colorFor(PrayerStatus s) {
    switch (s) {
      case PrayerStatus.done:
        return AppColors.sage;
      case PrayerStatus.upcoming:
        return AppColors.gold;
      case PrayerStatus.missed:
        return AppColors.ember;
      case PrayerStatus.pending:
<<<<<<< HEAD
        return Colors.white.withOpacity(0.55);
=======
       return Colors.white.withOpacity(0.55);
>>>>>>> 18ef8b7ca6fda35dd97059675b4b9b1de596e92a
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final n = prayers.length;
    if (n == 0) return;
    final margin = 26.0;
    final usableWidth = size.width - margin * 2;
    final trackY = 44.0;
    final points = <Offset>[];
    for (var i = 0; i < n; i++) {
      final t = n == 1 ? 0.5 : i / (n - 1);
      final x = margin + usableWidth * t;
      final y = trackY - math.sin(t * math.pi) * 26;
      points.add(Offset(x, y));
    }

    // خط المسار ذهبي شفاف قليلًا.
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppColors.gold.withOpacity(0.45);
    canvas.drawPath(path, linePaint);

    for (var i = 0; i < n; i++) {
      final p = prayers[i];
      final s = status[p] ?? PrayerStatus.pending;
      final color = _colorFor(s);
      final center = points[i];
      final isUpcoming = s == PrayerStatus.upcoming;
      final radius = isUpcoming ? 20.0 : 12.0;

<<<<<<< HEAD
      if (isUpcoming) {
        // تلميح "الصلاة القادمة" فوق النقطة مباشرة.
        _drawCallout(canvas, center, radius);

        final glow = Paint()
          ..color = AppColors.gold.withOpacity(0.22)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, radius + 10, glow);
      }

=======
     if (isUpcoming) {
  // تلميح "الصلاة القادمة" فوق النقطة مباشرة.
  _drawCallout(canvas, center, radius);

  final glow = Paint()
    ..color = AppColors.gold.withOpacity(0.22)
    ..style = PaintingStyle.fill;

  canvas.drawCircle(center, radius + 10, glow);
}
>>>>>>> 18ef8b7ca6fda35dd97059675b4b9b1de596e92a
      final dot = Paint()..color = color;
      canvas.drawCircle(center, radius, dot);

      if (isUpcoming) {
        final ringPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = AppColors.goldSoft;
        canvas.drawCircle(center, radius - 2, ringPaint);
        _drawSunOrMoon(canvas, center, radius * 0.5);
      } else if (s == PrayerStatus.done) {
        final tp = TextPainter(
          text: const TextSpan(
            text: '✓',
            style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
      } else if (s == PrayerStatus.missed) {
        final tp = TextPainter(
          text: const TextSpan(
            text: '✕',
            style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
      }

      final nameColor = switch (s) {
        PrayerStatus.upcoming => AppColors.gold,
        PrayerStatus.missed => AppColors.ember,
        PrayerStatus.done => Colors.white,
        PrayerStatus.pending => Colors.white,
      };
      _drawLabel(
        canvas,
        p.arabicName,
        center.dx,
        center.dy + radius + 10,
        nameColor,
        isUpcoming ? 15 : 12.5,
        bold: isUpcoming || s == PrayerStatus.missed,
      );
      final timeText = timeLabelFor?.call(p) ?? p.mockTime;
      _drawLabel(
        canvas,
        timeText,
        center.dx,
        center.dy + radius + (isUpcoming ? 30 : 26),
<<<<<<< HEAD
        (s == PrayerStatus.missed ? AppColors.ember : Colors.white).withOpacity(0.85),
=======
        (s == PrayerStatus.missed ? AppColors.ember : Colors.white)
    .withOpacity(0.85),
>>>>>>> 18ef8b7ca6fda35dd97059675b4b9b1de596e92a
        11,
      );
    }
  }

  void _drawSunOrMoon(Canvas canvas, Offset center, double r) {
<<<<<<< HEAD
    final isNight = period == DayPeriod.night || period == DayPeriod.dawn;
=======
    final isNight =
    period == PrayerDayPeriod.night ||
    period == PrayerDayPeriod.dawn;
>>>>>>> 18ef8b7ca6fda35dd97059675b4b9b1de596e92a
    final iconPaint = Paint()..color = AppColors.ink;
    if (isNight) {
      canvas.saveLayer(Rect.fromCircle(center: center, radius: r + 2), Paint());
      canvas.drawCircle(center, r, iconPaint);
      canvas.drawCircle(
        Offset(center.dx + r * 0.5, center.dy - r * 0.3),
        r * 0.8,
        Paint()..blendMode = BlendMode.clear,
      );
      canvas.restore();
    } else {
      canvas.drawCircle(center, r * 0.55, iconPaint);
      final rayPaint = Paint()
        ..color = AppColors.ink
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 8; i++) {
        final angle = (i / 8) * 2 * math.pi;
        final inner = Offset(center.dx + r * 0.68 * math.cos(angle), center.dy + r * 0.68 * math.sin(angle));
        final outer = Offset(center.dx + r * 0.95 * math.cos(angle), center.dy + r * 0.95 * math.sin(angle));
        canvas.drawLine(inner, outer, rayPaint);
      }
    }
  }

  void _drawCallout(Canvas canvas, Offset dotCenter, double dotRadius) {
    const text = 'الصلاة القادمة';
    final tp = TextPainter(
      text: const TextSpan(
        text: text,
        style: TextStyle(fontSize: 11, color: AppColors.goldSoft, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.rtl,
    )..layout();

    final pillW = tp.width + 20;
    const pillH = 24.0;
    final pillCenterY = dotCenter.dy - dotRadius - 22;
    final pillRect = Rect.fromCenter(center: Offset(dotCenter.dx, pillCenterY), width: pillW, height: pillH);
    final rrect = RRect.fromRectAndRadius(pillRect, const Radius.circular(12));

    final fillPaint = Paint()..color = AppColors.surfaceDark;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = AppColors.gold.withOpacity(0.7);
    canvas.drawRRect(rrect, fillPaint);
    canvas.drawRRect(rrect, strokePaint);

    // مثلث صغير يشير إلى النقطة.
    final arrow = Path()
      ..moveTo(dotCenter.dx - 5, pillRect.bottom)
      ..lineTo(dotCenter.dx + 5, pillRect.bottom)
      ..lineTo(dotCenter.dx, pillRect.bottom + 6)
      ..close();
    canvas.drawPath(arrow, fillPaint);
    canvas.drawPath(arrow, strokePaint);

    tp.paint(canvas, Offset(pillRect.center.dx - tp.width / 2, pillRect.center.dy - tp.height / 2));
  }

  void _drawLabel(Canvas canvas, String text, double cx, double y, Color color, double fontSize, {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.tajawal(
          fontSize: fontSize,
          color: color,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          shadows: const [
            Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
          ],
        ),
      ),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, y));
  }

  @override
  bool shouldRepaint(covariant _DayArcPainter oldDelegate) {
    return oldDelegate.status != status || oldDelegate.prayers != prayers || oldDelegate.period != period;
  }
}
