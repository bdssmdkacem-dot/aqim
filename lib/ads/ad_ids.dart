import 'dart:io';

/// معرّفات AdMob. القيم الحالية هي **معرّفات اختبار رسمية من Google**
/// (تعمل دائمًا وتُظهر إعلانات وهمية بلا أي عائد مالي حقيقي).
///
/// ⚠️ قبل نشر التطبيق على المتجر، استبدل:
/// 1. القيم أدناه بمعرّفات إعلاناتك الحقيقية من حساب AdMob الخاص بك.
/// 2. قيمة `com.google.android.gms.ads.APPLICATION_ID` في
///    android/app/src/main/AndroidManifest.xml بمعرّف تطبيقك الحقيقي.
///
/// لا حاجة لإخفاء هذه القيم أو معاملتها كسرّ — معرّفات الإعلانات ليست
/// حساسة، وتُضمَّن أصلًا داخل أي تطبيق منشور على المتجر.
class AdIds {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      // Test banner ad unit ID (Android) — استبدله بمعرّفك الحقيقي.
      return 'ca-app-pub-3940256099942544/6300978111';
    }
    // iOS test banner — للتوسّع المستقبلي إن أضفت منصة iOS.
    return 'ca-app-pub-3940256099942544/2934735716';
  }
}
