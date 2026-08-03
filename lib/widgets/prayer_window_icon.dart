

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
