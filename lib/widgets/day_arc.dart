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
    required this.pr