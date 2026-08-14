import 'dart:async';
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
      final height = (width * .56).clamp(300.0, 430.0);

      return SizedBox(
        width: width,
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/arch_hero.jpg',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (_, __, ___) => DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: _fallbackColors(widget.period),
                    ),
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withValues(alpha: .18), Colors.black.withValues(alpha: .28), AppColors.ink.withValues(alpha: .78)],
                    stops: const [.0, .52, 1.0],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
                child: Center(
                  child: _HeroPrayerInfo(
                    prayerName: widget.next.arabicName,
                    timeLabel: widget.timeLabel,
                    countdownText: _countdownText,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  List<Color> _fallbackColors(PrayerDayPeriod period) {
    switch (period) {
      case PrayerDayPeriod.dawn:
        return const [Color(0xFF352D46), Color(0xFF9A685C), Color(0xFF17241F)];
      case PrayerDayPeriod.day:
        return const [Color(0xFF315A61), Color(0xFF547E74), Color(0xFF0A2820)];
      case PrayerDayPeriod.sunset:
        return const [Color(0xFF3A2B42), Color(0xFF9A644F), Color(0xFF11251F)];
      case PrayerDayPeriod.night:
        return const [Color(0xFF08132C), Color(0xFF14243C), Color(0xFF071E18)];
    }
  }
}

class _HeroPrayerInfo extends StatelessWidget {
  final String prayerName;
  final String timeLabel;
  final String? countdownText;

  const _HeroPrayerInfo({required this.prayerName, required this.timeLabel, required this.countdownText});

  Widget _fitText(String text, TextStyle style) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Text(text, textAlign: TextAlign.center, maxLines: 1, softWrap: false, style: style),
      );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final available = constraints.maxWidth;
      final nameSize = (available * .115).clamp(34.0, 50.0);
      final timeSize = (available * .095).clamp(30.0, 42.0);
      final countdownSize = (available * .072).clamp(24.0, 34.0);

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _fitText('الصلاة القادمة', GoogleFonts.cairo(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 2),
          _fitText(prayerName, GoogleFonts.amiri(fontSize: nameSize, height: 1, fontWeight: FontWeight.w700, color: AppColors.gold, shadows: const [Shadow(color: Colors.black87, blurRadius: 7)])),
          const SizedBox(height: 5),
          _fitText(timeLabel, GoogleFonts.tajawal(fontSize: timeSize, fontWeight: FontWeight.w900, color: Colors.white, fontFeatures: const [FontFeature.tabularFigures()], shadows: const [Shadow(color: Colors.black87, blurRadius: 7)])),
          if (countdownText != null) ...[
            const SizedBox(height: 4),
            _fitText('بعد', GoogleFonts.cairo(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w500)),
            const SizedBox(height: 1),
            _fitText(countdownText!, GoogleFonts.tajawal(fontSize: countdownSize, fontWeight: FontWeight.w900, color: AppColors.gold, fontFeatures: const [FontFeature.tabularFigures()], shadows: const [Shadow(color: Colors.black87, blurRadius: 7)])),
            const SizedBox(height: 6),
            Container(width: available * .45, height: 1.2, color: AppColors.gold.withValues(alpha: .82)),
            const SizedBox(height: 5),
            _fitText('إن شاء الله', GoogleFonts.cairo(fontSize: 15, color: AppColors.goldSoft, fontWeight: FontWeight.w700)),
          ],
        ],
      );
    });
  }
}
