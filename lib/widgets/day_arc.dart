import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/prayer.dart';
import '../theme/app_theme.dart';

/// "قوس اليوم": يمثل الصلوات الخمس كنقاط على مسار مقوّس يشبه مسار الشمس،
/// كل نقطة تُلوَّن بحسب حالتها (تمت / القادمة / لم يحن وقتها / فائتة).
class DayArc extends StatelessWidget {
  final List<Prayer> prayers;
  final Map<Prayer, PrayerStatus> status;

  const DayArc({super.key, required this.prayers, required this.status});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: CustomPaint(
        painter: _DayArcPainter(prayers: prayers, status: status),
        child: Container(),
      ),
    );
  }
}

class _DayArcPainter extends CustomPainter {
  final List<Prayer> prayers;
  final Map<Prayer, PrayerStatus> status;

  _DayArcPainter({required this.prayers, required this.status});

  Color _colorFor(PrayerStatus s) {
    switch (s) {
      case PrayerStatus.done:
        return AppColors.sage;
      case PrayerStatus.upcoming:
        return AppColors.gold;
      case PrayerStatus.missed:
        return AppColors.ember;
      case PrayerStatus.pending:
        return AppColors.paperLine;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final n = prayers.length;
    if (n == 0) return;
    final margin = 26.0;
    final usableWidth = size.width - margin * 2;
    final points = <Offset>[];
    for (var i = 0; i < n; i++) {
      final t = n == 1 ? 0.5 : i / (n - 1);
      final x = margin + usableWidth * t;
      final y = 78 - math.sin(t * math.pi) * 52;
      points.add(Offset(x, y));
    }

    // خط المسار بتدرّج نيلي-ذهبي-نيلي، شفاف قليلًا.
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..shader = LinearGradient(
        colors: [
          AppColors.ink.withOpacity(0.25),
          AppColors.gold.withOpacity(0.35),
          AppColors.ink.withOpacity(0.25),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path, linePaint);

    for (var i = 0; i < n; i++) {
      final p = prayers[i];
      final s = status[p] ?? PrayerStatus.pending;
      final color = _colorFor(s);
      final center = points[i];
      final radius = s == PrayerStatus.upcoming ? 9.0 : 7.0;

      if (s == PrayerStatus.upcoming) {
        final glow = Paint()
          ..color = AppColors.gold.withOpacity(0.18)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, radius + 8, glow);
      }

      final dot = Paint()..color = color;
      canvas.drawCircle(center, radius, dot);

      if (s == PrayerStatus.done) {
        final tp = TextPainter(
          text: const TextSpan(
            text: '✓',
            style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
      }
      if (s == PrayerStatus.missed) {
        final tp = TextPainter(
          text: const TextSpan(
            text: '✕',
            style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
      }

      _drawLabel(canvas, p.arabicName, center.dx, center.dy + 20, AppColors.textMuted, 10);
      _drawLabel(canvas, p.mockTime, center.dx, center.dy + 32, AppColors.textMuted.withOpacity(0.8), 9);
    }
  }

  void _drawLabel(Canvas canvas, String text, double cx, double y, Color color, double fontSize) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.tajawal(fontSize: fontSize, color: color),
      ),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, y));
  }

  @override
  bool shouldRepaint(covariant _DayArcPainter oldDelegate) {
    return oldDelegate.status != status || oldDelegate.prayers != prayers;
  }
}
