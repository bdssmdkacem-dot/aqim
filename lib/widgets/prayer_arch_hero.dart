import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/prayer.dart';
import '../theme/app_theme.dart';
import 'prayer_window_icon.dart' show PrayerDayPeriod;

class PrayerArchHero extends StatefulWidget {
  final Prayer next;
  final DateTime? nextRealTime;
  final String timeLabel;
  final PrayerDayPeriod period;

  const PrayerArchHero({super.key, required this.next, required this.nextRealTime, required this.timeLabel, required this.period});

  @override
  State<PrayerArchHero> createState() => _PrayerArchHeroState();
}

class _PrayerArchHeroState extends State<PrayerArchHero> {
  Timer? _ticker;
  Duration? _remaining;

  @override
  void initState() {
    super.initState();
    _tick();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didUpdateWidget(covariant PrayerArchHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nextRealTime != widget.nextRealTime || oldWidget.next != widget.next || oldWidget.timeLabel != widget.timeLabel) _tick();
  }

  void _tick() {
    final target = widget.nextRealTime;
    if (target == null) {
      if (mounted && _remaining != null) setState(() => _remaining = null);
      return;
    }
    final diff = target.difference(DateTime.now());
    final value = diff.isNegative ? Duration.zero : diff;
    if (mounted && _remaining != value) setState(() => _remaining = value);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  String? get _countdownText {
    final remaining = _remaining;
    if (remaining == null) return null;
    return '${_twoDigits(remaining.inHours)}:${_twoDigits(remaining.inMinutes % 60)}:${_twoDigits(remaining.inSeconds % 60)}';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final height = math.min(width * 0.84, 780.0);
      return SizedBox(
        width: width,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipPath(
              clipper: _ArchClipper(),
              child: SizedBox.expand(
                child: Image.asset(
                  'assets/images/arch_hero.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (context, error, stackTrace) => CustomPaint(painter: _ArchScenePainter(period: widget.period)),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: ClipPath(
                  clipper: _ArchClipper(),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        stops: const [0.00, 0.48, 0.68, 1.00],
                        colors: [Colors.black.withValues(alpha: 0.04), Colors.black.withValues(alpha: 0.08), AppColors.ink.withValues(alpha: 0.42), AppColors.ink.withValues(alpha: 0.86)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: ClipPath(
                  clipper: _ArchClipper(),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.55, 0.78, 1.00],
                        colors: [Colors.transparent, AppColors.ink.withValues(alpha: 0.16), AppColors.ink.withValues(alpha: 0.72)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: height * 0.18,
              left: 0,
              right: 0,
              child: Center(child: _HeroPrayerInfo(prayerName: widget.next.arabicName, timeLabel: widget.timeLabel, countdownText: _countdownText)),
            ),
            Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _ArchBorderPainter()))),
          ],
        ),
      );
    });
  }
}

class _HeroPrayerInfo extends StatelessWidget {
  final String prayerName;
  final String timeLabel;
  final String? countdownText;

  const _HeroPrayerInfo({required this.prayerName, required this.timeLabel, required this.countdownText});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('الصلاة القادمة', textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 6),
        Text(prayerName, textAlign: TextAlign.center, style: GoogleFonts.amiri(fontSize: 48, height: .95, fontWeight: FontWeight.w700, color: AppColors.gold, shadows: const [Shadow(color: Colors.black54, blurRadius: 6)])),
        const SizedBox(height: 16),
        Text(timeLabel, textAlign: TextAlign.center, style: GoogleFonts.tajawal(fontSize: 38, fontWeight: FontWeight.w800, color: Colors.white, fontFeatures: const [FontFeature.tabularFigures()], shadows: const [Shadow(color: Colors.black87, blurRadius: 6)])),
        if (countdownText != null) ...[
          const SizedBox(height: 10),
          Text('بعد', textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 16, color: Colors.white)),
          const SizedBox(height: 3),
          Text(countdownText!, textAlign: TextAlign.center, style: GoogleFonts.tajawal(fontSize: 31, fontWeight: FontWeight.w800, color: AppColors.gold, fontFeatures: const [FontFeature.tabularFigures()], shadows: const [Shadow(color: Colors.black87, blurRadius: 6)])),
          const SizedBox(height: 12),
          Container(width: 150, height: 1, color: AppColors.gold.withValues(alpha: .75)),
          const SizedBox(height: 9),
          Text('إن شاء الله', textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 14, color: AppColors.goldSoft, fontWeight: FontWeight.w600)),
        ],
      ],
    );
  }
}

class _ArchClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => _archPath(size);
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

Path _archPath(Size size) {
  final w = size.width;
  final h = size.height;
  final path = Path();
  final apex = Offset(w * .50, h * .015);
  final leftShoulder = Offset(w * .075, h * .39);
  final rightShoulder = Offset(w * .925, h * .39);
  final leftNeck = Offset(w * .052, h * .62);
  final rightNeck = Offset(w * .948, h * .62);
  path.moveTo(apex.dx, apex.dy);
  path.cubicTo(w * .63, h * .025, w * .84, h * .15, rightShoulder.dx, rightShoulder.dy);
  path.cubicTo(w * .985, h * .45, w * .985, h * .54, rightNeck.dx, rightNeck.dy);
  path.lineTo(rightNeck.dx, h);
  path.lineTo(leftNeck.dx, h);
  path.lineTo(leftNeck.dx, leftNeck.dy);
  path.cubicTo(w * .015, h * .54, w * .015, h * .45, leftShoulder.dx, leftShoulder.dy);
  path.cubicTo(w * .16, h * .15, w * .37, h * .025, apex.dx, apex.dy);
  path.close();
  return path;
}

class _ArchBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(_archPath(size), Paint()..style = PaintingStyle.stroke..strokeWidth = 2.4..color = AppColors.gold..strokeJoin = StrokeJoin.round..strokeCap = StrokeCap.round);
  }
  @override
  bool shouldRepaint(covariant _ArchBorderPainter oldDelegate) => false;
}

class _ArchScenePainter extends CustomPainter {
  final PrayerDayPeriod period;
  _ArchScenePainter({required this.period});
  @override
  void paint(Canvas canvas, Size size) {
    final path = _archPath(size);
    canvas.save();
    canvas.clipPath(path);
    final w = size.width;
    final h = size.height;
    final rect = Rect.fromLTWH(0, 0, w, h);
    canvas.drawRect(rect, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: _skyColorsFor(period)).createShader(rect));
    canvas.drawCircle(Offset(w * .25, h * .29), w * .10, Paint()..color = const Color(0xFFFFE9B0).withValues(alpha: .20));
    canvas.drawCircle(Offset(w * .25, h * .29), w * .052, Paint()..color = const Color(0xFFFFF3D2));
    canvas.drawRect(Rect.fromLTWH(0, h * .79, w, h * .21), Paint()..color = Colors.black.withValues(alpha: .25));
    canvas.restore();
  }
  List<Color> _skyColorsFor(PrayerDayPeriod period) {
    switch (period) {
      case PrayerDayPeriod.dawn: return const [Color(0xFF29263D), Color(0xFF684B61), Color(0xFFC58A5A)];
      case PrayerDayPeriod.day: return const [Color(0xFF3F769C), Color(0xFF85B4CC), Color(0xFFE5D6AD)];
      case PrayerDayPeriod.sunset: return const [Color(0xFF302A45), Color(0xFF955C50), Color(0xFFE2A35B)];
      case PrayerDayPeriod.night: return const [Color(0xFF080F28), Color(0xFF111E3D), Color(0xFF1D3450)];
    }
  }
  @override
  bool shouldRepaint(covariant _ArchScenePainter oldDelegate) => oldDelegate.period != period;
}
