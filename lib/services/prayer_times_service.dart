import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../models/prayer.dart';

/// Fetches prayer times from AlAdhan and normalizes source timestamps to the
/// device's local DateTime. The resulting DateTime map is the single source
/// consumed by both Home and notification scheduling.
class PrayerTimesService {
  static const _baseUrl = 'https://api.aladhan.com/v1/timings';

  static Future<Map<Prayer, DateTime>?> fetchToday({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).round();
      final uri = Uri.parse(
        '$_baseUrl/$timestamp?latitude=$latitude&longitude=$longitude&method=21',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final timings = json['data']?['timings'] as Map<String, dynamic>?;
      if (timings == null) return null;

      final now = DateTime.now();
      DateTime? parseTime(String? key) {
        if (key == null) return null;
        final value = timings[key];
        if (value is! String) return null;

        // AlAdhan may return e.g. "13:42 (+01)". Keep the source offset
        // instead of silently interpreting that clock time in the device TZ.
        final match = RegExp(
          r'^(\d{1,2}):(\d{2})(?:\s*\(([+-])(\d{2})(?::?(\d{2}))?\))?',
        ).firstMatch(value.trim());
        if (match == null) return null;

        final hour = int.tryParse(match.group(1)!);
        final minute = int.tryParse(match.group(2)!);
        if (hour == null || minute == null) return null;

        late final DateTime parsed;
        final sign = match.group(3);
        if (sign != null) {
          final offsetHours = int.tryParse(match.group(4) ?? '0') ?? 0;
          final offsetMinutes = int.tryParse(match.group(5) ?? '0') ?? 0;
          final offset = Duration(hours: offsetHours, minutes: offsetMinutes);
          final sourceLocal = DateTime.utc(
            now.year,
            now.month,
            now.day,
            hour,
            minute,
          );
          final utc = sign == '+'
              ? sourceLocal.subtract(offset)
              : sourceLocal.add(offset);
          parsed = utc.toLocal();
        } else {
          parsed = DateTime(now.year, now.month, now.day, hour, minute);
        }

        final deviceNow = DateTime.now();
        developer.log(
          'prayer=$key raw="$value" '
          'parsedLocal="${parsed.toIso8601String()}" '
          'epoch=${parsed.millisecondsSinceEpoch} '
          'deviceTimezone="${deviceNow.timeZoneName}" '
          'deviceOffset="${deviceNow.timeZoneOffset}"',
          name: 'Aqim.PrayerTimes.Timestamp',
        );
        return parsed;
      }

      final fajr = parseTime('Fajr');
      final dhuhr = parseTime('Dhuhr');
      final asr = parseTime('Asr');
      final maghrib = parseTime('Maghrib');
      final isha = parseTime('Isha');

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
