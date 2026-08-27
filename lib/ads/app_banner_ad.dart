import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'banner_ad_manager.dart';

/// Banner widget backed by the centralized BannerAdManager.
///
/// If no placement is supplied, a stable instance-specific placement is
/// generated. This keeps the existing screen code compatible while ensuring
/// two simultaneously mounted screens never try to display the same AdWidget.
class AppBannerAd extends StatefulWidget {
  final String? placement;

  const AppBannerAd({super.key, this.placement});

  @override
  State<AppBannerAd> createState() => _AppBannerAdState();
}

class _AppBannerAdState extends State<AppBannerAd> {
  static int _nextId = 0;

  late final String _placement;
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _placement = widget.placement ?? 'banner_${_nextId++}';
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;

    final ad = await BannerAdManager.instance.load(
      context: context,
      placement: _placement,
    );

    if (!mounted || ad == null) return;

    setState(() {
      _ad = ad;
      _loaded = true;
    });
  }

  @override
  void dispose() {
    BannerAdManager.instance.dispose(_placement);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();

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
