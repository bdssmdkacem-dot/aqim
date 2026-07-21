import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class MosqueInfo {
  final String name;
  final double latitude;
  final double longitude;
  final double distanceMeters;

  const MosqueInfo({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
  });

  String get distanceLabel {
    if (distanceMeters < 1000) return '${distanceMeters.round()} م';
    return '${(distanceMeters / 1000).toStringAsFixed(1)} كم';
  }
}

/// يجلب أقرب المساجد عبر Overpass API (بيانات OpenStreetMap مفتوحة
/// المصدر، بلا حاجة لمفتاح API أو فوترة — بديل عملي لخرائط Google لهذا
/// الاستعمال البسيط).
class MosqueService {
  static const _endpoint = 'https://overpass-api.de/api/interpreter';

  static Future<List<MosqueInfo>?> fetchNearby({
    required double latitude,
    required double longitude,
    double radiusMeters = 3000,
  }) async {
    final query = '''
[out:json][timeout:15];
(
  node["amenity"="place_of_worship"]["religion"="muslim"](around:$radiusMeters,$latitude,$longitude);
  way["amenity"="place_of_worship"]["religion"="muslim"](around:$radiusMeters,$latitude,$longitude);
);
out center 30;
''';

    try {
      final res = await http
          .post(Uri.parse(_endpoint), body: {'data': query})
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return null;

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final elements = json['elements'] as List<dynamic>?;
      if (elements == null) return [];

      final results = <MosqueInfo>[];
      for (final el in elements) {
        final map = el as Map<String, dynamic>;
        double? lat = (map['lat'] as num?)?.toDouble();
        double? lon = (map['lon'] as num?)?.toDouble();
        // العناصر من نوع way ليس لها lat/lon مباشرة، بل center.
        if (lat == null || lon == null) {
          final center = map['center'] as Map<String, dynamic>?;
          lat = (center?['lat'] as num?)?.toDouble();
          lon = (center?['lon'] as num?)?.toDouble();
        }
        if (lat == null || lon == null) continue;

        final tags = map['tags'] as Map<String, dynamic>?;
        final name = (tags?['name'] as String?)?.trim();

        final distance = Geolocator.distanceBetween(latitude, longitude, lat, lon);
        results.add(MosqueInfo(
          name: (name == null || name.isEmpty) ? 'مسجد' : name,
          latitude: lat,
          longitude: lon,
          distanceMeters: distance,
        ));
      }

      results.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
      return results;
    } catch (_) {
      return null;
    }
  }
}
