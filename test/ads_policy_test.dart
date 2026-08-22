import 'package:english_fun/services/ads_placement.dart';
import 'package:english_fun/services/ads_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdsPolicy.surfaceFor', () {
    test('maps hub screens to the persistent banner', () {
      for (final name in [
        'HomeScreen',
        'UnitsScreen',
        'ArcadeScreen',
        'ShopScreen',
        'StickerBookScreen',
        'PetsScreen',
        'SpinScreen',
      ]) {
        expect(AdsPolicy.surfaceFor(name), AdSurface.hub, reason: name);
      }
    });

    test('maps the result screen to the medium-rectangle surface', () {
      expect(AdsPolicy.surfaceFor('ResultScreen'), AdSurface.result);
    });

    test('hides ads on gameplay, parents, and unknown routes', () {
      for (final name in [
        null,
        '',
        '/',
        'SplashScreen',
        'OnboardingScreen',
        'LearnScreen',
        'QuizScreen',
        'SpeakScreen',
        'BalloonScreen',
        'ParentsScreen',
        'PrivacyScreen',
        'DiagnosticsScreen',
        'SomeFutureScreen',
      ]) {
        expect(AdsPolicy.surfaceFor(name), AdSurface.hidden, reason: '$name');
      }
    });
  });

  group('InterstitialGate', () {
    final now = DateTime(2026, 8, 22, 11, 0);

    InterstitialGate gate() => InterstitialGate();

    test('does not show before two completed sessions', () {
      expect(
        gate().canShow(
          gamesTotal: 1,
          now: now,
          allowed: true,
          ready: true,
        ),
        isFalse,
      );
    });

    test('shows on the second session when the ad is ready', () {
      expect(
        gate().canShow(
          gamesTotal: 2,
          now: now,
          allowed: true,
          ready: true,
        ),
        isTrue,
      );
    });

    test('does not show when ads are removed or the ad is not loaded', () {
      expect(
        gate().canShow(
          gamesTotal: 8,
          now: now,
          allowed: false,
          ready: true,
        ),
        isFalse,
      );
      expect(
        gate().canShow(
          gamesTotal: 8,
          now: now,
          allowed: true,
          ready: false,
        ),
        isFalse,
      );
    });

    test('blocks another interstitial until two more games and three minutes pass', () {
      final g = gate()
        ..markShown(now: now, gamesTotal: 2);

      expect(
        g.canShow(gamesTotal: 3, now: now.add(const Duration(minutes: 4)), allowed: true, ready: true),
        isFalse,
        reason: 'only one extra game',
      );
      expect(
        g.canShow(gamesTotal: 4, now: now.add(const Duration(minutes: 2)), allowed: true, ready: true),
        isFalse,
        reason: 'cooldown still running',
      );
      expect(
        g.canShow(gamesTotal: 4, now: now.add(const Duration(minutes: 3)), allowed: true, ready: true),
        isTrue,
      );
    });
  });

  group('AdsPolicy.routeNameFor', () {
    test('uses the widget runtime type as the route name', () {
      expect(AdsPolicy.routeNameFor(const _NamedProbe()), '_NamedProbe');
    });
  });

  group('AdsPlacement', () {
    setUp(AdsPlacement.I.resetForTest);

    test('ignores unnamed routes so sheets do not hide the hub banner', () {
      AdsPlacement.I.applyRouteName('HomeScreen');
      expect(AdsPlacement.I.surface, AdSurface.hub);

      AdsPlacement.I.applyRouteName(null);
      AdsPlacement.I.applyRouteName('');

      expect(AdsPlacement.I.surface, AdSurface.hub);
    });

    test('treats the splash route as hidden and clears a ready banner', () {
      AdsPlacement.I.applyRouteName('HomeScreen');
      AdsPlacement.I.setHubBannerReady(true);
      AdsPlacement.I.applyRouteName('/');

      expect(AdsPlacement.I.surface, AdSurface.hidden);
      expect(AdsPlacement.I.hubBannerReady, isFalse);
      expect(AdsPlacement.I.showHubBanner, isFalse);
    });

    test('a full game round trip lands back on the hub surface', () {
      // Regression: the banner used to be destroyed on the way into a game
      // and re-requested on the way out. Repeating that a handful of times
      // exhausted fill and the child was left with no ad at all, so the
      // round trip has to end in a state the banner can simply re-render
      // from rather than reload.
      AdsPlacement.I.applyRouteName('HomeScreen');
      AdsPlacement.I.setHubBannerReady(true);

      for (final route in ['UnitsScreen', 'QuizScreen', 'ResultScreen']) {
        AdsPlacement.I.applyRouteName(route);
      }
      expect(AdsPlacement.I.surface, AdSurface.result);
      expect(AdsPlacement.I.showHubBanner, isFalse,
          reason: 'the hub banner must not render over a game or result');

      AdsPlacement.I.applyRouteName('HomeScreen');
      expect(AdsPlacement.I.surface, AdSurface.hub);
      expect(AdsPlacement.I.showHubBanner, isTrue);
    });

    test('hub-to-hub navigation never drops the banner', () {
      // Moving between hub screens must not interrupt rendering at all,
      // otherwise the ad flickers on every tap around the menus.
      AdsPlacement.I.applyRouteName('HomeScreen');
      AdsPlacement.I.setHubBannerReady(true);

      for (final route in ['UnitsScreen', 'ShopScreen', 'PetsScreen']) {
        AdsPlacement.I.applyRouteName(route);
        expect(AdsPlacement.I.showHubBanner, isTrue, reason: route);
        expect(AdsPlacement.I.hubBannerReady, isTrue, reason: route);
      }
    });
  });
}

class _NamedProbe {
  const _NamedProbe();
}
