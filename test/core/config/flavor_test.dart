import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/config/flavor.dart';

void main() {
  tearDown(() => FlavorConfig.initialize(Flavor.dev));

  group('FlavorConfig', () {
    test('defaults to dev before initialize is called', () {
      expect(FlavorConfig.current.flavor, Flavor.dev);
    });

    test('resolves the matching config for each flavor', () {
      for (final flavor in Flavor.values) {
        FlavorConfig.initialize(flavor);
        expect(FlavorConfig.current.flavor, flavor);
      }
    });

    // Serving live ads to a developer's own device is the fastest route to a
    // permanent AdMob ban, so guard the invariant rather than trusting review.
    test('ads and analytics are enabled only in prod', () {
      for (final flavor in Flavor.values) {
        FlavorConfig.initialize(flavor);
        final config = FlavorConfig.current;

        expect(
          config.enableAds,
          flavor == Flavor.prod,
          reason: 'ads must be off outside prod (was ${flavor.name})',
        );
        expect(
          config.enableAnalytics,
          flavor == Flavor.prod,
          reason: 'analytics must be off outside prod (was ${flavor.name})',
        );
      }
    });

    test('verbose logging is off in prod', () {
      FlavorConfig.initialize(Flavor.prod);
      expect(FlavorConfig.current.verboseLogging, isFalse);
    });

    test('each flavor has a distinct app name', () {
      final names = <String>{};
      for (final flavor in Flavor.values) {
        FlavorConfig.initialize(flavor);
        names.add(FlavorConfig.current.appName);
      }
      expect(names.length, Flavor.values.length);
    });
  });
}
