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

/// When the hub banner is allowed to start a *new* AdMob request.
///
/// Reloading on every notify after a no-fill spams the network. That is why
/// the banner vanished after a single game: the first return request missed,
/// then a listener reset the backoff and fired another immediate request
/// until AdMob stopped filling for the rest of the session.
enum HubBannerAction { none, tearDown, load }

class HubBannerLoadGate {
  bool _onHub = false;

  bool get onHub => _onHub;

  HubBannerAction decide({
    required bool adsAllowed,
    required bool isHub,
    required bool hasBanner,
    required bool loading,
  }) {
    if (!adsAllowed || !isHub) {
      _onHub = false;
      return HubBannerAction.tearDown;
    }
    if (_onHub) return HubBannerAction.none;
    _onHub = true;
    if (hasBanner || loading) return HubBannerAction.none;
    return HubBannerAction.load;
  }

  /// After a size-change rebuild the next hub tick must be allowed to load.
  void reset() => _onHub = false;
}

/// Backoff for a persistent hub banner after consecutive no-fill responses.
///
/// The counter deliberately lives outside the widget's load method: resetting
/// it at the start of every retry turns the intended exponential backoff into
/// a tight loop that keeps asking AdMob every few seconds.
class HubBannerRetryPolicy {
  static const maxDelay = Duration(minutes: 4);

  int _failures = 0;

  Duration recordFailure() {
    _failures++;
    final backoff = Duration(seconds: 3 * (1 << (_failures - 1).clamp(0, 7)));
    return backoff > maxDelay ? maxDelay : backoff;
  }

  void reset() => _failures = 0;
}
