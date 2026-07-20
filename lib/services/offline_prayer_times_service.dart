import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:timezone/timezone.dart' as tz;

import '../models/prayer.dart' as model;

/// يحسب أوقات الصلاة محليًا على الهاتف (بلا إنترنت)
class OfflinePrayerTimesService {
  static Map<adhan.Prayer, DateTime>? calculateToday({
    required double latitude,
    required double longitude,
  }) {
    try {
      final coordinates = adhan.Coordinates(latitude, longitude);

      final params =
          adhan.CalculationMethod.muslimWorldLeague.getParameters();

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

      if ([fajr, dhuhr, asr, maghrib, isha].contains(null)) {
        return null;
      }

      return {
        adhan.Prayer.fajr: fajr!,
        adhan.Prayer.dhuhr: dhuhr!,
        adhan.Prayer.asr: asr!,
        adhan.Prayer.maghrib: maghrib!,
        adhan.Prayer.isha: isha!,
      };
    } catch (_) {
      return null;
    }
  }
}
