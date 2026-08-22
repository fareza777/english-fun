import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ad_diagnostics.dart';
import 'ads_placement.dart';
import 'ads_policy.dart';
import 'consent.dart';
import 'error_reporter.dart';

/// Events that can change the local no-ads entitlement.
enum AdsEntitlementEvent { purchased, restored, pending, cancelled, failed }

/// Small, deterministic entitlement model that is easy to test independently
/// from Google Play Billing and AdMob platform channels.
class AdsEntitlement {
  // Dart forbids named parameters that start with an underscore, so the
  // initializing formal this lint suggests is not actually expressible here.
  // ignore: prefer_initializing_formals
  AdsEntitlement({bool adsRemoved = false}) : _adsRemoved = adsRemoved;

  bool _adsRemoved;

  bool get adsRemoved => _adsRemoved;
  bool get showAds => !_adsRemoved;

  void apply(AdsEntitlementEvent event) {
    if (event == AdsEntitlementEvent.purchased || event == AdsEntitlementEvent.restored) {
      _adsRemoved = true;
    }
  }
}

/// Coordinates child-safe advertising and the one-time remove-ads product.
///
/// The AdMob and Play Billing calls are intentionally wrapped in defensive
/// fallbacks so the app remains usable offline and in Flutter tests.
class MonetizationService extends ChangeNotifier {
  MonetizationService({InAppPurchase? store}) : _store = store ?? InAppPurchase.instance;

  static final MonetizationService I = MonetizationService();

  static const removeAdsProductId = 'remove_ads';
  static const _prodBannerAdUnitId = String.fromEnvironment(
    'ADMOB_BANNER_AD_UNIT_ID',
    defaultValue: 'ca-app-pub-6279186647593327/6889227968',
  );
  static const _prodMrecAdUnitId = String.fromEnvironment(
    'ADMOB_MREC_AD_UNIT_ID',
    defaultValue: 'ca-app-pub-6279186647593327/5392592706',
  );
  static const _prodInterstitialAdUnitId = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_AD_UNIT_ID',
    defaultValue: 'ca-app-pub-6279186647593327/7051490430',
  );

  /// `--dart-define=ADMOB_TEST_UNITS=true` swaps every slot for Google's
  /// official always-fill demo units. Live fill on a brand-new child-directed
  /// unit can take days to ramp up, which looks exactly like "iklan tidak
  /// ada" to a closed tester — a test-units build proves the placement and
  /// rendering are correct independent of AdMob-side fill.
  static const useTestUnits = bool.fromEnvironment('ADMOB_TEST_UNITS');

  /// Google's public demo units (Android).
  static const _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const _testInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';

  static String get bannerAdUnitId =>
      useTestUnits ? _testBannerAdUnitId : _prodBannerAdUnitId;

  /// Dedicated 300x250 unit ("Result MREC") for the result screen.
  ///
  /// AdMob tunes fill and eCPM per ad unit using that unit's size history, so
  /// serving a medium rectangle from the anchored-banner unit leaves money on
  /// the table. Falls back to the banner unit only if the define overrides
  /// the default with an empty value.
  static String get mrecAdUnitId {
    if (useTestUnits) return _testBannerAdUnitId;
    return _prodMrecAdUnitId.isEmpty ? _prodBannerAdUnitId : _prodMrecAdUnitId;
  }

  /// Distinct Interstitial unit (banner units cannot serve full-screen ads).
  /// Override with `--dart-define=ADMOB_INTERSTITIAL_AD_UNIT_ID=ca-app-pub-…/…`
  /// after creating the unit in AdMob.
  static String get interstitialAdUnitId =>
      useTestUnits ? _testInterstitialAdUnitId : _prodInterstitialAdUnitId;

  /// Forced non-personalized request; the SDK is also child-directed in
  /// [_initAds]. Used by every banner, MREC, and interstitial load.
  static const childAdRequest = AdRequest(nonPersonalizedAds: true);

  /// Comma-separated AdMob test device ids, for verifying ad behaviour on a
  /// real handset without waiting on live fill.
  ///
  /// Empty in every shipping build. The device's own id is printed by the
  /// Ads SDK in logcat ("Use RequestConfiguration.Builder().setTestDeviceIds").
  /// `--dart-define=ADMOB_TEST_DEVICE_IDS=ABC123,DEF456`
  static const testDeviceIds = String.fromEnvironment('ADMOB_TEST_DEVICE_IDS');

  final InAppPurchase _store;
  final AdsEntitlement entitlement = AdsEntitlement();
  final InterstitialGate interstitialGate = InterstitialGate();
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  SharedPreferences? _prefs;
  ProductDetails? _removeAdsProduct;
  InterstitialAd? _interstitial;
  Timer? _interstitialRetry;
  bool _initialized = false;
  bool _adsAvailable = false;
  bool _storeAvailable = false;
  bool _loadingInterstitial = false;
  bool _showingInterstitial = false;
  int _interstitialFailures = 0;

  bool get initialized => _initialized;
  bool get adsRemoved => entitlement.adsRemoved;
  bool get canShowAds =>
      !kIsWeb && _adsAvailable && entitlement.showAds && ConsentService.I.canRequestAds;
  bool get storeAvailable => _storeAvailable;
  String get removeAdsPrice => _removeAdsProduct?.price ?? r'$4.99';

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      _prefs = await SharedPreferences.getInstance();
      entitlement._adsRemoved = _prefs?.getBool('ads_removed') ?? false;
      final shownAt = _prefs?.getInt('interstitial_shown_at') ?? 0;
      if (shownAt > 0) {
        interstitialGate.lastShownAt =
            DateTime.fromMillisecondsSinceEpoch(shownAt);
      }
      interstitialGate.gamesAtLastShow =
          _prefs?.getInt('interstitial_games_at_show') ?? 0;
    } catch (_) {
      _prefs = null;
    }

    if (!kIsWeb) {
      await _initAds();
      await _initStore();
      if (canShowAds) preloadInterstitial();
    }
    notifyListeners();
  }

  Future<void> _initAds() async {
    try {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          maxAdContentRating: MaxAdContentRating.g,
          ageRestrictedTreatment: AgeRestrictedTreatment.child,
          testDeviceIds: testDeviceIds.isEmpty
              ? null
              : testDeviceIds.split(',').map((id) => id.trim()).toList(),
        ),
      );
      await MobileAds.instance.initialize();
      _adsAvailable = true;
      AdDiagnostics.I.markSdkReady();
      AdsPlacement.I.addListener(_onPlacementChanged);
    } catch (error, stack) {
      // Never swallow this one silently: a failed SDK init means zero ads for
      // the whole session, and "gak ada iklannya" is undebuggable without it.
      _adsAvailable = false;
      AdDiagnostics.I.markSdkInitFailed();
      ErrorReporter.I.record(error, stack, context: 'MonetizationService.initAds');
    }
  }

  void _onPlacementChanged() {
    if (AdsPlacement.I.surface == AdSurface.hidden) {
      preloadInterstitial();
    }
  }

  Future<void> _initStore() async {
    try {
      _purchaseSubscription = _store.purchaseStream.listen(_handlePurchases);
      _storeAvailable = await _store.isAvailable();
      if (!_storeAvailable) return;
      final response = await _store.queryProductDetails({removeAdsProductId});
      if (response.productDetails.isNotEmpty) {
        _removeAdsProduct = response.productDetails.firstWhere(
          (product) => product.id == removeAdsProductId,
          orElse: () => response.productDetails.first,
        );
      }
    } catch (_) {
      _storeAvailable = false;
    }
  }

  Future<bool> buyRemoveAds() async {
    final product = _removeAdsProduct;
    if (!_storeAvailable || product == null || entitlement.adsRemoved) return false;
    try {
      return await _store.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> restorePurchases() async {
    if (!_storeAvailable) return;
    try {
      await _store.restorePurchases();
    } catch (_) {}
  }

  void _handlePurchases(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.productID != removeAdsProductId) continue;
      switch (purchase.status) {
        case PurchaseStatus.purchased:
          _applyEntitlement(AdsEntitlementEvent.purchased);
        case PurchaseStatus.restored:
          _applyEntitlement(AdsEntitlementEvent.restored);
        case PurchaseStatus.pending:
          _applyEntitlement(AdsEntitlementEvent.pending);
        case PurchaseStatus.canceled:
          _applyEntitlement(AdsEntitlementEvent.cancelled);
        case PurchaseStatus.error:
          _applyEntitlement(AdsEntitlementEvent.failed);
      }
      if (purchase.pendingCompletePurchase) {
        unawaited(_store.completePurchase(purchase));
      }
    }
  }

  void _applyEntitlement(AdsEntitlementEvent event) {
    final before = entitlement.adsRemoved;
    entitlement.apply(event);
    if (!before && entitlement.adsRemoved) {
      final prefs = _prefs;
      if (prefs != null) unawaited(prefs.setBool('ads_removed', true).then((_) {}));
      _disposeInterstitial();
      notifyListeners();
    }
  }

  /// Warm a full-screen ad in the background while the child is playing.
  void preloadInterstitial() {
    if (!canShowAds || _interstitial != null || _loadingInterstitial) return;
    if (interstitialAdUnitId.isEmpty) return;
    _loadingInterstitial = true;
    unawaited(
      InterstitialAd.load(
        adUnitId: interstitialAdUnitId,
        request: childAdRequest,
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitial = ad;
            _loadingInterstitial = false;
            _interstitialFailures = 0;
            AdDiagnostics.I.markLoaded(AdDiagnostics.slotInterstitial);
          },
          onAdFailedToLoad: (error) {
            _loadingInterstitial = false;
            _interstitial = null;
            _interstitialFailures++;
            AdDiagnostics.I.markFailed(
              AdDiagnostics.slotInterstitial,
              error.code,
              error.message,
            );
            _scheduleInterstitialRetry();
          },
        ),
      ),
    );
  }

  /// Shows a capped interstitial when the child leaves a result screen.
  /// Returns immediately if the gate is closed or no ad is ready — never
  /// blocks navigation on a load.
  Future<void> showInterstitialIfEligible({required int gamesTotal}) async {
    if (_showingInterstitial) return;
    final allowed = canShowAds;
    final ready = _interstitial != null;
    if (!interstitialGate.canShow(
      gamesTotal: gamesTotal,
      now: DateTime.now(),
      allowed: allowed,
      ready: ready,
    )) {
      if (allowed && !ready) preloadInterstitial();
      return;
    }

    final ad = _interstitial;
    _interstitial = null;
    if (ad == null) return;

    _showingInterstitial = true;
    final done = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdDismissedFullScreenContent: (shown) {
        shown.dispose();
        _onInterstitialClosed(gamesTotal: gamesTotal, shown: true);
        if (!done.isCompleted) done.complete();
      },
      onAdFailedToShowFullScreenContent: (shown, error) {
        shown.dispose();
        ErrorReporter.I.record(
          'Interstitial failed to show: ${error.message}',
          StackTrace.current,
          context: 'MonetizationService.interstitial',
        );
        _onInterstitialClosed(gamesTotal: gamesTotal, shown: false);
        if (!done.isCompleted) done.complete();
      },
    );

    try {
      await ad.show();
      await done.future.timeout(
        const Duration(seconds: 45),
        onTimeout: () {},
      );
    } catch (error, stack) {
      ad.dispose();
      ErrorReporter.I.record(error, stack, context: 'MonetizationService.interstitial');
      _onInterstitialClosed(gamesTotal: gamesTotal, shown: false);
      if (!done.isCompleted) done.complete();
    } finally {
      if (_showingInterstitial) {
        _showingInterstitial = false;
        preloadInterstitial();
      }
    }
  }

  void _onInterstitialClosed({required int gamesTotal, required bool shown}) {
    _showingInterstitial = false;
    if (shown) {
      interstitialGate.markShown(now: DateTime.now(), gamesTotal: gamesTotal);
      final prefs = _prefs;
      if (prefs != null) {
        unawaited(
          prefs.setInt(
            'interstitial_shown_at',
            interstitialGate.lastShownAt!.millisecondsSinceEpoch,
          ),
        );
        unawaited(prefs.setInt('interstitial_games_at_show', gamesTotal));
      }
    }
    preloadInterstitial();
  }

  void _scheduleInterstitialRetry() {
    if (!canShowAds || _interstitialFailures > 5) return;
    _interstitialRetry?.cancel();
    final seconds = (3 * (1 << (_interstitialFailures - 1).clamp(0, 4))).clamp(3, 48);
    _interstitialRetry = Timer(Duration(seconds: seconds), preloadInterstitial);
  }

  void _disposeInterstitial() {
    _interstitialRetry?.cancel();
    _interstitialRetry = null;
    _interstitial?.dispose();
    _interstitial = null;
    _loadingInterstitial = false;
    _showingInterstitial = false;
  }

  @override
  void dispose() {
    AdsPlacement.I.removeListener(_onPlacementChanged);
    _disposeInterstitial();
    unawaited(_purchaseSubscription?.cancel() ?? Future<void>.value());
    super.dispose();
  }
}
