import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/prayer.dart';

/// يجلب أوقات الصلاة الحقيقية لليوم من AlAdhan API (مصدر مفتوح وموثوق
/// يُستعمل في عشرات التطبيقات الإسلامية). method=21 هي طريقة حساب وزارة
/// الأوقاف والشؤون الإسلامية المغربية. الأوقات المُرجعة بالتوقيت المحلي
/// لموقع الإحداثيات المُرسَلة، لذا لا حاجة لأي تحويل توقيت إضافي.
class PrayerTimesService {
  static const _baseUrl = 'https://api.aladhan.com/v1/timings';

  /// يرجع خريطة Prayer → DateTime لليوم الحالي، أو null إن فشل الطلب
  /// (بلا إنترنت، أو الخادم غير متاح) — الاستدعاء يجب أن يتعامل مع
  /// null بالرجوع للأوقات الاحتياطية الثابتة.
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
        final raw = (timings[key] as String?)?.split(' ').first; // يحذف أي لاحقة منطقة زمنية
        if (raw == null) return null;
        final parts = raw.split(':');
        if (parts.length != 2) return null;
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour == null || minute == null) return null;
        return DateTime(now.year, now.month, now.day, hour, minute);
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
