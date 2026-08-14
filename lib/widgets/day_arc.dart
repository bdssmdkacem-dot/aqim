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
        height: 190,
        width: double.infinity,
        child: CustomPaint(painter: _DayArcPainter(prayers: prayers, status: status, timeLabelFor: timeLabelFor, period: period)),
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
    final horizontalPadding = math.max(27.0, size.width * .055);
    final baseY = size.height * .64;
    final rise = math.min(31.0, size.height * .18);
    final usableWidth = math.max(1.0, size.width - horizontalPadding * 2);
    final points = <Offset>[];
    for (var i = 0; i < prayers.length; i++) {
      final t = prayers.length == 1 ? .5 : i / (prayers.length - 1);
      points.add(Offset(horizontalPadding + usableWidth * t, baseY - math.sin(t * math.pi) * rise));
    }

    final arc = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      arc.quadraticBezierTo((a.dx + b.dx) / 2, math.min(a.dy, b.dy) - 4, b.dx, b.dy);
    }
    canvas.drawPath(arc, Paint()..style = PaintingStyle.stroke..strokeWidth = 2.3..strokeCap = StrokeCap.round..color = AppColors.gold.withValues(alpha: .65));

    for (var i = 0; i < prayers.length; i++) {
      final prayer = prayers[i];
      final s = status[prayer] ?? PrayerStatus.pending;
      final center = points[i];
      final upcoming = s == PrayerStatus.upcoming;
      final missed = s == PrayerStatus.missed;
      final radius = upcoming ? 31.0 : 14.0;

      if (upcoming) {
        canvas.drawCircle(center, radius + 13, Paint()..color = AppColors.gold.withValues(alpha: .11));
        canvas.drawCircle(center, radius + 7, Paint()..color = AppColors.gold.withValues(alpha: .17));
        _callout(canvas, center, radius);
      }

      canvas.drawCircle(center, radius, Paint()..color = _color(s));
      canvas.drawCircle(center, radius, Paint()..style = PaintingStyle.stroke..strokeWidth = upcoming ? 2.2 : 1.4..color = upcoming ? AppColors.goldSoft : (missed ? AppColors.ember : AppColors.gold.withValues(alpha: .45)));

      if (s == PrayerStatus.done) {
        _checkIcon(canvas, center, radius * .65);
      } else if (missed) {
        _xIcon(canvas, center, radius * .62);
      } else {
        _celestialIcon(canvas, center, radius * (upcoming ? .62 : .48), prayer);
      }

      final labelY = center.dy + radius + 8;
      final timeY = labelY + (upcoming ? 25 : 21);
      final labelColor = upcoming ? AppColors.gold : missed ? AppColors.ember : Colors.white;
      _label(canvas, prayer.arabicName, center.dx, labelY, labelColor, upcoming ? 16.5 : 12.8, bold: upcoming || missed);
      final time = timeLabelFor?.call(prayer) ?? prayer.mockTime;
      _label(canvas, time, center.dx, timeY, missed ? AppColors.ember : Colors.white.withValues(alpha: .92), upcoming ? 13.5 : 11.5, bold: missed || upcoming);
    }
  }

  bool _isNightPrayer(Prayer prayer) => prayer == Prayer.maghrib || prayer == Prayer.isha;

  void _celestialIcon(Canvas canvas, Offset center, double r, Prayer prayer) {
    if (_isNightPrayer(prayer)) {
      canvas.drawCircle(center, r, Paint()..color = AppColors.ink);
      canvas.drawCircle(Offset(center.dx + r * .40, center.dy - r * .20), r * .82, Paint()..color = AppColors.gold);
      canvas.drawCircle(Offset(center.dx + r * .14, center.dy - r * .34), r * .72, Paint()..color = _color(PrayerStatus.pending));
      _star(canvas, Offset(center.dx + r * .55, center.dy - r * .55), r * .16);
      return;
    }
    canvas.drawCircle(center, r * .48, Paint()..color = AppColors.ink);
    for (var i = 0; i < 8; i++) {
      final a = i / 8 * 2 * math.pi;
      canvas.drawLine(Offset(center.dx + r * .66 * math.cos(a), center.dy + r * .66 * math.sin(a)), Offset(center.dx + r * .98 * math.cos(a), center.dy + r * .98 * math.sin(a)), Paint()..color = AppColors.ink..strokeWidth = 1.5..strokeCap = StrokeCap.round);
    }
  }

  void _star(Canvas canvas, Offset center, double r) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rr = i.isEven ? r : r * .4;
      final p = Offset(center.dx + math.cos(a) * rr, center.dy + math.sin(a) * rr);
      if (i == 0) path.moveTo(p.dx, p.dy); else path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = Colors.white.withValues(alpha: .9));
  }

  void _checkIcon(Canvas canvas, Offset center, double r) {
    final path = Path()..moveTo(center.dx - r * .55, center.dy)..lineTo(center.dx - r * .12, center.dy + r * .42)..lineTo(center.dx + r * .62, center.dy - r * .48);
    canvas.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = 2.7..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..color = Colors.white);
  }

  void _xIcon(Canvas canvas, Offset center, double r) {
    final p = Paint()..color = Colors.white..strokeWidth = 2.7..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(center.dx - r * .48, center.dy - r * .48), Offset(center.dx + r * .48, center.dy + r * .48), p);
    canvas.drawLine(Offset(center.dx + r * .48, center.dy - r * .48), Offset(center.dx - r * .48, center.dy + r * .48), p);
  }

  void _callout(Canvas canvas, Offset center, double radius) {
    final tp = TextPainter(
      text: const TextSpan(
        text: 'الصلاة القادمة',
        style: TextStyle(fontSize: 13, color: AppColors.goldSoft, fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    const height = 30.0;
    final rect = Rect.fromCenter(center: Offset(center.dx, center.dy - radius - 4 - height / 2), width: tp.width + 24, height: height);
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(16));
    canvas.drawRRect(rr, Paint()..color = AppColors.surfaceDark);
    canvas.drawRRect(rr, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5..color = AppColors.gold.withValues(alpha: .9));
    final arrow = Path()..moveTo(center.dx - 7, rect.bottom)..lineTo(center.dx + 7, rect.bottom)..lineTo(center.dx, rect.bottom + 7)..close();
    canvas.drawPath(arrow, Paint()..color = AppColors.surfaceDark);
    canvas.drawPath(arrow, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5..color = AppColors.gold.withValues(alpha: .9));
    tp.paint(canvas, Offset(rect.center.dx - tp.width / 2, rect.center.dy - tp.height / 2));
  }

  void _label(Canvas canvas, String text, double x, double y, Color color, double size, {bool bold = false}) {
    final style = GoogleFonts.tajawal(
      fontSize: size,
      color: color,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      shadows: const [Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1))],
    );
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
    )..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, y));
  }

  @override
  bool shouldRepaint(covariant _DayArcPainter oldDelegate) => oldDelegate.status != status || oldDelegate.prayers != prayers || oldDelegate.period != period || oldDelegate.timeLabelFor != timeLabelFor;
}
