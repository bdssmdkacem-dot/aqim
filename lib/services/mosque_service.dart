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
  // Keep multiple public Overpass instances so a single unavailable server
  // does not make the nearby-mosques feature fail.
  static const List<String> _endpoints = [
    "https://overpass-api.de/api/interpreter",
    "https://overpass.kumi.systems/api/interpreter",
  ];

  static Future<List<MosqueInfo>?> fetchNearby({
    required double latitude,
    required double longitude,
    double radiusMeters = 3000,
  }) async {
    final query = """
[out:json][timeout:20];
(
  nwr["amenity"="place_of_worship"]["religion"="muslim"](around:$radiusMeters,$latitude,$longitude);
  nwr["amenity"="mosque"](around:$radiusMeters,$latitude,$longitude);
  nwr["building"="mosque"](around:$radiusMeters,$latitude,$longitude);
);
out center;
""";

    for (final endpoint in _endpoints) {
      try {
        final response = await http
            .post(
              Uri.parse(endpoint),
              headers: {
                "User-Agent": "Aqim/1.0",
                "Accept": "application/json",
              },
              body: {"data": query},
            )
            .timeout(const Duration(seconds: 25));

        if (response.statusCode != 200) continue;

        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) continue;

        final elements = decoded["elements"];
        if (elements is! List) continue;

        final mosques = <MosqueInfo>[];
        final seen = <String>{};

        for (final element in elements) {
          if (element is! Map) continue;

          final coordinates = element["center"] is Map
              ? element["center"] as Map
              : element;
          final rawLatitude = coordinates["lat"];
          final rawLongitude = coordinates["lon"];
          if (rawLatitude is! num || rawLongitude is! num) continue;

          final mosqueLatitude = rawLatitude.toDouble();
          final mosqueLongitude = rawLongitude.toDouble();
          final distance = Geolocator.distanceBetween(
            latitude,
            longitude,
            mosqueLatitude,
            mosqueLongitude,
          );
          final id = element["id"]?.toString();
          final type = element["type"]?.toString() ?? "element";
          if (id != null && !seen.add("$type:$id")) continue;

          final tags = element["tags"];
          final rawName = tags is Map ? tags["name"] : null;
          final name = rawName is String && rawName.trim().isNotEmpty
              ? rawName.trim()
              : "مسجد";

          mosques.add(
            MosqueInfo(
              name: name,
              latitude: mosqueLatitude,
              longitude: mosqueLongitude,
              distanceMeters: distance,
            ),
          );
        }

        mosques.sort(
          (a, b) => a.distanceMeters.compareTo(b.distanceMeters),
        );
        return mosques;
      } catch (_) {
        // Try the next Overpass instance before reporting a network failure.
      }
    }

    return null;
  }
}
