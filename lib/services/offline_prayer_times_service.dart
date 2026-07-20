import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:timezone/timezone.dart' as tz;

import '../models/prayer.dart';

/// يحسب أوقات الصلاة محليًا على الهاتف (بلا إنترنت)
class OfflinePrayerTimesService {
  static Map<Prayer, DateTime>? calculateToday({
    required double latitude,
    required double longitude,
  }) {
    try {
      final coordinates = adhan.Coordinates(latitude, longitude);

      // adhan_dart 1.2.0
      final params = adhan.CalculationMethod.MuslimWorldLeague();

      final now = DateTime.now();

      final prayerTimes = adhan.PrayerTimes(
        coordinates: coordinates,
        date: now,
        calculationParameters: params,
      );

      DateTime? toLocalWallClock(DateTime? dateTime) {
        if (dateTime == null) return null;

        final local = tz.TZDateTime.from(dateTime, tz.local);

        return DateTime(
          now.year,
          now.month,
          now.day,
          local.hour,
          local.minute,
        );
      }

      final fajr = toLocalWallClock(prayerTimes.fajr);
      final dhuhr = toLocalWallClock(prayerTimes.dhuhr);
      final asr = toLocalWallClock(prayerTimes.asr);
      final maghrib = toLocalWallClock(prayerTimes.maghrib);
      final isha = toLocalWallClock(prayerTimes.isha);

      if (fajr == null ||
          dhuhr == null ||
          asr == null ||
          maghrib == null ||
          isha == null) {
        return null;
      }

      return {
        Prayer.fajr: fajr,
        Prayer.dhuhr: dhuhr,
        Prayer.asr: asr,
        Prayer.maghrib: maghrib,
        Prayer.isha: isha,
      };
    } catch (_) {
      return null;
    }
  }
}
