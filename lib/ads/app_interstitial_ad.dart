import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_ids.dart';

/// Interstitial manager used only for explicit non-worship actions.
///
/// AQIM preloads in the background, retries failed loads with a short
/// backoff, and immediately starts preparing the next ad after dismissal.
/// There is intentionally no artificial 10-minute cooldown.
class AppInterstitialAd {
  static InterstitialAd? _ad;
  static bool _loading = false;
  static Timer? _retryTimer;

  static void preload() {
    if (_ad != null || _loading) return;
    _retryTimer?.cancel();
    _retryTimer = null;
    _loading = true;

    InterstitialAd.load(
      adUnitId: AdIds.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loading = false;
          _ad = ad;
          debugPrint('AQIM Interstitial preloaded');
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _ad = null;
              preload();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('AQIM Interstitial failed to show: $error');
              ad.dispose();
              _ad = null;
              _scheduleRetry();
            },
            onAdShowedFullScreenContent: (_) {
              debugPrint('AQIM Interstitial shown');
            },
          );
        },
        onAdFailedToLoad: (error) {
          _loading = false;
          _ad = null;
          debugPrint('AQIM Interstitial failed to load: $error');
          _scheduleRetry();
        },
      ),
    );
  }

  static void _scheduleRetry() {
    if (_ad != null || _loading || _retryTimer != null) return;
    _retryTimer = Timer(const Duration(seconds: 8), () {
      _retryTimer = null;
      preload();
    });
  }

  /// Attempts to show the preloaded interstitial and then runs the action.
  /// If no ad is ready, the action still runs immediately.
  static void showThen(VoidCallback action) {
    final ad = _ad;
    if (ad == null) {
      preload();
      action();
      return;
    }

    _ad = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (shownAd) {
        shownAd.dispose();
        preload();
        action();
      },
      onAdFailedToShowFullScreenContent: (shownAd, error) {
        debugPrint('AQIM Interstitial failed to show: $error');
        shownAd.dispose();
        _scheduleRetry();
        action();
      },
    );
    ad.show();
  }

  /// Shows the preloaded interstitial when available.
  static bool showIfReady() {
    final ad = _ad;
    if (ad == null) {
      preload();
      return false;
    }
    _ad = null;
    ad.show();
    return true;
  }

  static void dispose() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _ad?.dispose();
    _ad = null;
    _loading = false;
  }
}
