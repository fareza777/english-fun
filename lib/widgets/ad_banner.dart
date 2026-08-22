import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_diagnostics.dart';
import '../services/ads_placement.dart';
import '../services/consent.dart';
import '../services/error_reporter.dart';
import '../services/monetization.dart';

/// The single adaptive banner owned by the app shell.
///
/// Only ever one live banner exists, and only while a hub screen is on top.
/// It is created on arrival and disposed on departure, which is what the
/// Ads SDK expects: an AdWidget leaving the tree destroys the ad's WebView,
/// so a BannerAd held past that point can never render again.
class PersistentAdBanner extends StatefulWidget {
  const PersistentAdBanner({super.key});

  @override
  State<PersistentAdBanner> createState() => _PersistentAdBannerState();
}

class _PersistentAdBannerState extends State<PersistentAdBanner>
    with WidgetsBindingObserver {
  late final Listenable _listenable = Listenable.merge([
    AdsPlacement.I,
    MonetizationService.I,
    ConsentService.I,
  ]);
  BannerAd? _banner;
  bool _loaded = false;
  bool _loading = false;
  int _failures = 0;
  int _lastWidth = 0;
  Timer? _retry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenable.addListener(_sync);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didChangeMetrics() {
    _onChanged(forceReloadIfWidthChanged: true);
  }

  void _sync() => _onChanged();

  void _onChanged({bool forceReloadIfWidthChanged = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Entitlement or consent revoked: the ad has to go.
      if (!_adsAllowed) {
        _tearDown();
        return;
      }

      // Off a hub screen the ad is disposed, not merely hidden.
      //
      // Unmounting an AdWidget destroys the underlying WebView, so a
      // BannerAd kept alive past that point is a zombie: the SDK logs
      // "The webview is destroyed. Ignoring action." on its next refresh and
      // the banner comes back blank. Releasing it here and requesting a new
      // one on the way back is what the SDK expects.
      if (!AdsPlacement.I.showHubBanner) {
        _tearDown();
        return;
      }

      final width = MediaQuery.sizeOf(context).width.truncate();
      if (forceReloadIfWidthChanged &&
          _banner != null &&
          (width - _lastWidth).abs() > 24) {
        _tearDown(notify: false);
      }
      // A fresh arrival on the hub is a fresh chance: clear a stale failure
      // streak so a temporary run of no-fill cannot disable ads for good.
      _failures = 0;
      if (_banner == null && !_loading) unawaited(_load());
    });
  }

  /// Ads are permitted at all (entitlement + consent + SDK ready).
  bool get _adsAllowed => !kIsWeb && MonetizationService.I.canShowAds;

  /// Ads may be *rendered* right now.
  bool get _canShow => _adsAllowed && AdsPlacement.I.showHubBanner;

  Future<void> _load() async {
    if (!mounted || _loading || _banner != null || !_canShow) return;
    _loading = true;
    final width = MediaQuery.sizeOf(context).width.truncate();
    _lastWidth = width;
    final size = await _adaptiveSize(width);
    if (!mounted || !_canShow) {
      _loading = false;
      return;
    }

    final banner = BannerAd(
      adUnitId: MonetizationService.bannerAdUnitId,
      size: size,
      request: MonetizationService.childAdRequest,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _loading = false;
          // If the child left the hub while this was in flight there is no
          // AdWidget to host it, so release it rather than keep a banner
          // whose WebView is about to be torn down.
          if (!mounted || !_canShow) {
            ad.dispose();
            return;
          }
          _failures = 0;
          setState(() {
            _banner = ad as BannerAd;
            _loaded = true;
          });
          AdsPlacement.I.setHubBannerReady(true);
          AdDiagnostics.I.markLoaded(AdDiagnostics.slotBanner);
        },
        onAdFailedToLoad: (ad, error) {
          // Only the request that failed dies here.
          //
          // A banner already on screen is deliberately left alone: AdMob
          // returns "no fill" (code 3) constantly for a young, child-directed
          // ad unit, and blanking the hub on every miss is exactly why the
          // ad seemed to vanish for good after a few minutes of play.
          ad.dispose();
          _loading = false;
          AdDiagnostics.I.markFailed(
            AdDiagnostics.slotBanner,
            error.code,
            error.message,
          );
          if (_banner == null) {
            _loaded = false;
            AdsPlacement.I.setHubBannerReady(false);
            if (mounted) setState(() {});
          }
          _scheduleRetry();
        },
      ),
    );
    try {
      await banner.load();
    } catch (error, stack) {
      _loading = false;
      banner.dispose();
      ErrorReporter.I.record(error, stack, context: 'PersistentAdBanner');
      _scheduleRetry();
    }
  }

  /// Backs off after a miss, but never gives up for the whole session.
  ///
  /// "No fill" is a temporary state of the ad network, not a permanent one,
  /// so the old hard stop after a handful of misses meant a quiet minute
  /// could cost every impression for the rest of the session. Retries slow
  /// down to one every few minutes instead of stopping.
  static const _maxRetryDelay = Duration(minutes: 4);

  void _scheduleRetry() {
    if (!_canShow) return;
    _failures++;
    _retry?.cancel();
    final backoff = Duration(seconds: 3 * (1 << (_failures - 1).clamp(0, 7)));
    final delay = backoff > _maxRetryDelay ? _maxRetryDelay : backoff;
    _retry = Timer(delay, () {
      if (mounted) unawaited(_load());
    });
  }

  void _tearDown({bool notify = true}) {
    _retry?.cancel();
    _retry = null;
    _banner?.dispose();
    _banner = null;
    _loaded = false;
    _loading = false;
    AdsPlacement.I.setHubBannerReady(false);
    if (notify && mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _listenable.removeListener(_sync);
    _retry?.cancel();
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_canShow || !_loaded || _banner == null) {
      return const SizedBox.shrink();
    }
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: _banner!.size.width.toDouble(),
          height: _banner!.size.height.toDouble(),
          child: AdWidget(ad: _banner!),
        ),
      ),
    );
  }
}

/// 300×250 on the result screen. Unmounted while games run, so it never
/// shares a live AdWidget with the hub banner.
class ResultMrecAd extends StatefulWidget {
  const ResultMrecAd({super.key});

  @override
  State<ResultMrecAd> createState() => _ResultMrecAdState();
}

class _ResultMrecAdState extends State<ResultMrecAd> {
  BannerAd? _banner;
  bool _loaded = false;
  Timer? _retry;
  int _failures = 0;

  @override
  void initState() {
    super.initState();
    MonetizationService.I.addListener(_onChanged);
    ConsentService.I.addListener(_onChanged);
    // Each result screen is a new widget, so the streak starts clean and a
    // bad run of no-fill can never disable the MREC permanently.
    _failures = 0;
    _onChanged();
  }

  void _onChanged() {
    if (!mounted || !MonetizationService.I.canShowAds || _banner != null) {
      return;
    }
    unawaited(_load());
  }

  Future<void> _load() async {
    if (!mounted || _banner != null || !MonetizationService.I.canShowAds) {
      return;
    }
    final banner = BannerAd(
      adUnitId: MonetizationService.mrecAdUnitId,
      size: AdSize.mediumRectangle,
      request: MonetizationService.childAdRequest,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          _failures = 0;
          setState(() {
            _banner = ad as BannerAd;
            _loaded = true;
          });
          AdDiagnostics.I.markLoaded(AdDiagnostics.slotMrec);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          AdDiagnostics.I.markFailed(
            AdDiagnostics.slotMrec,
            error.code,
            error.message,
          );
          if (mounted) setState(() => _banner = null);
          _scheduleRetry();
        },
      ),
    );
    _banner = banner;
    try {
      await banner.load();
    } catch (error, stack) {
      _banner = null;
      banner.dispose();
      ErrorReporter.I.record(error, stack, context: 'ResultMrecAd');
      _scheduleRetry();
    }
  }

  void _scheduleRetry() {
    if (!MonetizationService.I.canShowAds || _failures > 4) return;
    _failures++;
    _retry?.cancel();
    _retry = Timer(Duration(seconds: (4 * _failures).clamp(4, 20)), _onChanged);
  }

  @override
  void dispose() {
    MonetizationService.I.removeListener(_onChanged);
    ConsentService.I.removeListener(_onChanged);
    _retry?.cancel();
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !MonetizationService.I.canShowAds) {
      return const SizedBox.shrink();
    }
    if (!_loaded || _banner == null) return const SizedBox(height: 8);
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Center(
        child: SizedBox(
          width: _banner!.size.width.toDouble(),
          height: _banner!.size.height.toDouble(),
          child: AdWidget(ad: _banner!),
        ),
      ),
    );
  }
}

/// Anchored adaptive size for the current orientation.
///
/// Deliberately *not* the "large" variant: that one is allowed to take up to
/// ~15% of screen height (roughly 100dp on a tall phone), which swallowed a
/// big slice of the hub. The standard anchored size lands around 50-60dp,
/// which is what Google recommends for a bottom-anchored banner and leaves
/// the grade cards room to breathe.
Future<AdSize> _adaptiveSize(int width) async {
  if (width < 32) return AdSize.banner;
  try {
    // Standard anchored adaptive, not the "large" variant.
    //
    // Measured on a 392dp-wide phone: standard = 61dp tall, large = 123dp.
    // The large one ate roughly a sixth of the screen and pushed the grade
    // cards out of view, so the standard anchored size is the right trade
    // for a hub the child actually has to read.
    //
    // The Flutter wrapper marks this deprecated in favour of the large
    // variant, but it maps to the platform's long-standing
    // getCurrentOrientationAnchoredAdaptiveBannerAdSize, which is still the
    // documented choice for a bottom-anchored banner.
    final standard = await AdSize
        // ignore: deprecated_member_use
        .getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (standard != null && standard.height > 0) return standard;

    final large = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (large != null && large.height > 0) return large;
  } catch (_) {}
  return AdSize.banner;
}
