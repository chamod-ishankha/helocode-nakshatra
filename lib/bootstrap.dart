import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/ads/ad_gate.dart';
import 'core/ads/ads_service.dart';
import 'core/ads/rewarded_unlock.dart';
import 'core/astro/ephemeris.dart';
import 'core/config/flavor.dart';
import 'core/logging/analytics_service.dart';
import 'core/logging/app_logger.dart';
import 'core/logging/crash_reporter.dart';
import 'core/sync/auth_service.dart';
import 'core/sync/firebase_service.dart';
import 'features/onboarding/data/profile_repository.dart';

/// Shared startup path for every flavor.
///
/// Each flavor entrypoint (`main_dev.dart`, `main_staging.dart`,
/// `main_prod.dart`) calls this with its own [Flavor]. Keeping one bootstrap
/// means flavors cannot drift apart in initialisation order.
Future<void> bootstrap(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Taken once, here, so the ad session grace period is measured from
  // the real launch rather than restarting on every widget rebuild.
  final launchedAt = DateTime.now();

  FlavorConfig.initialize(flavor);
  AppLogger.initialize();
  AppLogger.info('Starting Nakshatra (${flavor.name})');

  // Both are awaited before the first frame so no screen has to handle a
  // "not ready yet" state: the ephemeris is required to draw anything, and
  // the router needs the saved profile to decide where to land.
  // Sinhala and Tamil month and day names are not compiled in by default.
  // Without this, DateFormat falls back to English however the locale is set.
  await initializeDateFormatting();

  final prefs = await SharedPreferences.getInstance();
  await Ephemeris.initialize();

  // Firebase is awaited too, but it can never fail the launch: initialize()
  // swallows everything and leaves isAvailable false. A build with no
  // google-services.json, or a phone with no signal, still gets a fully
  // working app — charts and nekath are computed on-device.
  await FirebaseService.initialize();

  // Straight after Firebase and before the first frame, so an error thrown
  // while building the first screen is still reported. Never throws.
  await CrashReporter.initialize();

  // Prod only, and it honours FlavorConfig.enableAnalytics rather than working
  // around it: a debug reinstall twenty times an afternoon must not look like
  // twenty users.
  await AnalyticsService.initialize();

  // Decides whether the account screen offers a Google button at all. Also
  // never throws: a project without the Google provider switched on is the
  // normal state, not an error.
  await AuthService.initializeGoogle();

  // Not awaited. The SDK takes a second or two and the daily screen is what
  // the user opened the app for; ads can arrive after it.
  unawaited(AdsService.initialize());

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      appLaunchedAtProvider.overrideWithValue(launchedAt),
      // The real rewarded ad. Defaults to "not earned" so tests and any
      // build without the SDK never hand out an unlock for free.
      rewardedPresenterProvider.overrideWithValue(AdsService.showRewarded),
    ],
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
