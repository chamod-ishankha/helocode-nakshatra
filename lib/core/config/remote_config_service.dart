import 'package:firebase_remote_config/firebase_remote_config.dart';

import '../logging/app_logger.dart';
import '../sync/firebase_service.dart';
import 'flavor.dart';

/// Firebase Remote Config (KAN-36).
///
/// Lets the paywall be tuned — which tier is recommended, which headline,
/// which features are currently free — without an app release. On the Spark
/// plan this is one of the few server-side levers available at all.
///
/// ## It is a dial, never a dependency
///
/// Same rule as Firebase, Crashlytics and the store: every failure is
/// swallowed, and every read has a default compiled in. A phone that has never
/// reached Firebase draws exactly the same paywall as one that has, minus the
/// experiment. Nothing here can stop a screen from rendering.
abstract final class RemoteConfigService {
  static FirebaseRemoteConfig? _config;

  static bool get isEnabled => _config != null;

  /// Fetches once, in the background, and never throws.
  ///
  /// The first launch always uses the compiled-in defaults: Remote Config
  /// answers from a local cache, and on a fresh install that cache is empty
  /// until this returns. That is deliberate — waiting on the network before
  /// the first frame to find out which headline to draw would be a poor trade.
  static Future<void> initialize() async {
    if (!FirebaseService.isAvailable) {
      AppLogger.info('Remote Config off: Firebase unavailable');
      return;
    }

    try {
      final config = FirebaseRemoteConfig.instance;

      await config.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          // Google throttles hard past a handful of fetches an hour, and the
          // throttle is per app instance — a developer testing an experiment
          // would hit it in minutes and then be unable to test at all. Prod
          // has no reason to ask more than hourly.
          minimumFetchInterval: FlavorConfig.current.flavor == Flavor.prod
              ? const Duration(hours: 1)
              : Duration.zero,
        ),
      );

      await config.fetchAndActivate();
      _config = config;
      AppLogger.info('Remote Config on');
    } on Object catch (e, s) {
      // Offline, throttled, or no Remote Config set up in the project yet.
      // All three are ordinary and all three mean "use the defaults".
      AppLogger.warn('Remote Config unavailable, using defaults', e, s);
      _config = null;
    }
  }

  /// A string value, or null when there is none.
  ///
  /// Null rather than an empty string, because "not set" and "deliberately
  /// blank" are different answers and only the caller knows which matters.
  static String? string(String key) {
    final value = _config?.getString(key);
    return (value == null || value.isEmpty) ? null : value;
  }

  /// Test seam.
  static void resetForTesting() => _config = null;
}
