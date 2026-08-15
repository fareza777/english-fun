import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Events that can change the local no-ads entitlement.
enum AdsEntitlementEvent { purchased, restored, pending, cancelled, failed }

/// Small, deterministic entitlement model that is easy to test independently
/// from Google Play Billing and AdMob platform channels.
class AdsEntitlement {
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
  static const bannerAdUnitId = String.fromEnvironment(
    'ADMOB_BANNER_AD_UNIT_ID',
    defaultValue: 'ca-app-pub-6279186647593327/6889227968',
  );

  final InAppPurchase _store;
  final AdsEntitlement entitlement = AdsEntitlement();
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  SharedPreferences? _prefs;
  ProductDetails? _removeAdsProduct;
  bool _initialized = false;
  bool _adsAvailable = false;
  bool _storeAvailable = false;

  bool get initialized => _initialized;
  bool get adsRemoved => entitlement.adsRemoved;
  bool get canShowAds => !kIsWeb && _adsAvailable && entitlement.showAds;
  bool get storeAvailable => _storeAvailable;
  String get removeAdsPrice => _removeAdsProduct?.price ?? r'$4.99';

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      _prefs = await SharedPreferences.getInstance();
      entitlement._adsRemoved = _prefs?.getBool('ads_removed') ?? false;
    } catch (_) {
      _prefs = null;
    }

    if (!kIsWeb) {
      await _initAds();
      await _initStore();
    }
    notifyListeners();
  }

  Future<void> _initAds() async {
    try {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          maxAdContentRating: MaxAdContentRating.g,
          ageRestrictedTreatment: AgeRestrictedTreatment.child,
        ),
      );
      await MobileAds.instance.initialize();
      _adsAvailable = true;
    } catch (_) {
      _adsAvailable = false;
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
      notifyListeners();
    }
  }

  @override
  void dispose() {
    unawaited(_purchaseSubscription?.cancel() ?? Future<void>.value());
    super.dispose();
  }
}
