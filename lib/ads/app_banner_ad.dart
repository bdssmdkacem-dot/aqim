import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_ids.dart';

/// Banner ad used only on general-purpose screens such as Home and the
/// weekly Life Board. It is intentionally not used in prayer, Quran or
/// Adhkar flows.
class AppBannerAd extends StatefulWidget {
  const AppBannerAd({super.key});

  @override
  State<AppBannerAd> createState() => _AppBannerAdState();
}

class _AppBannerAdState extends State<AppBannerAd> {
  BannerAd? _bannerAd;
  bool _loaded = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAd());
  }

  Future<void> _loadAd() async {
    if (!mounted || _loading) return;
    _loading = true;

    final width = MediaQuery.sizeOf(context).width.truncate();
    final adaptiveSize = await AdSize.getAnchoredAdaptiveBannerAdSize(
      Orientation.portrait,
      width,
    );

    if (!mounted) {
      _loading = false;
      return;
    }

    final size = adaptiveSize ?? AdSize.banner;
    final oldAd = _bannerAd;
    _bannerAd = null;
    _loaded = false;
    oldAd?.dispose();

    final ad = BannerAd(
      adUnitId: AdIds.bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          _bannerAd = ad as BannerAd;
          _loading = false;
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _loading = false;
          debugPrint('AQIM BannerAd failed to load: $error');
          if (mounted) setState(() => _loaded = false);
        },
      ),
    );

    _bannerAd = ad;
    ad.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _bannerAd == null) return const SizedBox.shrink();

    final ad = _bannerAd!;
    return SafeArea(
      top: false,
      child: SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
