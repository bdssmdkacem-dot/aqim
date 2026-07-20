import 'dart:convert';
import 'package:http/http.dart' as http;

/// يحوّل الإحداثيات إلى اسم مدينة عبر Nominatim (OpenStreetMap) — نفس
/// المصدر المستعمل لأقرب مسجد، بلا حاجة لمفتاح API.
class GeocodingService {
  static const _endpoint = 'https://nominatim.openstreetmap.org/reverse';

  static Future<String?> cityFor({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final uri = Uri.parse(
        '$_endpoint?format=jsonv2&lat=$latitude&lon=$longitude&accept-language=ar',
      );
      final res = await http.get(
        uri,
        // سياسة Nominatim تفرض تعريف التطبيق عبر User-Agent.
        headers: {'User-Agent': 'AqimApp/1.0 (aqim prayer habit app)'},
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final address = json['address'] as Map<String, dynamic>?;
      if (address == null) return null;

      // ترتيب الأولوية: قد لا تتوفر كل الحقول حسب المنطقة.
      final city = address['city'] ??
          address['town'] ??
          address['village'] ??
          address['municipality'] ??
          address['county'] ??
          address['state'];
      return (city as String?)?.trim();
    } catch (_) {
      return null;
    }
  }
}
