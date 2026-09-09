import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/config/flavor.dart';
import 'package:nakshatra/core/logging/app_logger.dart';
import 'package:nakshatra/core/logging/crash_reporter.dart';
import 'package:nakshatra/core/sync/firebase_service.dart';

/// Crash reporting, which is the one thing that cannot report its own failure.
///
/// The app shipped to twelve testers with none of this. A crash on someone
/// else's phone was invisible: they saw it and nobody else ever did.
///
/// What matters here is not that reports reach Google — that needs a real
/// project and a real crash — but that the wiring holds in the states the app
/// is actually in: no Firebase, debug builds, and errors arriving before
/// anything is initialised. Every one of those has to end in silence rather
/// than in a second crash.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final reported = <(Object, bool)>[];
  late FlutterExceptionHandler? originalOnError;

  setUp(() {
    reported.clear();
    originalOnError = FlutterError.onError;
    FlavorConfig.initialize(Flavor.dev);
    FirebaseService.resetForTesting();
    CrashReporter.resetForTesting();
    AppLogger.initialize();
    CrashReporter.recorder = (error, stack, {fatal = false}) =>
        reported.add((error, fatal));
  });

  tearDown(() {
    CrashReporter.resetForTesting();
    FlutterError.onError = originalOnError;
  });

  test('an error is passed to the reporter', () {
    CrashReporter.record(StateError('boom'), StackTrace.current);

    expect(reported, hasLength(1));
    expect(reported.single.$1, isA<StateError>());
  });

  test('fatal is carried through', () {
    CrashReporter.record(Exception('a'), null, fatal: true);
    CrashReporter.record(Exception('b'), null);

    expect(reported.map((r) => r.$2), [true, false]);
  });

  test('recording without Firebase does nothing and does not throw', () {
    // The normal state of a fresh clone, and of any build with no
    // google-services.json. It must be silent, not a second failure.
    CrashReporter.recorder = null;
    expect(FirebaseService.isAvailable, isFalse);

    expect(
      () => CrashReporter.record(StateError('boom'), StackTrace.current),
      returnsNormally,
    );
    expect(CrashReporter.isEnabled, isFalse);
  });

  test('initialize survives having no Firebase', () async {
    // initialize() is awaited in bootstrap before the first frame. If it threw
    // here, a build without Firebase would not start at all — which is every
    // fresh clone, and CI.
    CrashReporter.recorder = null;

    await expectLater(CrashReporter.initialize(), completes);
    expect(CrashReporter.isEnabled, isFalse);
  });

  test('a Flutter framework error reaches the reporter', () async {
    // The handler is the point of the whole exercise: without it a framework
    // error prints to a console nobody is attached to.
    await CrashReporter.initialize();

    FlutterError.onError!(
      FlutterErrorDetails(
        exception: StateError('render blew up'),
        stack: StackTrace.current,
        library: 'test',
      ),
    );

    expect(reported, hasLength(1));
    expect(reported.single.$1, isA<StateError>());
    expect(reported.single.$2, isTrue, reason: 'framework errors are fatal');
  });

  test(
    'the handlers are installed even when nothing is being uploaded',
    () async {
      // Firebase is unavailable here, so nothing will be sent — but the handlers
      // still have to be in place, or an error escaping the zone kills the
      // isolate with no log at all.
      await CrashReporter.initialize();

      expect(FlutterError.onError, isNotNull);
      expect(CrashReporter.isEnabled, isFalse);
    },
  );

  test('a report before initialize is swallowed', () {
    CrashReporter.resetForTesting();

    expect(
      () => CrashReporter.record(Exception('early'), null),
      returnsNormally,
    );
  });
}
