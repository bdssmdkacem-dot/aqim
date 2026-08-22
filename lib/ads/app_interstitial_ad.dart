import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_ids.dart';

/// Interstitial manager for non-worship transitions only.
///
/// The ad is never shown automatically. Call showIfEligible() only from a
/// user action such as opening the weekly report. There is no artificial
/// 10-minute cooldown: each user action may show the currently preloaded ad.
class AppInterstitialAd {
  static InterstitialAd? _ad;
  static bool _loading = false;

  static void preload() {
    if (_ad != null || _loading) return;
    _loading = true;

    InterstitialAd.load(
      adUnitId: AdIds.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loading = false;
          _ad = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _ad = null;
              preload();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Interstitial failed to show: $error');
              ad.dispose();
              _ad = null;
              preload();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _loading = false;
          _ad = null;
          debugPrint('Interstitial failed to load: $error');
        },
      ),
    );
  }

  /// Shows the preloaded interstitial when available, then prepares another
  /// one. No 10-minute cooldown is applied.
  static void showIfEligible() {
    final ad = _ad;
    if (ad == null) {
      preload();
      return;
    }

    _ad = null;
    ad.show();
    preload();
  }
}
