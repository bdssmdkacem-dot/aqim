import 'dart:io';

/// معرّفات AdMob.
///
/// البانر الحالي يستخدم معرّف AdMob الخاص بالتطبيق على Android.
/// الـInterstitial يستخدم معرّفات الاختبار الرسمية من Google إلى أن يتم
/// استبدالها بمعرّف وحدة الإعلان الحقيقي الخاص بالتطبيق قبل النشر.
class AdIds {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-1377346158677931/7344891091';
    }
    return 'ca-app-pub-3940256099942544/2934735716';
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      // Google official test interstitial ID.
      return 'ca-app-pub-3940256099942544/1033173712';
    }
    // Google official iOS test interstitial ID.
    return 'ca-app-pub-3940256099942544/4411468910';
  }
}
