import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'error_reporter.dart';

/// Where the consent flow ended up.
enum ConsentState {
  /// Not asked yet, or still resolving.
  unknown,

  /// The user is outside a consent region, or has already answered.
  obtained,

  /// A form is required and is waiting to be shown.
  required,

  /// Something failed; ads must fall back to non-personalised.
  unavailable,
}

/// Drives Google's User Messaging Platform (UMP) consent flow.
///
/// Required for serving ads to users in the EEA/UK, and it is what lets
/// AdMob decide between personalised and non-personalised ads. This app is
/// child-directed, so consent here governs the *non-personalised* ad request
/// rather than unlocking behavioural targeting.
///
/// Ships with google_mobile_ads, so no extra dependency is needed. Every call
/// is defensive: a consent failure must degrade to "no personalised ads",
/// never to a broken app.
class ConsentService extends ChangeNotifier {
  ConsentService._();
  static final ConsentService I = ConsentService._();

  ConsentState _state = ConsentState.unknown;
  bool _running = false;

  ConsentState get state => _state;

  /// True once it is safe to request ads.
  bool get canRequestAds => _state != ConsentState.required;

  /// True when a privacy options entry point should be shown to parents.
  bool privacyOptionsRequired = false;

  /// Requests consent info and shows the form when one is required.
  ///
  /// Safe to call repeatedly; concurrent calls collapse into one.
  Future<void> ensureConsent() async {
    if (kIsWeb || _running) return;
    _running = true;
    try {
      final params = ConsentRequestParameters(
        consentDebugSettings: ConsentDebugSettings(
          // Child-directed app: never request personalised ads.
          debugGeography: DebugGeography.debugGeographyDisabled,
        ),
      );
      final completer = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        () async {
          await _loadAndShowFormIfNeeded();
          if (!completer.isCompleted) completer.complete();
        },
        (error) {
          _set(ConsentState.unavailable);
          ErrorReporter.I.record(
            'Consent info update failed: ${error.message}',
            StackTrace.current,
            context: 'ConsentService',
          );
          if (!completer.isCompleted) completer.complete();
        },
      );
      await completer.future.timeout(
        const Duration(seconds: 8),
        onTimeout: () => _set(ConsentState.unavailable),
      );
    } catch (error, stack) {
      _set(ConsentState.unavailable);
      ErrorReporter.I.record(error, stack, context: 'ConsentService');
    } finally {
      _running = false;
    }
  }

  Future<void> _loadAndShowFormIfNeeded() async {
    try {
      privacyOptionsRequired =
          await ConsentInformation.instance.isConsentFormAvailable();
      final status = await ConsentInformation.instance.getConsentStatus();
      if (status != ConsentStatus.required) {
        _set(ConsentState.obtained);
        return;
      }
      _set(ConsentState.required);
      await _showForm();
    } catch (error, stack) {
      _set(ConsentState.unavailable);
      ErrorReporter.I.record(error, stack, context: 'ConsentService.form');
    }
  }

  Future<void> _showForm() async {
    final completer = Completer<void>();
    ConsentForm.loadAndShowConsentFormIfRequired((error) {
      if (error != null) {
        _set(ConsentState.unavailable);
        ErrorReporter.I.record(
          'Consent form failed: ${error.message}',
          StackTrace.current,
          context: 'ConsentService',
        );
      } else {
        _set(ConsentState.obtained);
      }
      if (!completer.isCompleted) completer.complete();
    });
    await completer.future;
  }

  /// Re-opens the privacy choices form from the parents' area.
  Future<void> showPrivacyOptions() async {
    if (kIsWeb) return;
    try {
      final completer = Completer<void>();
      ConsentForm.showPrivacyOptionsForm((error) {
        if (error != null) {
          ErrorReporter.I.record(
            'Privacy options failed: ${error.message}',
            StackTrace.current,
            context: 'ConsentService',
          );
        }
        if (!completer.isCompleted) completer.complete();
      });
      await completer.future;
    } catch (error, stack) {
      ErrorReporter.I.record(error, stack, context: 'ConsentService.privacy');
    }
  }

  void _set(ConsentState next) {
    if (_state == next) return;
    _state = next;
    notifyListeners();
  }

  @visibleForTesting
  void setStateForTest(ConsentState next) => _set(next);
}
