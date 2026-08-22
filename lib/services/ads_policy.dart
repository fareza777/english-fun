/// Where a route is allowed to show ads. Unknown routes fail closed (hidden)
/// so a new game screen can never accidentally host a banner.
enum AdSurface {
  /// Splash, onboarding, games, learn, parents, privacy.
  hidden,

  /// Hub screens that share one persistent adaptive banner.
  hub,

  /// Post-game celebration: medium rectangle, plus an optional interstitial
  /// when the child leaves — never during play.
  result,
}

/// Child-safe placement and frequency rules. Pure Dart so it can be tested
/// without AdMob platform channels.
class AdsPolicy {
  static const hubRoutes = {
    'HomeScreen',
    'UnitsScreen',
    'ArcadeScreen',
    'ShopScreen',
    'StickerBookScreen',
    'PetsScreen',
    'SpinScreen',
  };

  static const resultRoute = 'ResultScreen';

  /// Navigator.home is named `/`; treat it as splash (no ads).
  static AdSurface surfaceFor(String? routeName) {
    if (routeName == null || routeName.isEmpty || routeName == '/') {
      return AdSurface.hidden;
    }
    if (routeName == resultRoute) return AdSurface.result;
    if (hubRoutes.contains(routeName)) return AdSurface.hub;
    return AdSurface.hidden;
  }

  static String routeNameFor(Object page) => page.runtimeType.toString();
}

/// Caps full-screen ads: never during play, never the first session, then at
/// most once per two completed games and once per three minutes.
class InterstitialGate {
  static const minSessions = 2;
  static const cooldown = Duration(minutes: 3);

  DateTime? lastShownAt;
  int gamesAtLastShow = 0;

  bool canShow({
    required int gamesTotal,
    required DateTime now,
    required bool allowed,
    required bool ready,
  }) {
    if (!allowed || !ready) return false;
    if (gamesTotal < minSessions) return false;
    final last = lastShownAt;
    if (last != null) {
      if (now.difference(last) < cooldown) return false;
      if (gamesTotal - gamesAtLastShow < minSessions) return false;
    }
    return true;
  }

  void markShown({required DateTime now, required int gamesTotal}) {
    lastShownAt = now;
    gamesAtLastShow = gamesTotal;
  }
}
