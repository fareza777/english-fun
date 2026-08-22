import 'package:english_fun/services/error_reporter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    ErrorReporter.I.resetForTest();
    SharedPreferences.setMockInitialValues({});
    await ErrorReporter.I.init();
  });

  test('records an error with its context', () async {
    ErrorReporter.I.record(StateError('boom'), StackTrace.current, context: 'unit');

    expect(ErrorReporter.I.hasRecords, isTrue);
    final record = ErrorReporter.I.records.single;
    expect(record.error, contains('boom'));
    expect(record.context, 'unit');
    expect(record.fatal, isFalse);
    expect(record.stack, isNotEmpty);
  });

  test('keeps the newest records first and caps the log', () async {
    for (var i = 0; i < ErrorReporter.maxRecords + 8; i++) {
      ErrorReporter.I.record('error $i', null);
    }

    final records = ErrorReporter.I.records;
    expect(records, hasLength(ErrorReporter.maxRecords));
    expect(records.first.error, 'error ${ErrorReporter.maxRecords + 7}');
  });

  test('survives a restart by reloading from storage', () async {
    ErrorReporter.I.record('persisted failure', StackTrace.current, fatal: true);

    // Simulate a fresh launch against the same preferences.
    ErrorReporter.I.resetForTest();
    await ErrorReporter.I.init();

    expect(ErrorReporter.I.records.single.error, 'persisted failure');
    expect(ErrorReporter.I.records.single.fatal, isTrue);
  });

  test('a corrupt log never blocks startup', () async {
    SharedPreferences.setMockInitialValues({'error_log_v1': 'not json at all'});
    ErrorReporter.I.resetForTest();

    await ErrorReporter.I.init();
    expect(ErrorReporter.I.records, isEmpty);

    // And it can still record afterwards.
    ErrorReporter.I.record('after corruption', null);
    expect(ErrorReporter.I.records, hasLength(1));
  });

  test('forwards to an external reporter such as Crashlytics', () async {
    final forwarded = <ErrorRecord>[];
    ErrorReporter.I.onReport = forwarded.add;

    ErrorReporter.I.record('sent onwards', null, context: 'sink');

    expect(forwarded, hasLength(1));
    expect(forwarded.single.error, 'sent onwards');
  });

  test('a throwing external reporter cannot break the app', () async {
    ErrorReporter.I.onReport = (_) => throw StateError('reporter is down');

    // The record call itself must still succeed and store the entry.
    expect(() => ErrorReporter.I.record('still logged', null), returnsNormally);
    expect(ErrorReporter.I.records.single.error, 'still logged');
  });

  test('clear empties the log', () async {
    ErrorReporter.I.record('temporary', null);
    await ErrorReporter.I.clear();

    expect(ErrorReporter.I.hasRecords, isFalse);
  });

  test('exports a readable text dump for support', () async {
    expect(ErrorReporter.I.exportAsText(), 'No errors recorded.');

    ErrorReporter.I.record('readable failure', StackTrace.current, context: 'export');
    final dump = ErrorReporter.I.exportAsText();

    expect(dump, contains('readable failure'));
    expect(dump, contains('context: export'));
  });

  test('shortError trims a long first line', () {
    final record = ErrorRecord(
      time: DateTime(2026),
      error: 'x' * 400,
      stack: '',
      context: '',
      fatal: false,
    );
    expect(record.shortError.length, lessThanOrEqualTo(120));
    expect(record.shortError, endsWith('...'));
  });

  test('install routes Flutter framework errors into the log', () async {
    ErrorReporter.I.install();
    addTearDown(() => FlutterError.onError = FlutterError.presentError);

    FlutterError.reportError(
      FlutterErrorDetails(
        exception: StateError('framework failure'),
        stack: StackTrace.current,
        library: 'test',
      ),
    );

    expect(
      ErrorReporter.I.records.any((r) => r.error.contains('framework failure')),
      isTrue,
    );
  });
}
