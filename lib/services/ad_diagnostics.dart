import 'package:flutter/foundation.dart';

/// Last-known state of one ad slot (hub banner, result MREC, interstitial).
@immutable
class AdSlotStatus {
  final int loads;
  final int failures;
  final DateTime? lastLoadedAt;
  final int? lastErrorCode;
  final String lastError;
  final DateTime? lastErrorAt;

  const AdSlotStatus({
    this.loads = 0,
    this.failures = 0,
    this.lastLoadedAt,
    this.lastErrorCode,
    this.lastError = '',
    this.lastErrorAt,
  });

  AdSlotStatus copyWith({
    int? loads,
    int? failures,
    DateTime? lastLoadedAt,
    int? lastErrorCode,
    String? lastError,
    DateTime? lastErrorAt,
  }) {
    return AdSlotStatus(
      loads: loads ?? this.loads,
      failures: failures ?? this.failures,
      lastLoadedAt: lastLoadedAt ?? this.lastLoadedAt,
      lastErrorCode: lastErrorCode ?? this.lastErrorCode,
      lastError: lastError ?? this.lastError,
      lastErrorAt: lastErrorAt ?? this.lastErrorAt,
    );
  }
}

/// Answers the one question closed testers always ask — "kenapa tidak ada
/// iklan?" — without needing logcat.
///
/// Ad load callbacks report here ([markLoaded] / [markFailed]) and the
/// parents' diagnostics screen renders the result. Load *failures* are kept
/// out of [ErrorReporter] on purpose: a child-directed ad unit returns
/// "no fill" constantly, and logging every miss would flush real crashes out
/// of the rolling error log. Actual exceptions still go to ErrorReporter.
class AdDiagnostics extends ChangeNotifier {
  AdDiagnostics._();
  static final AdDiagnostics I = AdDiagnostics._();

  static const slotBanner = 'banner';
  static const slotMrec = 'mrec';
  static const slotInterstitial = 'interstitial';

  /// The MobileAds SDK finished initializing.
  bool sdkReady = false;

  /// MobileAds.initialize() threw. Almost always means a manifest/App ID
  /// problem or a device without Play services — and with it, zero ads.
  bool sdkInitFailed = false;

  final Map<String, AdSlotStatus> _slots = {};

  AdSlotStatus slot(String name) => _slots[name] ?? const AdSlotStatus();

  void markSdkReady() {
    sdkReady = true;
    notifyListeners();
  }

  void markSdkInitFailed() {
    sdkInitFailed = true;
    notifyListeners();
  }

  void markLoaded(String name) {
    final current = slot(name);
    _slots[name] = current.copyWith(
      loads: current.loads + 1,
      lastLoadedAt: DateTime.now(),
    );
    notifyListeners();
  }

  void markFailed(String name, int? code, String message) {
    final current = slot(name);
    _slots[name] = current.copyWith(
      failures: current.failures + 1,
      lastErrorCode: code,
      lastError: message,
      lastErrorAt: DateTime.now(),
    );
    notifyListeners();
  }

  @visibleForTesting
  void resetForTest() {
    sdkReady = false;
    sdkInitFailed = false;
    _slots.clear();
  }
}
