import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Prayer periods used by Aqim.
/// (Renamed to avoid conflict with Flutter's Material DayPeriod)
enum PrayerDayPeriod {
  dawn,
  morning,
  afternoon,
  sunset,
  night,
}

/// Background tint depending on prayer period.
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

    case PrayerDayPeriod.morning:
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF64B5F6).withOpacity(0.18),
          const Color(0xFF81C784).withOpacity(0.22),
          Colors.black.withOpacity(0.70),
        ],
      );

    case PrayerDayPeriod.afternoon:
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF1B3A52).withOpacity(0.22),
          const Color(0xFF0F3D2E).withOpacity(0.30),
          Colors.black.withOpacity(0.76),
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

class PrayerWindowIcon extends StatelessWidget {
  final PrayerDayPeriod period;
  final double size;

  const PrayerWindowIcon({
    super.key,
    required this.period,
    this.size = 84,
  });

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

  _WindowPainter({
    required this.period,
  });

  bool get _isNight =>
      period == PrayerDayPeriod.night ||
      period == PrayerDayPeriod.dawn;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final gold = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final goldFill = Paint()
      ..color = AppColors.gold;

    final archPath = Path();
    final archTop = h * .10;
    final side = w * .08;

    archPath.moveTo(side, h * .92);
    archPath.lineTo(side, h * .42);

    archPath.arcToPoint(
      Offset(w - side, h * .42),
      radius: Radius.circular(w * .42),
      clockwise: true,
    );

    archPath.lineTo(w - side, h * .92);

    canvas.drawPath(archPath, gold);

    canvas.drawLine(
      Offset(side, h * .92),
      Offset(w - side, h * .92),
      gold,
    );

    if (_isNight) {
      final moonCenter = Offset(
        w * .42,
        archTop + h * .10,
      );

      final moonRadius = w * .09;

      canvas.saveLayer(
        Rect.fromCircle(
          center: moonCenter,
          radius: moonRadius + 2,
        ),
        Paint(),
      );

      canvas.drawCircle(
        moonCenter,
        moonRadius,
        goldFill,
      );

      canvas.drawCircle(
        Offset(
          moonCenter.dx + moonRadius * .55,
          moonCenter.dy - moonRadius * .25,
        ),
        moonRadius * .85,
        Paint()..blendMode = BlendMode.clear,
      );

      canvas.restore();

      final starPaint = Paint()
        ..color = AppColors.goldSoft;

      canvas.drawCircle(
        Offset(w * .66, archTop + h * .04),
        1.4,
        starPaint,
      );

      canvas.drawCircle(
        Offset(w * .74, archTop + h * .14),
        1,
        starPaint,
      );

      canvas.drawCircle(
        Offset(w * .60, archTop + h * .18),
        1,
        starPaint,
      );
    } else {
      final sunCenter = Offset(
        w * .50,
        archTop + h * .08,
      );

      canvas.drawCircle(
        sunCenter,
        w * .075,
        goldFill,
      );

      final rayPaint = Paint()
        ..color = AppColors.gold
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < 8; i++) {
        final angle = (i / 8) * 2 * math.pi;

        final inner = Offset(
          sunCenter.dx + (w * .11) * math.cos(angle),
          sunCenter.dy + (w * .11) * math.sin(angle),
        );

        final outer = Offset(
          sunCenter.dx + (w * .16) * math.cos(angle),
          sunCenter.dy + (w * .16) * math.sin(angle),
        );

        canvas.drawLine(
          inner,
          outer,
          rayPaint,
        );
      }
    }

    final baseY = h * .86;

    final domeCenter = Offset(
      w * .46,
      baseY - h * .22,
    );

    final domeRadius = w * .14;

    canvas.drawArc(
      Rect.fromCircle(
        center: domeCenter,
        radius: domeRadius,
      ),
      math.pi,
      math.pi,
      false,
      gold,
    );

    canvas.drawLine(
      Offset(domeCenter.dx - domeRadius, domeCenter.dy),
      Offset(domeCenter.dx - domeRadius, baseY),
      gold,
    );

    canvas.drawLine(
      Offset(domeCenter.dx + domeRadius, domeCenter.dy),
      Offset(domeCenter.dx + domeRadius, baseY),
      gold,
    );

    canvas.drawLine(
      Offset(domeCenter.dx - domeRadius, baseY),
      Offset(domeCenter.dx + domeRadius, baseY),
      gold,
    );

    final minaretX = w * .72;

    canvas.drawLine(
      Offset(minaretX, baseY),
      Offset(minaretX, baseY - h * .32),
      gold,
    );

    canvas.drawLine(
      Offset(minaretX - w * .03, baseY - h * .32),
      Offset(minaretX + w * .03, baseY - h * .32),
      gold,
    );

    canvas.drawCircle(
      Offset(minaretX, baseY - h * .36),
      2,
      goldFill,
    );
  }

  @override
  bool shouldRepaint(covariant _WindowPainter oldDelegate) {
    return oldDelegate.period != period;
  }
}
PrayerDayPeriod currentDayPeriod() {
  final hour = DateTime.now().hour;

  if (hour >= 4 && hour < 7) {
    return PrayerDayPeriod.dawn;
  }

  if (hour >= 7 && hour < 12) {
    return PrayerDayPeriod.morning;
  }

  if (hour >= 12 && hour < 17) {
    return PrayerDayPeriod.afternoon;
  }

  if (hour >= 17 && hour < 20) {
    return PrayerDayPeriod.sunset;
  }

  return PrayerDayPeriod.night;
}
