import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../models/prayer.dart';

/// Fetches prayer times from AlAdhan. The API returns the prayer clock time
/// for the requested coordinates; Aqim keeps that local civil time so Home
/// and scheduling use the same DateTime behavior as the original app.
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

        // Preserve the original Aqim behavior: AlAdhan's HH:mm clock value
        // is interpreted as local civil time. Do not convert the (+01) label
        // into a second timezone conversion on the device.
        final raw = value.split(' ').first;
        final parts = raw.split(':');
        if (parts.length != 2) return null;
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour == null || minute == null) return null;

        final parsed = DateTime(now.year, now.month, now.day, hour, minute);
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
