import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/config/flavor.dart';
import 'package:nakshatra/core/purchases/revenuecat_gateway.dart';

/// The checks that happen before the SDK is ever touched (KAN-35).
///
/// Everything else in the gateway needs a device. These two do not, and they
/// are the ones that decide whether a build talks to the store at all.
void main() {
  group('a Test Store key', () {
    test('is recognised by its prefix', () {
      // RevenueCat prefixes simulated-store keys `test_`. Real Android keys
      // start `goog_`.
      expect(RevenueCatGateway.isTestKey('test_abc123'), isTrue);
      expect(RevenueCatGateway.isTestKey('goog_abc123'), isFalse);
      expect(RevenueCatGateway.isTestKey(''), isFalse);
    });

    test('is refused in a prod build rather than shipped', () async {
      // The SDK's own warning: "our SDK will crash if using it in production".
      // A crash on launch for every user is not a failure mode this app is
      // allowed to have, and the mistake is easy — copy the dev env file,
      // forget one line, ship it.
      FlavorConfig.initialize(Flavor.prod);

      expect(
        await RevenueCatGateway().configure(publicKey: 'test_abc123'),
        isFalse,
        reason: 'a prod build must not configure with a Test Store key',
      );
    });

    test('an empty key is off, not an error', () async {
      // The normal state of a fresh clone.
      FlavorConfig.initialize(Flavor.dev);

      expect(await RevenueCatGateway().configure(publicKey: ''), isFalse);
    });
  });
}
