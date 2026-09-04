import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/astro/ephemeris.dart';
import 'core/config/flavor.dart';
import 'core/logging/app_logger.dart';
import 'features/onboarding/data/profile_repository.dart';

/// Shared startup path for every flavor.
///
/// Each flavor entrypoint (`main_dev.dart`, `main_staging.dart`,
/// `main_prod.dart`) calls this with its own [Flavor]. Keeping one bootstrap
/// means flavors cannot drift apart in initialisation order.
Future<void> bootstrap(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();

  FlavorConfig.initialize(flavor);
  AppLogger.initialize();
  AppLogger.info('Starting Nakshatra (${flavor.name})');

  // Both are awaited before the first frame so no screen has to handle a
  // "not ready yet" state: the ephemeris is required to draw anything, and
  // the router needs the saved profile to decide where to land.
  final prefs = await SharedPreferences.getInstance();
  await Ephemeris.initialize();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const NakshatraApp(),
    ),
  );
}
