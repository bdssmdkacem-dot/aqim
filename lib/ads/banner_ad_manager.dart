import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_ids.dart';

/// Central banner lifecycle manager.
///
/// Each placement has at most one active load and one loaded BannerAd.
/// Widgets use stable placement keys, preventing rebuilds from creating
/// duplicate BannerAd requests.
class BannerAdManager {
  BannerAdManager._();

  static final BannerAdManager instance = BannerAdManager._();

  final Map<String, BannerAd> _ads = <String, BannerAd>{};
  final Map<String, Future<BannerAd?>> _loads = <String, Future<BannerAd?>>{};

  BannerAd? get(String placement) => _ads[placement];

  Future<BannerAd?> load({
    required BuildContext context,
    required String placement,
  }) {
    final existing = _ads[placement];
    if (existing != null) return Future<BannerAd?>.value(existing);

    final pending = _loads[placement];
    if (pending != null) return pending;

    final future = _loadInternal(context: context, placement: placement);
    _loads[placement] = future;
    future.whenComplete(() => _loads.remove(placement));
    return future;
  }

  Future<BannerAd?> _loadInternal({
    required BuildContext context,
    required String placement,
  }) async {
    final width = MediaQuery.sizeOf(context).width.truncate();
    final adaptiveSize = await AdSize.getAnchoredAdaptiveBannerAdSize(
      Orientation.portrait,
      width,
    );

    if (!context.mounted) return null;

    final completer = Completer<BannerAd?>();
    final ad = BannerAd(
      adUnitId: AdIds.bannerAdUnitId,
      size: adaptiveSize ?? AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (loadedAd) {
          final banner = loadedAd as BannerAd;
          _ads[placement] = banner;
          debugPrint('AQIM_AD_BANNER_LOADED placement=$placement');
          if (!completer.isCompleted) completer.complete(banner);
        },
        onAdFailedToLoad: (failedAd, error) {
          failedAd.dispose();
          debugPrint('AQIM_AD_BANNER_FAILED placement=$placement error=$error');
          if (!completer.isCompleted) completer.complete(null);
        },
      ),
    );

    ad.load();
    return completer.future;
  }

  void dispose(String placement) {
    _ads.remove(placement)?.dispose();
  }

  void disposeAll() {
    for (final ad in _ads.values) {
      ad.dispose();
    }
    _ads.clear();
  }
}
