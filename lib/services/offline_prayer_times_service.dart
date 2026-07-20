import 'package:adhan_dart/adhan_dart.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/prayer.dart';

/// يحسب أوقات الصلاة محليًا على الهاتف (بلا إنترنت إطلاقًا) بالاعتماد
/// على معادلات فلكية قياسية (مكتبة Adhan، طريقة رابطة العالم الإسلامي).
/// يُستعمل فقط كخطة بديلة عند تعذّر الوصول لـ AlAdhan API (بلا إنترنت)،
/// طالما توفّرت إحداثيات (حتى لو من GPS بلا شبكة، أو آخر إحداثيات
/// محفوظة). الفرق عن الطريقة الرسمية المغربية عادة دقائق قليلة فقط.
class OfflinePrayerTimesService {
  static Map<Prayer, DateTime>? calculateToday({
    required double latitude,
    required double longitude,
  }) {
    try {
      final coordinates = Coordinates(latitude, longitude);
      final params = CalculationMethod.MuslimWorldLeague();
      final now = DateTime.now();

      final prayerTimes = PrayerTimes(
        coordinates: coordinates,
        date: now,
        calculationParameters: params,
      );

      DateTime? toLocalWallClock(DateTime? utcTime) {
        if (utcTime == null) return null;
        final local = tz.TZDateTime.from(utcTime, tz.local);
        return DateTime(now.year, now.month, now.day, local.hour, local.minute);
      }

      final fajr = toLocalWallClock(prayerTimes.fajr);
      final dhuhr = toLocalWallClock(prayerTimes.dhuhr);
      final asr = toLocalWallClock(prayerTimes.asr);
      final maghrib = toLocalWallClock(prayerTimes.maghrib);
      final isha = toLocalWallClock(prayerTimes.isha);

      if ([fajr, dhuhr, asr, maghrib, isha].contains(null)) return null;

      return {
        Prayer.fajr: fajr!,
        Prayer.dhuhr: dhuhr!,
        Prayer.asr: asr!,
        Prayer.maghrib: maghrib!,
        Prayer.isha: isha!,
      };
    } catch (_) {
      return null;
    }
  }
}
