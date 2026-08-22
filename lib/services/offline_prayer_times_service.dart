import 'dart:math' as math;
import '../models/prayer.dart';

/// يحسب أوقات الصلاة محليًا على الهاتف بلا إنترنت.
class OfflinePrayerTimesService {
  static Map<Prayer, DateTime>? calculateToday({
    required double latitude,
    required double longitude,
  }) {
    final now = DateTime.now();
    return calculateForDate(date: now, latitude: latitude, longitude: longitude);
  }

  /// يحسب أوقات الصلاة لأي يوم، ويُستخدم أيضًا لعرض أيام الأجندة السابقة
  /// والقادمة عندما يضغط المستخدم على يوم من الشهر.
  static Map<Prayer, DateTime>? calculateForDate({
    required DateTime date,
    required double latitude,
    required double longitude,
  }) {
    try {
      final localDate = DateTime(date.year, date.month, date.day);
      final jd = _julianDate(localDate.year, localDate.month, localDate.day);
      final sun = _sunPosition(jd);
      final tzOffsetHours = DateTime.now().timeZoneOffset.inMinutes / 60.0;
      final dhuhrLocal = 12 + tzOffsetHours - longitude / 15 - sun.equationOfTime;
      final fajrH = _hourAngle(18.0, latitude, sun.declination);
      final ishaH = _hourAngle(17.0, latitude, sun.declination);
      final maghribH = _hourAngle(0.833, latitude, sun.declination);
      final asrH = _asrHourAngle(latitude, sun.declination);
      if ([fajrH, ishaH, maghribH, asrH].contains(null)) return null;

      DateTime timeFromHours(double hours) {
        final h = _fixHour(hours);
        final totalMinutes = (h * 60).round();
        return localDate.add(Duration(minutes: totalMinutes));
      }

      return {
        Prayer.fajr: timeFromHours(dhuhrLocal - fajrH!),
        Prayer.dhuhr: timeFromHours(dhuhrLocal),
        Prayer.asr: timeFromHours(dhuhrLocal + asrH!),
        Prayer.maghrib: timeFromHours(dhuhrLocal + maghribH!),
        Prayer.isha: timeFromHours(dhuhrLocal + ishaH!),
      };
    } catch (_) {
      return null;
    }
  }

  static double _dtr(double d) => d * math.pi / 180;
  static double _rtd(double r) => r * 180 / math.pi;
  static double _fixAngle(double a) {
    a = a - 360 * (a / 360).floor();
    return a < 0 ? a + 360 : a;
  }
  static double _fixHour(double h) {
    h = h - 24 * (h / 24).floor();
    return h < 0 ? h + 24 : h;
  }
  static double _julianDate(int year, int month, int day) {
    var y = year;
    var m = month;
    if (m <= 2) { y -= 1; m += 12; }
    final a = (y / 100).floor();
    final b = 2 - a + (a / 4).floor();
    return (365.25 * (y + 4716)).floor() + (30.6001 * (m + 1)).floor() + day + b - 1524.5;
  }
  static ({double declination, double equationOfTime}) _sunPosition(double jd) {
    final d = jd - 2451545.0;
    final g = _fixAngle(357.529 + 0.98560028 * d);
    final q = _fixAngle(280.459 + 0.98564736 * d);
    final l = _fixAngle(q + 1.915 * math.sin(_dtr(g)) + 0.020 * math.sin(_dtr(2 * g)));
    final e = 23.439 - 0.00000036 * d;
    var ra = _rtd(math.atan2(math.cos(_dtr(e)) * math.sin(_dtr(l)), math.cos(_dtr(l)))) / 15;
    ra = _fixHour(ra);
    final eqt = q / 15 - ra;
    final decl = _rtd(math.asin(math.sin(_dtr(e)) * math.sin(_dtr(l))));
    return (declination: decl, equationOfTime: eqt);
  }
  static double? _hourAngle(double angle, double latitude, double declination) {
    final term = (-math.sin(_dtr(angle)) - math.sin(_dtr(latitude)) * math.sin(_dtr(declination))) / (math.cos(_dtr(latitude)) * math.cos(_dtr(declination)));
    if (term.isNaN) return null;
    return _rtd(math.acos(term.clamp(-1.0, 1.0))) / 15;
  }
  static double? _asrHourAngle(double latitude, double declination) {
    const shadowFactor = 1.0;
    final angle = -_rtd(math.atan(1 / (shadowFactor + math.tan(_dtr((latitude - declination).abs())))));
    return _hourAngle(angle, latitude, declination);
  }
}
