import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'banner_ad_manager.dart';

/// Banner placement widget backed by the centralized banner manager.
class AppBannerAd extends StatefulWidget {
  final String placement;

  const AppBannerAd({super.key, required this.placement});

  @override
  State<AppBannerAd> createState() => _AppBannerAdState();
}

class _AppBannerAdState extends State<AppBannerAd> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    final manager = BannerAdManager.instance;
    await manager.load(context: context, placement: widget.placement);
    if (!mounted) return;

    final current = manager.get(widget.placement);
    if (current != null) {
      setState(() {
        _ad = current;
        _loaded = true;
      });
    }
  }

  @override
  void dispose() {
    BannerAdManager.instance.dispose(widget.placement);
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
