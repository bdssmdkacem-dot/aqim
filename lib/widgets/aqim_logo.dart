import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Compact vector version of the Aqim brand mark.
/// It follows the existing Aqim branding: dark rounded field, gold day arc,
/// five progress nodes and a small crescent representing night-to-light.
class AqimLogo extends StatelessWidget {
  final double size;
  final bool showBorder;

  const AqimLogo({super.key, this.size = 44, this.showBorder = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AqimLogoPainter(showBorder: showBorder),
      ),
    );
  }
}

class _AqimLogoPainter extends CustomPainter {
  final bool showBorder;
  const _AqimLogoPainter({required this.showBorder});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final rect = Offset.zero & size;
    final radius = Radius.circular(s * .225);

    final bg = Paint()..color = AppColors.ink;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), bg);

    if (showBorder) {
      final border = Paint()
        ..color = AppColors.gold.withOpacity(.42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, s * .025);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.deflate(s * .012),
          Radius.circular(s * .21),
        ),
        border,
      );
    }

    final cx = s * .50;
    final cy = s * .60;
    final rx = s * .29;
    final ry = s * .30;

    final arcPaint = Paint()
      ..color = AppColors.gold.withOpacity(.70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, s * .012)
      ..strokeCap = StrokeCap.round;

    final points = <Offset>[];
    for (var i = 0; i < 5; i++) {
      final t = i / 4;
      points.add(Offset(
        cx - rx + 2 * rx * t,
        cy - math.sin(t * math.pi) * ry,
      ));
    }
    for (var i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], arcPaint);
    }

    for (var i = 0; i < points.length; i++) {
      final active = i < 2;
      final current = i == 2;
      final radiusNode = s * (current ? .027 : .020);
      final paint = Paint()
        ..color = active
            ? AppColors.sage
            : current
                ? AppColors.gold
                : AppColors.paper.withOpacity(.68);
      canvas.drawCircle(points[i], radiusNode, paint);
      if (current) {
        final glow = Paint()..color = AppColors.gold.withOpacity(.10);
        canvas.drawCircle(points[i], radiusNode * 2.6, glow);
      }
    }

    // Crescent: a simple gold crescent near the top of the mark.
    final moonCenter = Offset(s * .50, s * .245);
    final moonR = s * .075;
    final moon = Path()
      ..addOval(Rect.fromCircle(center: moonCenter, radius: moonR));
    final cutout = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(moonCenter.dx + moonR * .57, moonCenter.dy - moonR * .12),
        width: moonR * 1.7,
        height: moonR * 2.05,
      ));
    final crescent = Path.combine(PathOperation.difference, moon, cutout);
    canvas.drawPath(crescent, Paint()..color = AppColors.goldSoft);
  }

  @override
  bool shouldRepaint(covariant _AqimLogoPainter oldDelegate) =>
      oldDelegate.showBorder != showBorder;
}
