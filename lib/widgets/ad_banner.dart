import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/monetization.dart';

/// A small, non-disruptive banner shown only on the home screen.
/// MonetizationService applies the child-directed, non-personalized request
/// configuration before any ad is loaded.
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _banner;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    MonetizationService.I.addListener(_onMonetizationChanged);
    _onMonetizationChanged();
  }

  void _onMonetizationChanged() {
    if (!mounted || !MonetizationService.I.canShowAds || _banner != null) return;
    _banner = BannerAd(
      adUnitId: MonetizationService.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (mounted) setState(() => _banner = null);
        },
      ),
    )..load();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    MonetizationService.I.removeListener(_onMonetizationChanged);
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !MonetizationService.I.canShowAds) return const SizedBox.shrink();
    if (!_loaded || _banner == null) return const SizedBox(height: 8);
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      color: Colors.white.withValues(alpha: 0.75),
      child: SizedBox(
        width: _banner!.size.width.toDouble(),
        height: _banner!.size.height.toDouble(),
        child: AdWidget(ad: _banner!),
      ),
    );
  }
}
