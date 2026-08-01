import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Periods used by Aqim.
/// Renamed to avoid conflict with Flutter's Material DayPeriod.
enum PrayerDayPeriod {
  dawn,
  morning,
  afternoon,
  sunset,
  night,
}

/// Returns current prayer day period.
PrayerDayPeriod currentPrayerDayPeriod() {
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

/// Background overlay gradient.
LinearGradient tintForPeriod(PrayerDayPeriod period) {
  switch (period) {
    case PrayerDayPeriod.dawn:
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF3A2A4A).withOpacity(.35),
          const Color(0xFFB56B4A).withOpacity(.25),
          Colors.black.withOpacity(.80),
        ],
      );

    case PrayerDayPeriod.morning:
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF64B5F6).withOpacity(.18),
          const Color(0xFF81C784).withOpacity(.22),
          Colors.black.withOpacity(.70),
        ],
      );

    case PrayerDayPeriod.afternoon:
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF1B3A52).withOpacity(.22),
          const Color(0xFF0F3D2E).withOpacity(.30),
          Colors.black.withOpacity(.76),
        ],
      );

    case PrayerDayPeriod.sunset:
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF7A3A2A).withOpacity(.30),
          const Color(0xFFB5654A).withOpacity(.25),
          Colors.black.withOpacity(.82),
        ],
      );

    case PrayerDayPeriod.night:
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF0C1B33).withOpacity(.55),
          const Color(0xFF0C2E24).withOpacity(.45),
          Colors.black.withOpacity(.85),
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

  const _WindowPainter({
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

    final goldFill = Paint()..color = AppColors.gold;

    final archTop = h * .10;
    final side = w * .08;

    final arch = Path()
      ..moveTo(side, h * .92)
      ..lineTo(side, h * .42)
      ..arcToPoint(
        Offset(w - side, h * .42),
        radius: Radius.circular(w * .42),
      )
      ..lineTo(w - side, h * .92);

    canvas.drawPath(arch, gold);

    canvas.drawLine(
      Offset(side, h * .92),
      Offset(w - side, h * .92),
      gold,
    );

    if (_isNight) {
      final center = Offset(w * .42, archTop + h * .10);
      final radius = w * .09;

      canvas.saveLayer(
        Rect.fromCircle(center: center, radius: radius + 2),
        Paint(),
      );

      canvas.drawCircle(center, radius, goldFill);

      canvas.drawCircle(
        Offset(
          center.dx + radius * .55,
          center.dy - radius * .25,
        ),
        radius * .85,
        Paint()..blendMode = BlendMode.clear,
      );

      canvas.restore();

      final star = Paint()..color = AppColors.goldSoft;

      canvas.drawCircle(Offset(w * .66, archTop + h * .04), 1.4, star);
      canvas.drawCircle(Offset(w * .74, archTop + h * .14), 1.0, star);
      canvas.drawCircle(Offset(w * .60, archTop + h * .18), 1.0, star);
    } else {
      final center = Offset(w * .50, archTop + h * .08);

      canvas.drawCircle(
        center,
        w * .075,
        goldFill,
      );

      final rays = Paint()
        ..color = AppColors.gold
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < 8; i++) {
        final angle = i * math.pi / 4;

        final inner = Offset(
          center.dx + w * .11 * math.cos(angle),
          center.dy + w * .11 * math.sin(angle),
        );

        final outer = Offset(
          center.dx + w * .16 * math.cos(angle),
          center.dy + w * .16 * math.sin(angle),
        );

        canvas.drawLine(inner, outer, rays);
      }
    }

    final baseY = h * .86;
    final domeCenter = Offset(w * .46, baseY - h * .22);
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
