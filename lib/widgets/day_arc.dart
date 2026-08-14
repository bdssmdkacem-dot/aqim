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

  const DayArc({super.key, required this.prayers, required this.status, this.timeLabelFor, this.period = PrayerDayPeriod.day});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 154,
        child: CustomPaint(
          painter: _DayArcPainter(prayers: prayers, status: status, timeLabelFor: timeLabelFor, period: period),
        ),
      );
}

class _DayArcPainter extends CustomPainter {
  final List<Prayer> prayers;
  final Map<Prayer, PrayerStatus> status;
  final String Function(Prayer)? timeLabelFor;
  final PrayerDayPeriod period;

  _DayArcPainter({required this.prayers, required this.status, required this.period, this.timeLabelFor});

  Color _color(PrayerStatus s) => switch (s) {
        PrayerStatus.done => AppColors.sage,
        PrayerStatus.upcoming => AppColors.gold,
        PrayerStatus.missed => AppColors.ember,
        PrayerStatus.pending => Colors.white.withValues(alpha: .55),
      };

  @override
  void paint(Canvas canvas, Size size) {
    if (prayers.isEmpty) return;

    const margin = 30.0;
    const baseY = 78.0;
    final usable = size.width - margin * 2;
    final points = <Offset>[];

    for (var i = 0; i < prayers.length; i++) {
      final t = prayers.length == 1 ? .5 : i / (prayers.length - 1);
      points.add(Offset(margin + usable * t, baseY - math.sin(t * math.pi) * 24));
    }

    final arc = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      arc.quadraticBezierTo((a.dx + b.dx) / 2, math.min(a.dy, b.dy) - 2, b.dx, b.dy);
    }

    canvas.drawPath(
      arc,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..color = AppColors.gold.withValues(alpha: .52),
    );

    for (var i = 0; i < prayers.length; i++) {
      final prayer = prayers[i];
      final s = status[prayer] ?? PrayerStatus.pending;
      final center = points[i];
      final upcoming = s == PrayerStatus.upcoming;
      final missed = s == PrayerStatus.missed;
      final radius = upcoming ? 28.0 : 12.0;

      if (upcoming) {
        canvas.drawCircle(center, radius + 9, Paint()..color = AppColors.gold.withValues(alpha: .18));
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
        _sunMoon(canvas, center, radius * .5);
      } else if (s == PrayerStatus.done) {
        _mark(canvas, center, '✓', 13);
      } else if (missed) {
        _mark(canvas, center, '×', 19);
      }

      final labelColor = upcoming ? AppColors.gold : missed ? AppColors.ember : Colors.white;
      _label(
        canvas,
        prayer.arabicName,
        center.dx,
        center.dy + radius + 9,
        labelColor,
        upcoming ? 17 : 12.5,
        bold: upcoming || missed,
      );

      final time = timeLabelFor?.call(prayer) ?? prayer.mockTime;
      _label(
        canvas,
        time,
        center.dx,
        center.dy + radius + (upcoming ? 35 : 27),
        (missed ? AppColors.ember : Colors.white).withValues(alpha: .88),
        upcoming ? 12 : 11,
        bold: missed,
      );
    }
  }

  void _callout(Canvas canvas, Offset center, double radius) {
    final tp = TextPainter(
      text: const TextSpan(
        text: 'الصلاة القادمة',
        style: TextStyle(fontSize: 12, color: AppColors.goldSoft, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.rtl,
    )..layout();

    // Keep the label visually attached to the upcoming circle.
    const h = 27.0;
    const gap = 1.0;
    final rect = Rect.fromCenter(
      center: Offset(center.dx, center.dy - radius - gap - h / 2),
      width: tp.width + 22,
      height: h,
    );
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(14));
    final fill = Paint()..color = AppColors.surfaceDark;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = AppColors.gold.withValues(alpha: .8);

    canvas.drawRRect(rr, fill);
    canvas.drawRRect(rr, stroke);

    final arrow = Path()
      ..moveTo(center.dx - 6, rect.bottom)
      ..lineTo(center.dx + 6, rect.bottom)
      ..lineTo(center.dx, rect.bottom + 6)
      ..close();
    canvas.drawPath(arrow, fill);
    canvas.drawPath(arrow, stroke);
    tp.paint(canvas, Offset(rect.center.dx - tp.width / 2, rect.center.dy - tp.height / 2));
  }

  void _mark(Canvas canvas, Offset center, String value, double size) {
    final tp = TextPainter(
      text: TextSpan(text: value, style: TextStyle(fontSize: size, color: Colors.white, fontWeight: FontWeight.bold)),
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

  void _label(Canvas canvas, String text, double x, double y, Color color, double size, {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.tajawal(
          fontSize: size,
          color: color,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          shadows: const [Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1))],
        ),
      ),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
    )..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, y));
  }

  @override
  bool shouldRepaint(covariant _DayArcPainter oldDelegate) =>
      oldDelegate.status != status || oldDelegate.prayers != prayers || oldDelegate.period != period;
}
