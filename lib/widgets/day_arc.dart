import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/prayer.dart';
import '../theme/app_theme.dart';
import 'prayer_window_icon.dart' show PrayerDayPeriod;

class DayArc extends StatelessWidget {
  final List<Prayer> prayers;
  final Map<Prayer, PrayerStatus> status;
  final String Function(Prayer)? timeLabelFor;
  final PrayerDayPeriod period;

  const DayArc({
    super.key,
    required this.prayers,
    required this.status,
    this.timeLabelFor,
    this.period = PrayerDayPeriod.day,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 182,
        width: double.infinity,
        child: CustomPaint(
          painter: _DayArcPainter(
            prayers: prayers,
            status: status,
            timeLabelFor: timeLabelFor,
            period: period,
          ),
        ),
      );
}

class _DayArcPainter extends CustomPainter {
  final List<Prayer> prayers;
  final Map<Prayer, PrayerStatus> status;
  final String Function(Prayer)? timeLabelFor;
  final PrayerDayPeriod period;

  _DayArcPainter({
    required this.prayers,
    required this.status,
    required this.period,
    this.timeLabelFor,
  });

  Color _color(PrayerStatus s) => switch (s) {
        PrayerStatus.done => AppColors.sage,
        PrayerStatus.upcoming => AppColors.gold,
        PrayerStatus.missed => AppColors.ember,
        PrayerStatus.pending => Colors.white.withValues(alpha: .55),
      };

  @override
  void paint(Canvas canvas, Size size) {
    if (prayers.isEmpty) return;

    // The arc occupies its own visual lane. The lower part is reserved for
    // the prayer name/time so they never collide with the curve or each other.
    const horizontalPadding = 26.0;
    const baseY = 104.0;
    const rise = 30.0;
    final usableWidth = math.max(1.0, size.width - horizontalPadding * 2);

    final points = <Offset>[];
    for (var i = 0; i < prayers.length; i++) {
      final t = prayers.length == 1 ? .5 : i / (prayers.length - 1);
      points.add(
        Offset(
          horizontalPadding + usableWidth * t,
          baseY - math.sin(t * math.pi) * rise,
        ),
      );
    }

    final arc = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      final midX = (a.dx + b.dx) / 2;
      final controlY = math.min(a.dy, b.dy) - 4;
      arc.quadraticBezierTo(midX, controlY, b.dx, b.dy);
    }

    canvas.drawPath(
      arc,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..color = AppColors.gold.withValues(alpha: .55),
    );

    for (var i = 0; i < prayers.length; i++) {
      final prayer = prayers[i];
      final s = status[prayer] ?? PrayerStatus.pending;
      final center = points[i];
      final upcoming = s == PrayerStatus.upcoming;
      final missed = s == PrayerStatus.missed;
      final radius = upcoming ? 30.0 : 13.0;

      if (upcoming) {
        canvas.drawCircle(
          center,
          radius + 11,
          Paint()..color = AppColors.gold.withValues(alpha: .16),
        );
        _callout(canvas, center, radius);
      }

      canvas.drawCircle(center, radius, Paint()..color = _color(s));

      if (upcoming) {
        canvas.drawCircle(
          center,
          radius - 2,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..color = AppColors.goldSoft,
        );
        _sunMoon(canvas, center, radius * .52);
      } else if (s == PrayerStatus.done) {
        _mark(canvas, center, '✓', 14);
      } else if (missed) {
        _mark(canvas, center, '×', 20);
      }

      final labelY = center.dy + radius + 7;
      final timeY = labelY + (upcoming ? 22 : 20);
      final labelColor = upcoming
          ? AppColors.gold
          : missed
              ? AppColors.ember
              : Colors.white;

      _label(
        canvas,
        prayer.arabicName,
        center.dx,
        labelY,
        labelColor,
        upcoming ? 16.5 : 12.5,
        bold: upcoming || missed,
      );

      final time = timeLabelFor?.call(prayer) ?? prayer.mockTime;
      _label(
        canvas,
        time,
        center.dx,
        timeY,
        (missed ? AppColors.ember : Colors.white).withValues(alpha: .90),
        upcoming ? 12.5 : 11,
        bold: missed,
      );
    }
  }

  void _callout(Canvas canvas, Offset center, double radius) {
    final tp = TextPainter(
      text: const TextSpan(
        text: 'الصلاة القادمة',
        style: TextStyle(
          fontSize: 13,
          color: AppColors.goldSoft,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();

    const height = 30.0;
    const gap = 3.0;
    final rect = Rect.fromCenter(
      center: Offset(center.dx, center.dy - radius - gap - height / 2),
      width: tp.width + 24,
      height: height,
    );
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(16));

    canvas.drawRRect(rr, Paint()..color = AppColors.surfaceDark);
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = AppColors.gold.withValues(alpha: .85),
    );

    final arrow = Path()
      ..moveTo(center.dx - 7, rect.bottom)
      ..lineTo(center.dx + 7, rect.bottom)
      ..lineTo(center.dx, rect.bottom + 7)
      ..close();
    canvas.drawPath(arrow, Paint()..color = AppColors.surfaceDark);
    canvas.drawPath(
      arrow,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = AppColors.gold.withValues(alpha: .85),
    );

    tp.paint(
      canvas,
      Offset(rect.center.dx - tp.width / 2, rect.center.dy - tp.height / 2),
    );
  }

  void _mark(Canvas canvas, Offset center, String value, double size) {
    final tp = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontSize: size,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _sunMoon(Canvas canvas, Offset center, double r) {
    final night = period == PrayerDayPeriod.night || period == PrayerDayPeriod.dawn;
    final p = Paint()..color = AppColors.ink;

    if (night) {
      canvas.saveLayer(Rect.fromCircle(center: center, radius: r + 2), Paint());
      canvas.drawCircle(center, r, p);
      canvas.drawCircle(
        Offset(center.dx + r * .5, center.dy - r * .3),
        r * .8,
        Paint()..blendMode = BlendMode.clear,
      );
      canvas.restore();
      return;
    }

    canvas.drawCircle(center, r * .55, p);
    for (var i = 0; i < 8; i++) {
      final a = i / 8 * 2 * math.pi;
      canvas.drawLine(
        Offset(center.dx + r * .68 * math.cos(a), center.dy + r * .68 * math.sin(a)),
        Offset(center.dx + r * .95 * math.cos(a), center.dy + r * .95 * math.sin(a)),
        Paint()
          ..color = AppColors.ink
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _label(
    Canvas canvas,
    String text,
    double x,
    double y,
    Color color,
    double size, {
    bool bold = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.tajawal(
          fontSize: size,
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
    tp.paint(canvas, Offset(x - tp.width / 2, y));
  }

  @override
  bool shouldRepaint(covariant _DayArcPainter oldDelegate) =>
      oldDelegate.status != status ||
      oldDelegate.prayers != prayers ||
      oldDelegate.period != period ||
      oldDelegate.timeLabelFor != timeLabelFor;
}
