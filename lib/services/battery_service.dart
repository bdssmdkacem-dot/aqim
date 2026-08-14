import 'package:disable_battery_optimization/disable_battery_optimization.dart';

/// Handles Android battery/background restrictions so scheduled prayer
/// reminders are less likely to be delayed by Doze or OEM restrictions.
class BatteryService {
  static Future<bool> isFullyExempted() async {
    try {
      final result =
          await DisableBatteryOptimization.isAllBatteryOptimizationDisabled;
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens the package's combined battery-optimization flow.
  ///
  /// The caller should re-check [isFullyExempted] after the user returns
  /// instead of assuming that opening Settings means permission was granted.
  static Future<void> openSettings() async {
    await DisableBatteryOptimization.showDisableAllOptimizationsSettings(
      'فعّل التشغيل التلقائي',
      'اسمح لتطبيق أقم بالعمل في الخلفية كي تصلك تذكيرات الصلاة في وقتها',
      'إعدادات بطارية إضافية',
      'بعض الأجهزة مثل Xiaomi وHuawei وOppo لديها إعدادات بطارية خاصة. عطّل التقييد لأقم حتى تعمل التذكيرات بشكل موثوق.',
    );
  }

  /// Opens the native Android battery optimization request directly.
  static Future<void> requestNativeExemption() async {
    await DisableBatteryOptimization.showDisableBatteryOptimizationSettings();
  }

  /// Opens manufacturer-specific instructions when available.
  static Future<void> openManufacturerSettings() async {
    await DisableBatteryOptimization
        .showDisableManufacturerBatteryOptimizationSettings(
      'إعدادات بطارية إضافية',
      'قد يحتاج هاتفك إلى السماح لأقم بالعمل تلقائيًا في الخلفية.',
    );
  }

  /// Opens the OEM auto-start instructions when the device supports them.
  static Future<void> openAutoStartSettings() async {
    await DisableBatteryOptimization.showEnableAutoStartSettings(
      'فعّل التشغيل التلقائي',
      'اسمح لتطبيق أقم بالبدء تلقائيًا حتى تبقى تذكيرات الصلاة فعّالة.',
    );
  }
}
