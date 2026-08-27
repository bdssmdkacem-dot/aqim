import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_ids.dart';

/// Central banner lifecycle manager.
///
/// Each visible placement gets one BannerAd instance. Screens never create
/// BannerAd objects directly; this manager owns loading, failure handling and
/// disposal so rebuilds cannot accidentally generate duplicate requests.
class BannerAdManager {
  BannerAdManager._();

  static final BannerAdManager instance = BannerAdManager._();

  final Map<String, BannerAd> _ads = <String, BannerAd>{};
  final Set<String> _loading = <String>{};

  BannerAd? get(String placement) => _ads[placement];

  Future<BannerAd?> load({required BuildContext context, required String placement}) async {
    if (_ads.containsKey(placement) || _loading.contains(placement)) {
      return _ads[placement];
    }

    _loading.add(placement);
    try {
      final width = MediaQuery.sizeOf(context).width.truncate();
      final adaptiveSize = await AdSize.getAnchoredAdaptiveBannerAdSize(
        Orientation.portrait,
        width,
      );

      if (!context.mounted) return null;

      final ad = BannerAd(
        adUnitId: AdIds.bannerAdUnitId,
        size: adaptiveSize ?? AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            _ads[placement] = ad as BannerAd;
            debugPrint('AQIM Banner loaded: $placement');
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            _ads.remove(placement);
            debugPrint('AQIM Banner failed [$placement]: $error');
          },
        ),
      );

      _ads[placement] = ad;
      ad.load();
      return ad;
    } finally {
      _loading.remove(placement);
    }
  }

  void dispose(String placement) {
    _ads.remove(placement)?.dispose();
    _loading.remove(placement);
  }

  void disposeAll() {
    for (final ad in _ads.values) {
      ad.dispose();
    }
    _ads.clear();
    _loading.clear();
  }
}
