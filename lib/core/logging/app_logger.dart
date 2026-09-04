import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../config/flavor.dart';

/// Application logger.
///
/// In release builds nothing is emitted to the console. Once Crashlytics is
/// wired up (KAN-19), warnings and above should be forwarded there instead.
abstract final class AppLogger {
  static final Logger _root = Logger('nakshatra');

  static void initialize() {
    Logger.root.level = FlavorConfig.current.verboseLogging
        ? Level.ALL
        : Level.WARNING;

    Logger.root.onRecord.listen((record) {
      // Never write logs to the console in a release build: they cost
      // performance and can leak user birth data into logcat, which other
      // apps and anyone with adb access can read.
      if (kReleaseMode) return;

      developer.log(
        record.message,
        time: record.time,
        level: record.level.value,
        name: record.loggerName,
        error: record.error,
        stackTrace: record.stackTrace,
      );
    });
  }

  static Logger forName(String name) => Logger('nakshatra.$name');

  static void debug(String message) => _root.fine(message);
  static void info(String message) => _root.info(message);
  static void warn(String message, [Object? error, StackTrace? stackTrace]) =>
      _root.warning(message, error, stackTrace);
  static void error(String message, [Object? error, StackTrace? stackTrace]) =>
      _root.severe(message, error, stackTrace);
}
