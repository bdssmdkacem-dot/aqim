import 'package:disable_battery_optimization/disable_battery_optimization.dart';

/// يتحقق من إعدادات توفير البطارية (العامة وإعدادات الشركة المصنّعة
/// الخاصة مثل Xiaomi/Huawei/Oppo) ويعرض حوارًا يوجّه المستخدم لتعطيلها،
/// كي تصل تذكيرات الصلاة فوقتها ولا يقتلها النظام فـ الخلفية.
class BatteryService {
  static Future<bool> isFullyExempted() async {
  try {
    return (await DisableBatteryOptimization
            .isAllBatteryOptimizationDisabled) ??
        false;
  } catch (_) {
    return true;
  }
}

  /// يفتح شاشات النظام المناسبة (استثناء عام + إعدادات الشركة المصنّعة
  /// إن وُجدت) بخطوتين متتاليتين.
  static void openSettings() {
    DisableBatteryOptimization.showDisableAllOptimizationsSettings(
      'فعّل التشغيل التلقائي',
      'اسمح لتطبيق أقم بالعمل فـ الخلفية كي تصلك تذكيرات الصلاة فوقتها',
      'إعدادات بطارية إضافية',
      'بعض الأجهزة (Xiaomi، Huawei، Oppo...) عندها إعداد بطارية خاص بها — عطّله لنفس السبب',
    );
  }
}
