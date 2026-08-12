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
    if (distanceMeters < 1000) {
      return "${distanceMeters.round()} م";
    }
    return "${(distanceMeters / 1000).toStringAsFixed(1)} كم";
  }
}

class MosqueService {
  static const String _endpoint =
      "https://overpass-api.de/api/interpreter";

  static Future<List<MosqueInfo>?> fetchNearby({
    required double latitude,
    required double longitude,
    double radiusMeters = 3000,
  }) async {
    final query = """
[out:json][timeout:25];
(
node["amenity"="place_of_worship"]["religion"="muslim"](around:$radiusMeters,$latitude,$longitude);
way["amenity"="place_of_worship"]["religion"="muslim"](around:$radiusMeters,$latitude,$longitude);
relation["amenity"="place_of_worship"]["religion"="muslim"](around:$radiusMeters,$latitude,$longitude);
);
out center;
""";

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          "User-Agent": "Aqim/1.0",
          "Accept": "application/json",
        },
        body: {"data": query},
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode != 200) {
        print(response.statusCode);
        print(response.body);
        return null;
      }

      final json = jsonDecode(response.body);

      final elements = json["elements"] as List?;

      if (elements == null) {
        return [];
      }

      List<MosqueInfo> mosques = [];

      for (final e in elements) {
        double? lat;
        double? lon;

        if (e["lat"] != null) {
          lat = (e["lat"] as num).toDouble();
          lon = (e["lon"] as num).toDouble();
        } else if (e["center"] != null) {
          lat = (e["center"]["lat"] as num).toDouble();
          lon = (e["center"]["lon"] as num).toDouble();
        }

        if (lat == null || lon == null) continue;

        final tags = e["tags"] ?? {};

        final distance = Geolocator.distanceBetween(
          latitude,
          longitude,
          lat,
          lon,
        );

        mosques.add(
          MosqueInfo(
            name: tags["name"] ?? "مسجد",
            latitude: lat,
            longitude: lon,
            distanceMeters: distance,
          ),
        );
      }

      mosques.sort(
        (a, b) => a.distanceMeters.compareTo(b.distanceMeters),
      );

      return mosques;
    } catch (e) {
      print(e);
      return null;
    }
  }
}
