import 'package:geolocator/geolocator.dart';

/// يجلب إحداثيات الهاتف لحساب أوقات الصلاة الحقيقية. يرجع null بهدوء
/// (بدل رمي استثناء) في أي حالة فشل: خدمة الموقع مطفأة، أو الصلاحية
/// مرفوضة — التطبيق يستمر بالعمل بالأوقات الاحتياطية فهاذي الحالة.
class LocationService {
  static Future<Position?> getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (_) {
      return null;
    }
  }
}
