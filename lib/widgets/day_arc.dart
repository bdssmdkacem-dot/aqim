import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/prayer.dart';
import '../theme/app_theme.dart';

class DayArc extends StatelessWidget {
  final List<Prayer> prayers;
  final Map<Prayer, PrayerStatus> status;
  final String Function(Prayer)? timeLabelFor;
  final dynamic period;

  const DayArc({super.key, required this.prayers, required this.status, this.timeLabelFor, this.period});

  @override
  Widget build(BuildContext context) {
    if (prayers.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 178,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 30, 10, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withOpacity(.82),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withOpacity(.42)),
      ),
      child: Row(
        textDirection: TextDirection.ltr,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: prayers.map((prayer) {
          final s = status[prayer] ?? PrayerStatus.pending;
          final upcoming = s == PrayerStatus.upcoming;
          return Expanded(
            child: _PrayerTile(
              prayer: prayer,
              status: s,
              upcoming: upcoming,
              time: timeLabelFor?.call(prayer) ?? prayer.mockTime,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PrayerTile extends StatelessWidget {
  final Prayer prayer;
  final PrayerStatus status;
  final bool upcoming;
  final String time;

  const _PrayerTile({required this.prayer, required this.status, required this.upcoming, required this.time});

  Color get _statusColor {
    switch (status) {
      case PrayerStatus.done:
        return AppColors.sage;
      case PrayerStatus.missed:
        return AppColors.ember;
      case PrayerStatus.upcoming:
        return AppColors.gold;
      case PrayerStatus.pending:
        return Colors.white.withOpacity(.82);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = upcoming ? 60.0 : 45.0;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        if (upcoming)
          Positioned(
            top: -22,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.gold, width: 1.3),
              ),
              child: Text('الصلاة القادمة', style: GoogleFonts.cairo(fontSize: 10, color: AppColors.goldSoft, fontWeight: FontWeight.w800)),
            ),
          ),
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _statusColor.withOpacity(upcoming ? .95 : .7), width: upcoming ? 2.0 : 1.2),
            boxShadow: upcoming ? [BoxShadow(color: AppColors.gold.withOpacity(.25), blurRadius: 16, spreadRadius: 3)] : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/images/arch_hero.jpg', fit: BoxFit.cover, alignment: _alignmentForPrayer(prayer)),
              ColoredBox(color: _statusColor.withOpacity(status == PrayerStatus.missed ? .42 : .18)),
              Center(child: _PrayerGlyph(prayer: prayer, status: status, upcoming: upcoming)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: EdgeInsets.only(top: size + 7),
          child: Column(
            children: [
              Text(prayer.arabicName, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: GoogleFonts.tajawal(fontSize: upcoming ? 13.5 : 11.5, fontWeight: FontWeight.w800, color: _statusColor)),
              const SizedBox(height: 2),
              Text(time, maxLines: 1, style: GoogleFonts.tajawal(fontSize: upcoming ? 12.5 : 10.5, fontWeight: FontWeight.w700, color: status == PrayerStatus.missed ? AppColors.ember : Colors.white.withOpacity(.92))),
            ],
          ),
        ),
      ],
    );
  }

  Alignment _alignmentForPrayer(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return const Alignment(-.65, -.2);
      case Prayer.dhuhr:
        return const Alignment(.0, -.25);
      case Prayer.asr:
        return const Alignment(.35, -.05);
      case Prayer.maghrib:
        return const Alignment(.65, .05);
      case Prayer.isha:
        return const Alignment(.15, .5);
    }
  }
}

class _PrayerGlyph extends StatelessWidget {
  final Prayer prayer;
  final PrayerStatus status;
  final bool upcoming;

  const _PrayerGlyph({required this.prayer, required this.status, required this.upcoming});

  @override
  Widget build(BuildContext context) {
    if (status == PrayerStatus.done) return const Icon(Icons.check_rounded, color: Colors.white, size: 29);
    if (status == PrayerStatus.missed) return const Icon(Icons.close_rounded, color: Colors.white, size: 28);

    final night = prayer == Prayer.maghrib || prayer == Prayer.isha || prayer == Prayer.fajr;
    return Icon(night ? Icons.nightlight_round : Icons.wb_sunny_rounded, color: Colors.white, size: upcoming ? 31 : 23);
  }
}
