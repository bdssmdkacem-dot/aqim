import 'package:disable_battery_optimization/disable_battery_optimization.dart';

/// يتحقق من إعدادات توفير البطارية (العامة وإعدادات الشركة المصنّعة
/// الخاصة مثل Xiaomi/Huawei/Oppo) ويعرض حوارًا يوجّه المستخدم لتعطيلها،
/// كي تصل تذكيرات الصلاة فوقتها ولا يقتلها النظام في الخلفية.
class BatteryService {
  /// يتحقق مما إذا كانت جميع قيود البطارية معطلة.
  static Future<bool> isFullyExempted() async {
    try {
      final result = await DisableBatteryOptimization
          .isAllBatteryOptimizationDisabled;

      return result ?? false;
    } catch (_) {
      // إذا لم يكن الجهاز يدعم هذه الميزة، فلا نمنع التطبيق من العمل.
      return true;
    }
  }

  /// يفتح إعدادات تعطيل تحسين البطارية وإعدادات الشركة المصنّعة إن وُجدت.
  static Future<void> openSettings() async {
    try {
      await DisableBatteryOptimization.showDisableAllOptimizationsSettings(
        'فعّل التشغيل التلقائي',
        'اسمح لتطبيق أقم بالعمل في الخلفية كي تصلك تذكيرات الصلاة في وقتها.',
        'إعدادات بطارية إضافية',
        'في بعض الأجهزة (Xiaomi، Huawei، Oppo...) توجد إعدادات بطارية إضافية، يُرجى تعطيلها لهذا التطبيق.',
      );
    } catch (_) {
      // تجاهل أي خطأ على الأجهزة غير المدعومة.
    }
  }
}
