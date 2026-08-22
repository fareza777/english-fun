import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One captured error, kept small enough to store many of them in prefs.
@immutable
class ErrorRecord {
  final DateTime time;
  final String error;
  final String stack;
  final String context;
  final bool fatal;

  const ErrorRecord({
    required this.time,
    required this.error,
    required this.stack,
    required this.context,
    required this.fatal,
  });

  /// Short one-line label for the parent diagnostics list.
  String get shortError {
    final firstLine = error.split('\n').first.trim();
    return firstLine.length <= 120 ? firstLine : '${firstLine.substring(0, 117)}...';
  }

  Map<String, dynamic> toJson() => {
        't': time.toIso8601String(),
        'e': error,
        's': stack,
        'c': context,
        'f': fatal,
      };

  static ErrorRecord? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final time = DateTime.tryParse('${raw['t']}');
    if (time == null) return null;
    return ErrorRecord(
      time: time,
      error: '${raw['e'] ?? ''}',
      stack: '${raw['s'] ?? ''}',
      context: '${raw['c'] ?? ''}',
      fatal: raw['f'] == true,
    );
  }
}

/// Captures every Dart-side error the app can see and keeps a rolling log.
///
/// Two jobs:
/// 1. **Never lose a crash silently.** Flutter framework errors, async errors
///    from the platform dispatcher, and anything thrown inside the guarded
///    zone all land in [record].
/// 2. **Stay pluggable.** Attach Crashlytics/Sentry by setting [onReport]
///    once in `main()`; no other file needs to change.
///
/// Deliberately dependency-free so it works offline and in tests.
///
/// Note: this cannot catch native crashes that happen before the Dart VM
/// runs (for example a failing Android ContentProvider). Play Console
/// "Vitals" remains the source of truth for those.
class ErrorReporter {
  ErrorReporter._();
  static final ErrorReporter I = ErrorReporter._();

  static const _storageKey = 'error_log_v1';
  static const maxRecords = 20;
  static const _maxStackChars = 2000;

  SharedPreferences? _prefs;
  final List<ErrorRecord> _records = [];
  bool _installed = false;

  /// Newest first.
  List<ErrorRecord> get records => List.unmodifiable(_records);

  bool get hasRecords => _records.isNotEmpty;

  /// Optional external sink (Crashlytics, Sentry, custom endpoint).
  /// Must not throw; exceptions from it are swallowed.
  void Function(ErrorRecord record)? onReport;

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final raw = _prefs?.getString(_storageKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      for (final item in decoded) {
        final record = ErrorRecord.fromJson(item);
        if (record != null) _records.add(record);
      }
    } catch (_) {
      // A corrupt log must never block startup.
    }
  }

  /// Routes Flutter + async errors here. Safe to call more than once.
  void install() {
    if (_installed) return;
    _installed = true;

    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      record(
        details.exception,
        details.stack,
        context: details.context?.toDescription() ?? 'FlutterError',
        fatal: false,
      );
      previousOnError?.call(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      record(error, stack, context: 'PlatformDispatcher', fatal: true);
      return true; // handled: keep the app alive
    };
  }

  /// Records one error. Never throws.
  void record(
    Object error,
    StackTrace? stack, {
    String context = '',
    bool fatal = false,
  }) {
    try {
      final entry = ErrorRecord(
        time: DateTime.now(),
        error: error.toString(),
        stack: _trimStack(stack),
        context: context,
        fatal: fatal,
      );
      _records.insert(0, entry);
      if (_records.length > maxRecords) {
        _records.removeRange(maxRecords, _records.length);
      }
      _persist();
      if (kDebugMode) {
        debugPrint('[ErrorReporter] $context: ${entry.shortError}');
      }
      try {
        onReport?.call(entry);
      } catch (_) {
        // An failing external reporter must not cascade.
      }
    } catch (_) {
      // Recording an error must never itself crash the app.
    }
  }

  static String _trimStack(StackTrace? stack) {
    if (stack == null) return '';
    final text = stack.toString();
    return text.length <= _maxStackChars ? text : text.substring(0, _maxStackChars);
  }

  void _persist() {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      final payload = jsonEncode(_records.map((r) => r.toJson()).toList());
      unawaited(prefs.setString(_storageKey, payload));
    } catch (_) {}
  }

  Future<void> clear() async {
    _records.clear();
    try {
      await _prefs?.remove(_storageKey);
    } catch (_) {}
  }

  /// Plain-text dump a parent can share with support.
  String exportAsText() {
    if (_records.isEmpty) return 'No errors recorded.';
    final buffer = StringBuffer();
    for (final r in _records) {
      buffer
        ..writeln('--- ${r.time.toIso8601String()} ${r.fatal ? '[FATAL]' : ''}')
        ..writeln('context: ${r.context}')
        ..writeln(r.error);
      if (r.stack.isNotEmpty) buffer.writeln(r.stack);
      buffer.writeln();
    }
    return buffer.toString();
  }

  @visibleForTesting
  void resetForTest() {
    _records.clear();
    _installed = false;
    onReport = null;
    _prefs = null;
  }
}
