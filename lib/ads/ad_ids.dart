import 'dart:io';

/// AdMob identifiers for Aqim.
class AdIds {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-1377346158677931/7344891091';
    }
    return 'ca-app-pub-3940256099942544/2934735716';
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      // Aqim production interstitial ad unit.
      return 'ca-app-pub-1377346158677931/6832048914';
    }
    // Google official iOS test interstitial ID.
    return 'ca-app-pub-3940256099942544/4411468910';
  }
}
