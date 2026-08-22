import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'ads_policy.dart';

/// Tracks the currently visible ad surface from Navigator events.
///
/// Unnamed routes (dialogs, bottom sheets) are ignored so the hub banner
/// does not blink off when a unit sheet opens.
class AdsPlacement extends ChangeNotifier {
  AdsPlacement._();
  static final AdsPlacement I = AdsPlacement._();

  late final NavigatorObserver observer = _AdsNavigatorObserver(this);

  AdSurface _surface = AdSurface.hidden;
  bool _hubBannerReady = false;
  bool _notifyScheduled = false;

  AdSurface get surface => _surface;
  bool get hubBannerReady => _hubBannerReady;
  bool get showHubBanner => _surface == AdSurface.hub;
  bool get showResultMrec => _surface == AdSurface.result;
  bool get consumeBottomInset => _surface == AdSurface.hub && _hubBannerReady;

  void setHubBannerReady(bool ready) {
    if (_hubBannerReady == ready) return;
    _hubBannerReady = ready;
    _scheduleNotify();
  }

  void applyRouteName(String? name) {
    if (name == null || name.isEmpty) return;
    final next = AdsPolicy.surfaceFor(name);
    if (next == _surface) return;
    _surface = next;
    if (_surface != AdSurface.hub) _hubBannerReady = false;
    _scheduleNotify();
  }

  /// NavigatorObserver.didPush can fire while the navigator is building.
  /// Deferring the rebuild avoids marking [_AdShell] dirty mid-frame.
  void _scheduleNotify() {
    SchedulerBinding? binding;
    try {
      binding = WidgetsBinding.instance;
    } catch (_) {
      notifyListeners();
      return;
    }
    if (binding.schedulerPhase == SchedulerPhase.idle ||
        binding.schedulerPhase == SchedulerPhase.postFrameCallbacks) {
      notifyListeners();
      return;
    }
    if (_notifyScheduled) return;
    _notifyScheduled = true;
    binding.addPostFrameCallback((_) {
      _notifyScheduled = false;
      notifyListeners();
    });
  }

  @visibleForTesting
  void resetForTest() {
    _surface = AdSurface.hidden;
    _hubBannerReady = false;
    _notifyScheduled = false;
  }
}

class _AdsNavigatorObserver extends NavigatorObserver {
  _AdsNavigatorObserver(this._owner);
  final AdsPlacement _owner;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _owner.applyRouteName(route.settings.name);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _owner.applyRouteName(newRoute?.settings.name);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _owner.applyRouteName(previousRoute?.settings.name);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _owner.applyRouteName(previousRoute?.settings.name);
  }
}
