import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/widgets.dart';

import '../config/flavor.dart';
import '../sync/firebase_service.dart';
import 'app_logger.dart';

/// Firebase Analytics (KAN-19).
///
/// ## Why this was missing for two days of closed testing
///
/// `FlavorConfig.enableAnalytics` has existed since the flavors were set up,
/// prod-only, with a comment explaining that development traffic must not
/// pollute real metrics. Nothing ever read it, because the SDK was never
/// added — so the Firebase console showed nothing for the released app and
/// there was no way to tell that from a reporting failure.
///
/// ## Prod only, on purpose
///
/// The flag is honoured rather than worked around. A developer reinstalling a
/// debug build twenty times an afternoon would otherwise look like twenty
/// users, which is worse than no numbers: numbers that are quietly wrong get
/// believed.
///
/// ## It can never take the app down
///
/// Same rule as [FirebaseService] and the crash reporter. Every failure is
/// swallowed. Analytics is a thing we would like to know, never a thing the
/// app needs in order to draw a chart.
abstract final class AnalyticsService {
  static FirebaseAnalytics? _analytics;

  /// Whether events are actually being sent.
  static bool get isEnabled => _analytics != null;

  /// A navigator observer that logs screen views, or null when disabled.
  ///
  /// Screen names come from the route path, so this reports which screens are
  /// used and never anything a user typed.
  static NavigatorObserver? get observer {
    final analytics = _analytics;
    return analytics == null
        ? null
        : FirebaseAnalyticsObserver(analytics: analytics);
  }

  /// Starts analytics if this flavor and this build allow it.
  ///
  /// Call after [FirebaseService.initialize]. Never throws.
  static Future<void> initialize() async {
    if (!FirebaseService.isAvailable) {
      AppLogger.info('Analytics off: Firebase unavailable');
      return;
    }

    if (!FlavorConfig.current.enableAnalytics) {
      AppLogger.info(
        'Analytics off: ${FlavorConfig.current.flavor.name} flavor',
      );
      // Explicitly off rather than merely unused, so a debug install cannot
      // report through automatic collection behind the flag's back.
      await _disableQuietly();
      return;
    }

    try {
      final analytics = FirebaseAnalytics.instance;
      await analytics.setAnalyticsCollectionEnabled(true);
      _analytics = analytics;
      AppLogger.info('Analytics on');
    } on Object catch (e, s) {
      AppLogger.warn('Analytics unavailable, continuing', e, s);
      _analytics = null;
    }
  }

  static Future<void> _disableQuietly() async {
    try {
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(false);
    } on Object catch (e) {
      AppLogger.warn('Could not disable analytics: $e');
    }
  }

  /// Records one event. Does nothing when analytics is off.
  static Future<void> log(
    String name, [
    Map<String, Object>? parameters,
  ]) async {
    final analytics = _analytics;
    if (analytics == null) return;

    try {
      await analytics.logEvent(name: name, parameters: parameters);
    } on Object catch (e) {
      AppLogger.warn('Could not log "$name": $e');
    }
  }

  /// Test seam.
  @visibleForTesting
  static void resetForTesting() => _analytics = null;
}
