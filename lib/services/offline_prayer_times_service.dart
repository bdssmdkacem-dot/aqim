import 'dart:math' as math;
import '../models/prayer.dart';

/// يحسب أوقات الصلاة محليًا على الهاتف (بلا إنترنت إطلاقًا وبلا أي
/// حزمة خارجية) بالاعتماد على معادلات فلكية قياسية معروفة (خوارزمية
/// praytimes.org، طريقة رابطة العالم الإسلامي: زاوية الفجر ١٨°، زاوية
/// العشاء ١٧°، حساب العصر بمذهب الشافعي). يُستعمل فقط كخطة بديلة عند
/// تعذّر الوصول لـ AlAdhan API، طالما توفّرت إحداثيات (حتى GPS بلا
/// شبكة). الفرق عن الطريقة الرسمية المغربية عادة دقائق قليلة فقط.
///
/// مكتوبة بلا أي حزمة خارجية عمدًا (dart:math فقط) لتفادي مفاجآت تغيّر
/// واجهات الحزم الخارجية بين الإصدارات.
class OfflinePrayerTimesService {
  static Map<Prayer, DateTime>? calculateToday({
    required double latitude,
    required double longitude,
  }) {
    try {
      final now = DateTime.now();
      final jd = _julianDate(now.year, now.month, now.day);
      final sun = _sunPosition(jd);

      final tzOffsetHours = now.timeZoneOffset.inMinutes / 60.0;
      final dhuhrLocal = 12 + tzOffsetHours - longitude / 15 - sun.equationOfTime;

      final fajrH = _hourAngle(18.0, latitude, sun.declination);
      final ishaH = _hourAngle(17.0, latitude, sun.declination);
      final maghribH = _hourAngle(0.833, latitude, sun.declination);
      final asrH = _asrHourAngle(latitude, sun.declination);

      if ([fajrH, ishaH, maghribH, asrH].contains(null)) return null;

      DateTime timeFromHours(double hours) {
        final h = _fixHour(hours);
        final totalMinutes = (h * 60).round();
        return DateTime(now.year, now.month, now.day).add(Duration(minutes: totalMinutes));
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

  /// رقم اليوم اليولياني (Julian Date) عند الساعة صفر توقيت غرينتش.
  static double _julianDate(int year, int month, int day) {
    var y = year;
    var m = month;
    if (m <= 2) {
      y -= 1;
      m += 12;
    }
    final a = (y / 100).floor();
    final b = 2 - a + (a / 4).floor();
    final jd = (365.25 * (y + 4716)).floor() + (30.6001 * (m + 1)).floor() + day + b - 1524.5;
    return jd;
  }

  /// انحراف الشمس ومعادلة الزمن لليوم المُعطى (معادلات مبسّطة لحساب
  /// موضع الشمس، دقتها كافية لأوقات الصلاة).
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

  /// زاوية الوقت (بالساعات) لصلاة تُحسب بزاوية شمسية معيّنة تحت الأفق
  /// (الفجر، العشاء، المغرب/الشروق).
  static double? _hourAngle(double angle, double latitude, double declination) {
    final term = (-math.sin(_dtr(angle)) - math.sin(_dtr(latitude)) * math.sin(_dtr(declination))) /
        (math.cos(_dtr(latitude)) * math.cos(_dtr(declination)));
    if (term.isNaN) return null;
    final clamped = term.clamp(-1.0, 1.0);
    return _rtd(math.acos(clamped)) / 15;
  }

  /// زاوية وقت العصر بمذهب الشافعي (معامل الظل = ١).
  static double? _asrHourAngle(double latitude, double declination) {
    const shadowFactor = 1.0;
    final angle = -_rtd(
      math.atan(1 / (shadowFactor + math.tan(_dtr((latitude - declination).abs())))),
    );
    return _hourAngle(angle, latitude, declination);
  }
}
