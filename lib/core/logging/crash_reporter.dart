import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../config/flavor.dart';
import '../sync/firebase_service.dart';
import 'app_logger.dart';

/// Sends crashes and uncaught errors to Crashlytics (KAN-19).
///
/// The app went into closed testing with twelve people and no crash reporting
/// of any kind. A crash on someone else's phone was simply invisible: they
/// would see it, and nobody else ever would. [AppLogger] writes to the local
/// console, which is useful with a cable attached and useless otherwise.
///
/// ## It can never take the app down
///
/// Same rule as [FirebaseService]: everything here is swallowed. A build with
/// no `google-services.json`, a phone with no signal, a Crashlytics outage —
/// all of them leave the app computing charts and nekath exactly as before.
/// A reporting tool that can crash the thing it reports on is worse than none.
///
/// ## Debug builds do not report
///
/// Collection is off in debug, so a developer's own deliberate errors do not
/// land in the same list as a tester's real ones. Reports are written to disk
/// on the crashing run and sent on the *next* launch, which is why a crash
/// forced by hand takes a restart to show up.
abstract final class CrashReporter {
  static bool _enabled = false;

  /// A test seam. Set to collect reports instead of sending them.
  @visibleForTesting
  static void Function(Object error, StackTrace? stack, {bool fatal})? recorder;

  /// Whether reports are actually being sent.
  static bool get isEnabled => _enabled;

  /// Starts reporting and takes over the two global error handlers.
  ///
  /// Call after [FirebaseService.initialize], because Crashlytics needs the
  /// Firebase app that sets up.
  static Future<void> initialize() async {
    // The handlers are installed either way. Without them a Flutter framework
    // error only prints, and an error escaping the zone kills the isolate
    // silently — both true whether or not anything is being uploaded.
    FlutterError.onError = (details) {
      AppLogger.error(
        'Flutter error: ${details.exceptionAsString()}',
        details.exception,
        details.stack,
      );
      record(details.exception, details.stack, fatal: true);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      AppLogger.error('Uncaught error', error, stack);
      record(error, stack, fatal: true);
      // True: handled, so the isolate is not torn down for an error the app
      // has already reported and can usually survive.
      return true;
    };

    if (!FirebaseService.isAvailable) {
      AppLogger.info('Crash reporting off: Firebase unavailable');
      return;
    }

    try {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        !kDebugMode,
      );
      // Which build a report came from. Without it a dev crash and a tester's
      // crash are indistinguishable in the console.
      await FirebaseCrashlytics.instance.setCustomKey(
        'flavor',
        FlavorConfig.current.flavor.name,
      );
      _enabled = !kDebugMode;
      AppLogger.info('Crash reporting ${_enabled ? "on" : "off (debug)"}');
    } on Object catch (e, s) {
      AppLogger.warn('Crash reporting unavailable, continuing', e, s);
      _enabled = false;
    }
  }

  /// Reports one error.
  ///
  /// Safe to call at any time, including before [initialize] and on a build
  /// with no Firebase — it does nothing rather than throwing.
  static void record(Object error, StackTrace? stack, {bool fatal = false}) {
    final sink = recorder;
    if (sink != null) {
      sink(error, stack, fatal: fatal);
      return;
    }

    if (!_enabled) return;

    try {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: fatal);
    } on Object catch (e) {
      // Reporting the failure of the reporter would recurse.
      AppLogger.warn('Could not record a crash: $e');
    }
  }

  /// Test seam — clears the memoised state and any installed recorder.
  @visibleForTesting
  static void resetForTesting() {
    _enabled = false;
    recorder = null;
  }
}
