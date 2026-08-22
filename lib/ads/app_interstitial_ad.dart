import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_ids.dart';

/// Lightweight interstitial manager for non-worship transitions only.
///
/// It is intentionally throttled so ads never appear on the Quran, Adhkar,
/// prayer, Qibla, or prayer-guide screens.
class AppInterstitialAd {
  static InterstitialAd? _ad;
  static DateTime? _lastShown;
  static bool _loading = false;

  static const Duration _cooldown = Duration(minutes: 10);

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

  /// Shows at most once every 10 minutes and only when explicitly requested
  /// by a safe, non-worship transition.
  static void showIfEligible() {
    final ad = _ad;
    if (ad == null) {
      preload();
      return;
    }

    final now = DateTime.now();
    if (_lastShown != null && now.difference(_lastShown!) < _cooldown) {
      return;
    }

    _lastShown = now;
    _ad = null;
    ad.show();
  }
}
