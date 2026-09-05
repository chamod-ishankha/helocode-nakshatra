import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/astro/ephemeris.dart';
import 'core/config/flavor.dart';
import 'core/logging/app_logger.dart';
import 'core/sync/firebase_service.dart';
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

  // Firebase is awaited too, but it can never fail the launch: initialize()
  // swallows everything and leaves isAvailable false. A build with no
  // google-services.json, or a phone with no signal, still gets a fully
  // working app — charts and nekath are computed on-device.
  await FirebaseService.initialize();

  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );

  // If this install has no profile but the account has a backup, recover it so
  // a reinstall skips onboarding. Failure here is silent and simply means the
  // user is asked for their details again.
  if (FirebaseService.isAvailable) {
    await container.read(profileProvider.notifier).restoreFromBackup();
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const NakshatraApp(),
    ),
  );
}
