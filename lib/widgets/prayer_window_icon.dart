import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Represents the time period used by the Aqim prayer window UI.
///
/// We intentionally use a project-specific name instead of `DayPeriod`
/// because Flutter Material also exposes a `DayPeriod` type.
enum PrayerDayPeriod {
  dawn,
  day,
  sunset,
  night,
}

/// Determines the current day period from the device clock.
///
/// Dawn:    05:00 - 06:59
/// Day:     07:00 - 16:59
/// Sunset:  17:00 - 18:59
/// Night:   19:00 - 04:59
PrayerDayPeriod currentDayPeriod([DateTime? now]) {
  final hour = (now ?? DateTime.now()).hour;

  if (hour >= 5 && hour < 7) {
    return PrayerDayPeriod.dawn;
  }

  if (hour >= 7 && hour < 17) {
    return PrayerDayPeriod.day;
  }

  if (hour >= 17 && hour < 19) {
    return PrayerDayPeriod.sunset;
  }

  return PrayerDayPeriod.night;
}

/// Transparent gradient placed over the mosque image to give the UI
/// an atmosphere matching the current time period.
LinearGradient tintForPeriod(PrayerDayPeriod period) {
  switch (period) {
    case PrayerDayPeriod.dawn:
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF3A2A4A).withValues(alpha: 0.35),
          const Color(0xFFB56B4A).withValues(alpha: 0.25),
          Colors.black.withValues(alpha: 0.80),
        ],
      );

    case PrayerDayPeriod.day:
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF1B3A52).withValues(alpha: 0.20),
          const Color(0xFF0F3D2E).withValues(alpha: 0.30),
          Colors.black.withValues(alpha: 0.78),
        ],
      );

    case PrayerDayPeriod.sunset:
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF7A3A2A).withValues(alpha: 0.30),
          const Color(0xFFB5654A).withValues(alpha: 0.25),
          Colors.black.withValues(alpha: 0.82),
        ],
      );

    case PrayerDayPeriod.night:
      return LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF0C1B33).withValues(alpha: 0.55),
          const Color(0xFF0C2E24).withValues(alpha: 0.45),
          Colors.black.withValues(alpha: 0.85),
        ],
      );
  }
}

/// Small prayer-window icon inside a curved mihrab frame.
///
/// The icon is drawn entirely with Flutter CustomPainter:
/// - Night / dawn: crescent + stars
/// - Day / sunset: sun
/// - Mosque: dome + minaret
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
      ..color = AppColors.gold
      ..style = PaintingStyle.fill;

    // ------------------------------------------------------------
    // Mihrab frame
    // ------------------------------------------------------------

    final archPath = Path();

    final archTop = h * 0.10;
    final sideMargin = w * 0.08;

    archPath.moveTo(
      sideMargin,
      h * 0.92,
    );

    archPath.lineTo(
      sideMargin,
      h * 0.42,
    );

    archPath.arcToPoint(
      Offset(
        w - sideMargin,
        h * 0.42,
      ),
      radius: Radius.circular(w * 0.42),
      clockwise: true,
    );

    archPath.lineTo(
      w - sideMargin,
      h * 0.92,
    );

    canvas.drawPath(
      archPath,
      gold,
    );

    canvas.drawLine(
      Offset(
        sideMargin,
        h * 0.92,
      ),
      Offset(
        w - sideMargin,
        h * 0.92,
      ),
      gold,
    );

    // ------------------------------------------------------------
    // Sky symbol
    // ------------------------------------------------------------

    if (_isNight) {
      // Crescent moon.
      final moonCenter = Offset(
        w * 0.42,
        archTop + h * 0.10,
      );

      final moonR = w * 0.09;

      canvas.saveLayer(
        Rect.fromCircle(
          center: moonCenter,
          radius: moonR + 2,
        ),
        Paint(),
      );

      canvas.drawCircle(
        moonCenter,
        moonR,
        goldFill,
      );

      final clearPaint = Paint()
        ..blendMode = BlendMode.clear;

      canvas.drawCircle(
        Offset(
          moonCenter.dx + moonR * 0.55,
          moonCenter.dy - moonR * 0.25,
        ),
        moonR * 0.85,
        clearPaint,
      );

      canvas.restore();

      // Stars.
      final starPaint = Paint()
        ..color = AppColors.goldSoft
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(
          w * 0.66,
          archTop + h * 0.04,
        ),
        1.4,
        starPaint,
      );

      canvas.drawCircle(
        Offset(
          w * 0.74,
          archTop + h * 0.14,
        ),
        1.0,
        starPaint,
      );

      canvas.drawCircle(
        Offset(
          w * 0.60,
          archTop + h * 0.18,
        ),
        1.0,
        starPaint,
      );
    } else {
      // Sun.
      final sunCenter = Offset(
        w * 0.5,
        archTop + h * 0.08,
      );

      canvas.drawCircle(
        sunCenter,
        w * 0.075,
        goldFill,
      );

      final rayPaint = Paint()
        ..color = AppColors.gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;

      for (var i = 0; i < 8; i++) {
        final angle = (i / 8) * 2 * math.pi;

        final inner = Offset(
          sunCenter.dx +
              (w * 0.11) * math.cos(angle),
          sunCenter.dy +
              (w * 0.11) * math.sin(angle),
        );

        final outer = Offset(
          sunCenter.dx +
              (w * 0.16) * math.cos(angle),
          sunCenter.dy +
              (w * 0.16) * math.sin(angle),
        );

        canvas.drawLine(
          inner,
          outer,
          rayPaint,
        );
      }
    }

    // ------------------------------------------------------------
    // Mosque dome
    // ------------------------------------------------------------

    final baseY = h * 0.86;

    final domeCenter = Offset(
      w * 0.46,
      baseY - h * 0.22,
    );

    final domeR = w * 0.14;

    canvas.drawArc(
      Rect.fromCircle(
        center: domeCenter,
        radius: domeR,
      ),
      math.pi,
      math.pi,
      false,
      gold,
    );

    canvas.drawLine(
      Offset(
        domeCenter.dx - domeR,
        domeCenter.dy,
      ),
      Offset(
        domeCenter.dx - domeR,
        baseY,
      ),
      gold,
    );

    canvas.drawLine(
      Offset(
        domeCenter.dx + domeR,
        domeCenter.dy,
      ),
      Offset(
        domeCenter.dx + domeR,
        baseY,
      ),
      gold,
    );

    canvas.drawLine(
      Offset(
        domeCenter.dx - domeR,
        baseY,
      ),
      Offset(
        domeCenter.dx + domeR,
        baseY,
      ),
      gold,
    );

    // ------------------------------------------------------------
    // Minaret
    // ------------------------------------------------------------

    final minaretX = w * 0.72;

    canvas.drawLine(
      Offset(
        minaretX,
        baseY,
      ),
      Offset(
        minaretX,
        baseY - h * 0.32,
      ),
      gold,
    );

    canvas.drawLine(
      Offset(
        minaretX - w * 0.03,
        baseY - h * 0.32,
      ),
      Offset(
        minaretX + w * 0.03,
        baseY - h * 0.32,
      ),
      gold,
    );

    canvas.drawCircle(
      Offset(
        minaretX,
        baseY - h * 0.36,
      ),
      2,
      goldFill,
    );
  }

  @override
  bool shouldRepaint(
    covariant _WindowPainter oldDelegate,
  ) {
    return oldDelegate.period != period;
  }
}
