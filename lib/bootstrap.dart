import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/ads/ad_gate.dart';
import 'core/ads/ads_service.dart';
import 'core/ads/interstitial.dart';
import 'core/ads/rewarded_interstitial.dart';
import 'core/ads/rewarded_unlock.dart';
import 'core/astro/ephemeris.dart';
import 'core/config/env.dart';
import 'core/config/flavor.dart';
import 'core/config/remote_config_service.dart';
import 'core/db/app_database.dart';
import 'core/db/profile_store.dart';
import 'core/logging/analytics_service.dart';
import 'core/notifications/notification_coordinator.dart';
import 'core/notifications/notification_service.dart';
import 'core/logging/app_logger.dart';
import 'core/logging/crash_reporter.dart';
import 'core/purchases/purchase_controller.dart';
import 'core/purchases/purchase_identity.dart';
import 'core/purchases/revenuecat_gateway.dart';
import 'core/sync/auth_service.dart';
import 'core/sync/firebase_service.dart';
import 'features/onboarding/data/profile_repository.dart';
import 'features/onboarding/domain/birth_profile.dart';

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

  // The profile moves from SharedPreferences into SQLite here, once (KAN-19).
  //
  // Read before the first frame and handed to the repository, so `load()` can
  // stay synchronous: the router decides where to send the user from whether a
  // profile exists, and an async read there would race its own redirect.
  //
  // The preferences copy is deliberately left behind. It is not read again
  // once the database has answered, but it is the only way back if the
  // database file is ever lost.
  final database = AppDatabase();
  final store = ProfileStore(database);
  BirthProfile? startingProfile;
  try {
    await store.migrateFromPrefs(ProfileRepository(prefs).load());
    startingProfile = (await store.selected())?.profile;
  } on Object catch (e, s) {
    // A database that will not open must not stop the app: the repository
    // falls back to preferences and the user keeps their profile.
    AppLogger.error('Database unavailable, using preferences', e, s);
    CrashReporter.record(e, s);
  }

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

  // Registers the channel and the tap handler. Scheduling comes later, once
  // the profile is known.
  await NotificationService.initialize();

  // Deliberately not awaited. The fetch has a ten-second timeout, and on a
  // poor connection awaiting it here is ten seconds of blank screen before the
  // app opens — paid for by every user, to decide which paywall headline to
  // use. Everything it controls has a compiled-in default, so a launch that
  // finishes before it does simply runs on those.
  //
  // It is also what makes Remote Config optional in the first place: a project
  // that never enables it costs nothing at startup.
  unawaited(RemoteConfigService.initialize());

  // Decides whether the account screen offers a Google button at all. Also
  // never throws: a project without the Google provider switched on is the
  // normal state, not an error.
  await AuthService.initializeGoogle();

  // Not awaited. The SDK takes a second or two and the daily screen is what
  // the user opened the app for; ads can arrive after it.
  unawaited(AdsService.initialize());

  // Awaited, unlike ads, because whether the user has paid decides whether the
  // first frame has a banner in it. This only starts the SDK — it does not go
  // to the network; the entitlements the first frame uses come from the cache
  // in EntitlementNotifier.build(), and the store is asked afterwards.
  //
  // Filed under the Firebase uid only when the account is permanent. See
  // AuthService.purchasesUserId for why an anonymous one is worse than none.
  final purchases = RevenueCatGateway();
  await purchases.configure(
    publicKey: Env.revenueCatPublicKey,
    appUserId: const AuthService().purchasesUserId,
  );

  final container = ProviderContainer(
    overrides: [
      purchaseGatewayProvider.overrideWithValue(purchases),
      sharedPreferencesProvider.overrideWithValue(prefs),
      appDatabaseProvider.overrideWithValue(database),
      initialProfileProvider.overrideWithValue(startingProfile),
      appLaunchedAtProvider.overrideWithValue(launchedAt),
      // The real rewarded ad. Defaults to "not earned" so tests and any
      // build without the SDK never hand out an unlock for free.
      rewardedPresenterProvider.overrideWithValue(AdsService.showRewarded),
      // The real interstitial (KAN-55). Same reasoning: without these a test
      // and a build with no SDK both behave as "no ad was shown", which is the
      // answer that leaves the cooldown untouched.
      interstitialPreloaderProvider.overrideWithValue(
        AdsService.preloadInterstitial,
      ),
      interstitialPresenterProvider.overrideWithValue(
        AdsService.showInterstitial,
      ),
      rewardedInterstitialPreloaderProvider.overrideWithValue(
        AdsService.preloadRewardedInterstitial,
      ),
      rewardedInterstitialPresenterProvider.overrideWithValue(
        AdsService.showRewardedInterstitial,
      ),
    ],
  );

  // If this install has no profile but the account has a backup, recover it so
  // a reinstall skips onboarding. Failure here is silent and simply means the
  // user is asked for their details again.
  if (FirebaseService.isAvailable) {
    await container.read(profileProvider.notifier).restoreFromBackup();
  }

  // Not awaited. Seven pañcāṅga are a few ephemeris calls each, and the daily
  // screen is what the user opened the app for; reminders can be re-armed
  // after it is on screen.
  unawaited(
    container
        .read(notificationRefreshProvider.future)
        .catchError((Object _) {}),
  );

  // Also not awaited: this is the network round trip that corrects the cached
  // entitlements, and it subscribes to store updates. A purchase made with a
  // slow payment method settles through that subscription and through nothing
  // else, so it has to be attached on every launch rather than only when a
  // paywall is opened.
  unawaited(container.read(entitlementsProvider.notifier).start());

  // Loaded here rather than on the screen before, because the screen before
  // the chart is the home screen and it is stateless — a preload in its build
  // would fire on every rebuild. One request per launch, skipped entirely for
  // a purchaser and for anyone who already holds what it pays out, and by the
  // time the 90-second grace expires it is ready (KAN-55).
  //
  // Chained off `ready` rather than called directly. AdsService.initialize()
  // is deliberately not awaited above, and asking for an ad before the SDK
  // has started returns quietly having done nothing — no error, no log, just
  // a placement that never fires. Found on the device: the chart showed one
  // ad ever, and only because the first one had been loaded by hand.
  unawaited(
    AdsService.ready.then((started) {
      if (!started) return null;
      return container
          .read(rewardedInterstitialControllerProvider)
          .prepare(container.read(unlockStoreProvider));
    }),
  );

  // Tells the store when the signed-in account changes (KAN-64). Without it,
  // signing out leaves the previous account's Pro on screen until the app is
  // restarted, and buying while anonymous never reaches the account it was
  // meant for. Lives as long as the container, which is the app.
  linkPurchasesToAccount(container);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const NakshatraApp(),
    ),
  );
}
