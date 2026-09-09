import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/config/flavor.dart';
import 'package:nakshatra/core/logging/analytics_service.dart';
import 'package:nakshatra/core/logging/app_logger.dart';
import 'package:nakshatra/core/sync/firebase_service.dart';

/// Analytics, and the flavor gate that decides whether it runs.
///
/// `FlavorConfig.enableAnalytics` existed from the start, prod-only, with a
/// comment saying development traffic must not pollute real metrics — and
/// nothing read it, because the SDK was never added. The Firebase console
/// showed nothing for the released app and there was no way to tell that from
/// a reporting failure.
///
/// These tests are about the gate and the failure states, not about delivery.
/// Whether an event reaches Google needs a real project and a real device;
/// whether a dev build is silent is decidable here, and it is the part that
/// would quietly corrupt the numbers if it were wrong.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FirebaseService.resetForTesting();
    AnalyticsService.resetForTesting();
    AppLogger.initialize();
  });

  tearDown(AnalyticsService.resetForTesting);

  test('the flavor flags say prod only', () {
    // The gate this service reads. If these ever flip, a developer's installs
    // start counting as users and every number after that is wrong.
    FlavorConfig.initialize(Flavor.prod);
    expect(FlavorConfig.current.enableAnalytics, isTrue);

    FlavorConfig.initialize(Flavor.dev);
    expect(FlavorConfig.current.enableAnalytics, isFalse);

    FlavorConfig.initialize(Flavor.staging);
    expect(FlavorConfig.current.enableAnalytics, isFalse);
  });

  test('without Firebase it stays off and does not throw', () async {
    // Every fresh clone and all of CI. initialize() is awaited before the
    // first frame, so throwing here would stop the app starting at all.
    FlavorConfig.initialize(Flavor.prod);
    expect(FirebaseService.isAvailable, isFalse);

    await expectLater(AnalyticsService.initialize(), completes);
    expect(AnalyticsService.isEnabled, isFalse);
  });

  test('a dev build never reports', () async {
    FlavorConfig.initialize(Flavor.dev);

    await expectLater(AnalyticsService.initialize(), completes);
    expect(AnalyticsService.isEnabled, isFalse);
  });

  test('there is no observer while analytics is off', () async {
    // The observer is attached to the router at build time. Null here means
    // no screen views are recorded, which is what a dev build should do.
    FlavorConfig.initialize(Flavor.dev);
    await AnalyticsService.initialize();

    expect(AnalyticsService.observer, isNull);
  });

  test('logging while off is silent rather than an error', () async {
    FlavorConfig.initialize(Flavor.dev);
    await AnalyticsService.initialize();

    await expectLater(AnalyticsService.log('chart_opened'), completes);
    await expectLater(
      AnalyticsService.log('chart_opened', {'style': 'south'}),
      completes,
    );
  });

  test('logging before initialize is silent', () async {
    await expectLater(AnalyticsService.log('early'), completes);
  });
}
