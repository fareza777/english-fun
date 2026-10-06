import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_diagnostics.dart';
import '../services/ads_placement.dart';
import '../services/ads_policy.dart';
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
  int _lastWidth = 0;
  Timer? _retry;
  Timer? _loadWatchdog;
  int _loadId = 0;
  int _syncGen = 0;
  final HubBannerLoadGate _gate = HubBannerLoadGate();
  final HubBannerRetryPolicy _retryPolicy = HubBannerRetryPolicy();

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
    final gen = ++_syncGen;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || gen != _syncGen) return;

      if (forceReloadIfWidthChanged &&
          _banner != null &&
          AdsPlacement.I.showHubBanner) {
        final width = MediaQuery.sizeOf(context).width.truncate();
        if ((width - _lastWidth).abs() > 24) {
          _tearDown(notify: false);
          _gate.reset();
        }
      }

      final action = _gate.decide(
        adsAllowed: _adsAllowed,
        isHub: AdsPlacement.I.showHubBanner,
        hasBanner: _banner != null,
        loading: _loading,
      );
      switch (action) {
        case HubBannerAction.tearDown:
          _tearDown();
        case HubBannerAction.load:
          unawaited(_load());
        case HubBannerAction.none:
          break;
      }
    });
  }

  /// Ads are permitted at all (entitlement + consent + SDK ready).
  bool get _adsAllowed => !kIsWeb && MonetizationService.I.canShowAds;

  /// Ads may be *rendered* right now.
  bool get _canShow => _adsAllowed && AdsPlacement.I.showHubBanner;

  Future<void> _load() async {
    if (!mounted || _loading || _banner != null || !_canShow) return;
    _loading = true;
    final id = ++_loadId;
    // Let a result-screen MREC finish disposing before we ask for the hub
    // banner again. Requesting both in the same beat is a common no-fill.
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted || id != _loadId || !_canShow) {
      if (id == _loadId) _loading = false;
      return;
    }
    final width = MediaQuery.sizeOf(context).width.truncate();
    _lastWidth = width;
    final size = await _adaptiveSize(width);
    if (!mounted || id != _loadId || !_canShow) {
      if (id == _loadId) _loading = false;
      return;
    }

    final banner = BannerAd(
      adUnitId: MonetizationService.bannerAdUnitId,
      size: size,
      request: MonetizationService.childAdRequest,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (id != _loadId) {
            ad.dispose();
            return;
          }
          _loadWatchdog?.cancel();
          _loading = false;
          if (!mounted || !_canShow) {
            ad.dispose();
            return;
          }
          _retryPolicy.reset();
          setState(() {
            _banner = ad as BannerAd;
            _loaded = true;
          });
          AdsPlacement.I.setHubBannerReady(true);
          AdDiagnostics.I.markLoaded(AdDiagnostics.slotBanner);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (id != _loadId) return;
          _loadWatchdog?.cancel();
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
    _loadWatchdog?.cancel();
    _loadWatchdog = Timer(const Duration(seconds: 12), () {
      if (id != _loadId || !_loading || _banner != null) return;
      _loading = false;
      _scheduleRetry();
    });
    try {
      await banner.load();
    } catch (error, stack) {
      if (id != _loadId) {
        banner.dispose();
        return;
      }
      _loadWatchdog?.cancel();
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
  void _scheduleRetry() {
    if (!_canShow) return;
    _retry?.cancel();
    final delay = _retryPolicy.recordFailure();
    _retry = Timer(delay, () {
      if (mounted) unawaited(_load());
    });
  }

  void _tearDown({bool notify = true}) {
    _loadId++;
    _retry?.cancel();
    _retry = null;
    _loadWatchdog?.cancel();
    _loadWatchdog = null;
    _banner?.dispose();
    _banner = null;
    _loaded = false;
    _loading = false;
    _retryPolicy.reset();
    AdsPlacement.I.setHubBannerReady(false);
    if (notify && mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _listenable.removeListener(_sync);
    _retry?.cancel();
    _loadWatchdog?.cancel();
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
    final standard =
        await AdSize
        // ignore: deprecated_member_use
        .getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (standard != null && standard.height > 0) return standard;

    final large = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (large != null && large.height > 0) return large;
  } catch (_) {}
  return AdSize.banner;
}
