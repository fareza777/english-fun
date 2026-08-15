import 'package:flutter_test/flutter_test.dart';

import 'package:english_fun/services/monetization.dart';

void main() {
  group('AdsEntitlement', () {
    test('shows ads by default', () {
      final entitlement = AdsEntitlement();

      expect(entitlement.adsRemoved, isFalse);
      expect(entitlement.showAds, isTrue);
    });

    test('purchased removes ads', () {
      final entitlement = AdsEntitlement();

      entitlement.apply(AdsEntitlementEvent.purchased);

      expect(entitlement.adsRemoved, isTrue);
      expect(entitlement.showAds, isFalse);
    });

    test('restored purchase removes ads', () {
      final entitlement = AdsEntitlement();

      entitlement.apply(AdsEntitlementEvent.restored);

      expect(entitlement.showAds, isFalse);
    });

    test('pending, cancelled, and failed purchases keep ads visible', () {
      final entitlement = AdsEntitlement();

      for (final event in [
        AdsEntitlementEvent.pending,
        AdsEntitlementEvent.cancelled,
        AdsEntitlementEvent.failed,
      ]) {
        entitlement.apply(event);
      }

      expect(entitlement.adsRemoved, isFalse);
      expect(entitlement.showAds, isTrue);
    });

    test('entitlement cannot be turned back on accidentally', () {
      final entitlement = AdsEntitlement();

      entitlement.apply(AdsEntitlementEvent.purchased);
      entitlement.apply(AdsEntitlementEvent.failed);

      expect(entitlement.adsRemoved, isTrue);
    });
  });
}
