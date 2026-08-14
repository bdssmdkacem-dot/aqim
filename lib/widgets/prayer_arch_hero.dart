import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/prayer.dart';
import '../theme/app_theme.dart';
import 'prayer_window_icon.dart' show PrayerDayPeriod;

/// Aqim — Moroccan / Andalusian Mihrab Hero.
///
/// Displays:
/// - Real image from assets/images/arch_hero.jpg
/// - Moroccan pointed horseshoe / mihrab shape
/// - Next prayer
/// - Prayer time
/// - Live countdown
/// - Automatic fallback illustration if the image cannot be loaded
class PrayerArchHero extends StatefulWidget {
  final Prayer next;
  final DateTime? nextRealTime;
  final String timeLabel;
  final PrayerDayPeriod period;

  const PrayerArchHero({
    super.key,
    required this.next,
    required this.nextRealTime,
    required this.timeLabel,
    required this.period,
  });

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

    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _tick(),
    );
  }

  @override
  void didUpdateWidget(covariant PrayerArchHero oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.nextRealTime != widget.nextRealTime ||
        oldWidget.next != widget.next ||
        oldWidget.timeLabel != widget.timeLabel) {
      _tick();
    }
  }

  void _tick() {
    final target = widget.nextRealTime;

    if (target == null) {
      if (mounted && _remaining != null) {
        setState(() {
          _remaining = null;
        });
      }
      return;
    }

    final diff = target.difference(DateTime.now());
    final newValue = diff.isNegative ? Duration.zero : diff;

    if (mounted && _remaining != newValue) {
      setState(() {
        _remaining = newValue;
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

   String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }

  String? get _countdownText {
    final remaining = _remaining;

    if (remaining == null) {
      return null;
    }

    final hours = _twoDigits(remaining.inHours);
    final minutes = _twoDigits(remaining.inMinutes % 60);
    final seconds = _twoDigits(remaining.inSeconds % 60);

    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = math.min(width * 0.60, 340.0);

        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // HERO IMAGE / FALLBACK
              ClipPath(
                clipper: _ArchClipper(),
                child: SizedBox.expand(
                  child: Image.asset(
                    'assets/images/arch_hero.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return CustomPaint(
                        painter: _ArchScenePainter(
                          period: widget.period,
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Continue with the rest of your Stack...

            // ============================================================
            // GLOBAL DARK OVERLAY
            // ============================================================
            Positioned.fill(
              child: IgnorePointer(
                child: ClipPath(
                  clipper: _ArchClipper(),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        stops: const [
                          0.00,
                          0.48,
                          0.68,
                          1.00,
                        ],
                        colors: [
                          Colors.black.withValues(alpha: 0.04),
                          Colors.black.withValues(alpha: 0.08),
                          AppColors.ink.withValues(alpha: 0.42),
                          AppColors.ink.withValues(alpha: 0.86),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
              // ============================================================
              // SUBTLE BOTTOM VIGNETTE
              // ============================================================
                           // ============================================================
              // SUBTLE BOTTOM VIGNETTE
              // ============================================================
              Positioned.fill(
                child: IgnorePointer(
                  child: ClipPath(
                    clipper: _ArchClipper(),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [
                            0.55,
                            0.78,
                            1.00,
                          ],
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.04),
                            Colors.black.withValues(alpha: 0.30),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ============================================================
              // PRAYER INFORMATION
              // ============================================================
              Positioned(
                top: height * 0.15,
                left: width * 0.08,
                width: width * 0.40,
                child: _PrayerInfoPanel(
                  prayerName: widget.next.arabicName,
                  timeLabel: widget.timeLabel,
                  countdownText: _countdownText,
                ),
              ),

              // ============================================================
              // GOLD ARCH BORDER
              // ============================================================
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _ArchBorderPainter(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ==========================================================================
// PRAYER INFORMATION PANEL
// ==========================================================================

class _PrayerInfoPanel extends StatelessWidget {
  final String prayerName;
  final String timeLabel;
  final String? countdownText;

  const _PrayerInfoPanel({
    super.key,
    required this.prayerName,
    required this.timeLabel,
    required this.countdownText,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      constraints: const BoxConstraints(
        minWidth: 135,
        maxWidth: 185,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: .38),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: .28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .18),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'الصلاة القادمة',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 4),

          Align(
            alignment: Alignment.centerRight,
            child: Text(
              prayerName,
              textAlign: TextAlign.right,
              style: GoogleFonts.amiri(
                fontSize: screenWidth < 350 ? 24 : 30,
                fontWeight: FontWeight.bold,
                color: AppColors.gold,
              ),
            ),
          ),

          const SizedBox(height: 10),

          Center(
            child: Text(
              timeLabel,
              textAlign: TextAlign.center,
              style: GoogleFonts.tajawal(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontFeatures: const [
                  FontFeature.tabularFigures(),
                ],
              ),
            ),
          ),

          if (countdownText != null) ...[
            const SizedBox(height: 8),

            const Center(
              child: Text(
                'متبقي',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white60,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 3),

            Center(
              child: Text(
                countdownText!,
                textAlign: TextAlign.center,
                style: GoogleFonts.tajawal(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFeatures: const [
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'إن شاء الله',
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
// ==========================================================================
// ARCH CLIPPER
// ==========================================================================

/// Moroccan / Andalusian pointed horseshoe arch.
///
/// The important change here is that the apex is not simply a triangle.
/// The sides transition smoothly from the pointed top into the wider
/// horseshoe shoulders and then into the vertical walls.
///
/// This gives the hero a more architectural "mihrab" appearance.
class _ArchClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return _archPath(size);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}

// ==========================================================================
// ARCH PATH
// ==========================================================================

Path _archPath(Size size) {
  final w = size.width;
  final h = size.height;

  final path = Path();

  // ------------------------------------------------------------------------
  // Main geometry
  // ------------------------------------------------------------------------

  // Slightly rounded pointed apex.
  final apex = Offset(
    w * 0.50,
    h * 0.015,
  );

  // Upper shoulder region.
  final leftShoulder = Offset(
    w * 0.075,
    h * 0.39,
  );

  final rightShoulder = Offset(
    w * 0.925,
    h * 0.39,
  );

  // Where the horseshoe becomes almost vertical.
  final leftNeck = Offset(
    w * 0.052,
    h * 0.62,
  );

  final rightNeck = Offset(
    w * 0.948,
    h * 0.62,
  );

  // ------------------------------------------------------------------------
  // Start at the apex
  // ------------------------------------------------------------------------

  path.moveTo(
    apex.dx,
    apex.dy,
  );

  // ------------------------------------------------------------------------
  // RIGHT HALF
  // ------------------------------------------------------------------------

  // Point → upper right shoulder.
  path.cubicTo(
    w * 0.63,
    h * 0.025,
    w * 0.84,
    h * 0.15,
    rightShoulder.dx,
    rightShoulder.dy,
  );

  // Shoulder → outer horseshoe curve.
  path.cubicTo(
    w * 0.985,
    h * 0.45,
    w * 0.985,
    h * 0.54,
    rightNeck.dx,
    rightNeck.dy,
  );

  // Right vertical wall.
  path.lineTo(
    rightNeck.dx,
    h,
  );

  // Bottom edge.
  path.lineTo(
    leftNeck.dx,
    h,
  );

  // ------------------------------------------------------------------------
  // LEFT HALF
  // ------------------------------------------------------------------------

  // Left vertical wall.
  path.lineTo(
    leftNeck.dx,
    leftNeck.dy,
  );

  // Outer left horseshoe curve.
  path.cubicTo(
    w * 0.015,
    h * 0.54,
    w * 0.015,
    h * 0.45,
    leftShoulder.dx,
    leftShoulder.dy,
  );

  // Left shoulder → pointed apex.
  path.cubicTo(
    w * 0.16,
    h * 0.15,
    w * 0.37,
    h * 0.025,
    apex.dx,
    apex.dy,
  );

  path.close();

  return path;
}

// ==========================================================================
// ARCH BORDER
// ==========================================================================

class _ArchBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = _archPath(size);

    // Main gold border.
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..color = AppColors.gold
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(
      path,
      borderPaint,
    );

    // Very subtle inner highlight.
    final innerPath = _archPathInset(
      size,
      4.0,
    );

    final innerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = AppColors.gold.withValues(alpha: 0.28)
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(
      innerPath,
      innerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ArchBorderPainter oldDelegate) {
    return false;
  }
}

// ==========================================================================
// INNER ARCH PATH
// ==========================================================================

Path _archPathInset(
  Size size,
  double inset,
) {
  final w = size.width;
  final h = size.height;

  final path = Path();

  final apex = Offset(
    w * 0.50,
    h * 0.015 + inset,
  );

  final leftShoulder = Offset(
    w * 0.075 + inset,
    h * 0.39 + inset * 0.2,
  );

  final rightShoulder = Offset(
    w * 0.925 - inset,
    h * 0.39 + inset * 0.2,
  );

  final leftNeck = Offset(
    w * 0.052 + inset,
    h * 0.62,
  );

  final rightNeck = Offset(
    w * 0.948 - inset,
    h * 0.62,
  );

  path.moveTo(
    apex.dx,
    apex.dy,
  );

  path.cubicTo(
    w * 0.63,
    h * 0.025,
    w * 0.84,
    h * 0.15,
    rightShoulder.dx,
    rightShoulder.dy,
  );

  path.cubicTo(
    w * 0.985 - inset,
    h * 0.45,
    w * 0.985 - inset,
    h * 0.54,
    rightNeck.dx,
    rightNeck.dy,
  );

  path.lineTo(
    rightNeck.dx,
    h - inset,
  );

  path.lineTo(
    leftNeck.dx,
    h - inset,
  );

  path.lineTo(
    leftNeck.dx,
    leftNeck.dy,
  );

  path.cubicTo(
    w * 0.015 + inset,
    h * 0.54,
    w * 0.015 + inset,
    h * 0.45,
    leftShoulder.dx,
    leftShoulder.dy,
  );

  path.cubicTo(
    w * 0.16,
    h * 0.15,
    w * 0.37,
    h * 0.025,
    apex.dx,
    apex.dy,
  );

  path.close();

  return path;
}

// ==========================================================================
// FALLBACK SCENE
// ==========================================================================

/// Fallback illustration used only when arch_hero.jpg cannot be loaded.
class _ArchScenePainter extends CustomPainter {
  final PrayerDayPeriod period;

  _ArchScenePainter({
    required this.period,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final path = _archPath(size);

    canvas.save();

    canvas.clipPath(path);

    final w = size.width;
    final h = size.height;

    final rect = Rect.fromLTWH(
      0,
      0,
      w,
      h,
    );

    // ----------------------------------------------------------------------
    // Sky
    // ----------------------------------------------------------------------

    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: _skyColorsFor(period),
      ).createShader(rect);

    canvas.drawRect(
      rect,
      skyPaint,
    );

    // ----------------------------------------------------------------------
    // Moon / sun
    // ----------------------------------------------------------------------

    final bodyCenter = Offset(
      w * 0.25,
      h * 0.29,
    );

    final isNight = period == PrayerDayPeriod.night;

    if (isNight) {
      _drawMoon(
        canvas,
        bodyCenter,
        w,
        h,
      );

      _drawStars(
        canvas,
        w,
        h,
      );
    } else {
      _drawSun(
        canvas,
        bodyCenter,
        w,
      );
    }

    // ----------------------------------------------------------------------
    // Horizon glow
    // ----------------------------------------------------------------------

    final horizonGlow = Paint()
      ..color = const Color(0xFFFFE9B0).withValues(alpha: 0.10)
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        24,
      );

    canvas.drawRect(
      Rect.fromLTWH(
        0,
        h * 0.67,
        w,
        h * 0.18,
      ),
      horizonGlow,
    );

    // ----------------------------------------------------------------------
    // Water / ground
    // ----------------------------------------------------------------------

    final waterPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25);

    canvas.drawRect(
      Rect.fromLTWH(
        0,
        h * 0.79,
        w,
        h * 0.21,
      ),
      waterPaint,
    );

    // ----------------------------------------------------------------------
    // Mosque silhouette
    // ----------------------------------------------------------------------

    _drawMosque(
      canvas,
      size,
    );

    canvas.restore();
  }

  // ------------------------------------------------------------------------
  // SUN
  // ------------------------------------------------------------------------

  void _drawSun(
    Canvas canvas,
    Offset center,
    double width,
  ) {
    final glow = Paint()
      ..color = const Color(0xFFFFE9B0).withValues(alpha: 0.48)
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        28,
      );

    canvas.drawCircle(
      center,
      width * 0.10,
      glow,
    );

    final sunPaint = Paint()
      ..color = const Color(0xFFFFF3D2);

    canvas.drawCircle(
      center,
      width * 0.052,
      sunPaint,
    );
  }

  // ------------------------------------------------------------------------
  // MOON
  // ------------------------------------------------------------------------

  void _drawMoon(
    Canvas canvas,
    Offset center,
    double width,
    double height,
  ) {
    final moonRadius = width * 0.052;

    final moonPaint = Paint()
      ..color = const Color(0xFFEFE6C8);

    canvas.drawCircle(
      center,
      moonRadius,
      moonPaint,
    );

    // Small dark cutout to create crescent.
    final cutoutPaint = Paint()
      ..color = const Color(0xFF101A38);

    canvas.drawCircle(
      Offset(
        center.dx + moonRadius * 0.43,
        center.dy - moonRadius * 0.25,
      ),
      moonRadius * 0.86,
      cutoutPaint,
    );
  }

  // ------------------------------------------------------------------------
  // STARS
  // ------------------------------------------------------------------------

  void _drawStars(
    Canvas canvas,
    double width,
    double height,
  ) {
    final starPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.75);

    final stars = <Offset>[
      Offset(width * 0.47, height * 0.12),
      Offset(width * 0.59, height * 0.20),
      Offset(width * 0.42, height * 0.23),
      Offset(width * 0.67, height * 0.10),
      Offset(width * 0.77, height * 0.24),
      Offset(width * 0.34, height * 0.13),
    ];

    for (final star in stars) {
      canvas.drawCircle(
        star,
        1.5,
        starPaint,
      );
    }
  }

  // ------------------------------------------------------------------------
  // MOSQUE
  // ------------------------------------------------------------------------

  void _drawMosque(
    Canvas canvas,
    Size size,
  ) {
    final w = size.width;
    final h = size.height;

    final baseY = h * 0.80;

    final silhouette = Paint()
      ..color = Colors.black.withValues(alpha: 0.58);

    // ------------------------------------------------------------
    // Minaret helper
    // ------------------------------------------------------------

    void minaret(
      double centerX,
      double topY,
      double towerWidth,
    ) {
      final tower = Path();

      tower.moveTo(
        centerX - towerWidth / 2,
        baseY,
      );

      tower.lineTo(
        centerX - towerWidth / 2,
        topY + towerWidth * 1.5,
      );

      tower.lineTo(
        centerX,
        topY,
      );

      tower.lineTo(
        centerX + towerWidth / 2,
        topY + towerWidth * 1.5,
      );

      tower.lineTo(
        centerX + towerWidth / 2,
        baseY,
      );

      tower.close();

      canvas.drawPath(
        tower,
        silhouette,
      );

      canvas.drawCircle(
        Offset(
          centerX,
          topY - towerWidth * 0.35,
        ),
        towerWidth * 0.22,
        silhouette,
      );
    }

    // ------------------------------------------------------------
    // Dome helper
    // ------------------------------------------------------------

    void dome(
      double centerX,
      double domeTop,
      double radius,
    ) {
      final domeRect = Rect.fromCircle(
        center: Offset(
          centerX,
          domeTop + radius,
        ),
        radius: radius,
      );

      canvas.drawArc(
        domeRect,
        math.pi,
        math.pi,
        true,
        silhouette,
      );

      canvas.drawRect(
        Rect.fromLTWH(
          centerX - radius * 0.90,
          domeTop + radius,
          radius * 1.80,
          baseY - (domeTop + radius),
        ),
        silhouette,
      );
    }

    // ------------------------------------------------------------
    // Distant minarets
    // ------------------------------------------------------------

    minaret(
      w * 0.23,
      h * 0.43,
      w * 0.025,
    );

    minaret(
      w * 0.83,
      h * 0.42,
      w * 0.028,
    );

    // ------------------------------------------------------------
    // Small domes
    // ------------------------------------------------------------

    dome(
      w * 0.72,
      h * 0.57,
      w * 0.055,
    );

    dome(
      w * 0.90,
      h * 0.61,
      w * 0.040,
    );

    // ------------------------------------------------------------
    // Main minarets
    // ------------------------------------------------------------

    minaret(
      w * 0.47,
      h * 0.33,
      w * 0.032,
    );

    minaret(
      w * 0.66,
      h * 0.36,
      w * 0.027,
    );

    // ------------------------------------------------------------
    // Main dome
    // ------------------------------------------------------------

    dome(
      w * 0.57,
      h * 0.43,
      w * 0.105,
    );
  }

  // ------------------------------------------------------------------------
  // SKY COLORS
  // ------------------------------------------------------------------------

  List<Color> _skyColorsFor(
    PrayerDayPeriod period,
  ) {
    switch (period) {
      case PrayerDayPeriod.dawn:
        return const [
          Color(0xFF29263D),
          Color(0xFF684B61),
          Color(0xFFC58A5A),
        ];

      case PrayerDayPeriod.day:
        return const [
          Color(0xFF3F769C),
          Color(0xFF85B4CC),
          Color(0xFFE5D6AD),
        ];

      case PrayerDayPeriod.sunset:
        return const [
          Color(0xFF302A45),
          Color(0xFF955C50),
          Color(0xFFE2A35B),
        ];

      case PrayerDayPeriod.night:
        return const [
          Color(0xFF080F28),
          Color(0xFF111E3D),
          Color(0xFF1D3450),
        ];
    }
  }

  @override
  bool shouldRepaint(
    covariant _ArchScenePainter oldDelegate,
  ) {
    return oldDelegate.period != period;
  }
}
