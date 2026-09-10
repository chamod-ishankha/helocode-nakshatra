import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/ads/ad_gate.dart';
import 'package:nakshatra/core/purchases/entitlement_cache.dart';
import 'package:nakshatra/core/purchases/entitlements.dart';
import 'package:nakshatra/core/purchases/purchase_controller.dart';
import 'package:nakshatra/core/purchases/purchase_identity.dart';
import 'package:nakshatra/features/onboarding/data/profile_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_purchase_gateway.dart';

/// Following the signed-in account into the store (KAN-64).
///
/// The bug was never in the logic — `identify` and `forget` were written,
/// documented and correct. It was that nothing called them, which no test
/// could catch by exercising them directly. So every case here drives the
/// *account id* and asserts what reached the store, never touching the
/// notifier itself.
void main() {
  late SharedPreferences prefs;
  late FakePurchaseGateway store;

  final now = DateTime(2026, 1, 20);
  final nextYear = DateTime(2027, 1, 20);

  /// The signed-in account, as the app would see it. Null is both "signed
  /// out" and "anonymous" — the ambiguity the fix has to survive.
  late NotifierProvider<_Account, String?> account;

  ProviderContainer harness({String? signedInAs}) {
    account = NotifierProvider<_Account, String?>(() => _Account(signedInAs));

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        purchaseGatewayProvider.overrideWithValue(store),
        purchaseClockProvider.overrideWithValue(() => now),
        // Stands in for AuthService.purchasesUserId, so none of this needs
        // Firebase. What is under test is what the listener does with the
        // value, not where the value comes from.
        purchasesUserIdProvider.overrideWith((ref) => ref.watch(account)),
      ],
    );
    addTearDown(container.dispose);

    // The line bootstrap adds. Without it nothing is listening, which is
    // precisely the shipped bug.
    addTearDown(linkPurchasesToAccount(container).close);
    return container;
  }

  /// Signs in, out or across, and lets the listener's async work finish.
  Future<void> becomes(ProviderContainer container, String? id) async {
    container.read(account.notifier).signedInAs(id);
    await pumpEventQueue();
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    store = FakePurchaseGateway();
  });

  group('the four transitions', () {
    test('signing in claims the purchase for that account', () async {
      // Bought while anonymous. Purchases.logIn is what merges it into the
      // real account; without this call the buyer keeps it only on this
      // install and finds out on their next phone.
      final container = harness();

      await becomes(container, 'uid-anushka');

      expect(store.identified, ['uid-anushka']);
      expect(store.forgets, 0);
    });

    test('signing out releases it', () async {
      // The shared-phone case. Handing the phone over and letting the next
      // person sign in as themselves must not show them somebody else's Pro.
      final container = harness(signedInAs: 'uid-anushka');

      await becomes(container, null);

      expect(store.forgets, 1);
      expect(store.identified, isEmpty);
    });

    test('swapping accounts follows the new one', () async {
      final container = harness(signedInAs: 'uid-anushka');

      await becomes(container, 'uid-dilani');

      expect(store.identified, ['uid-dilani']);
    });

    test('an anonymous user is left alone', () async {
      // The case that makes this a listener on the change rather than on the
      // value: purchasesUserId is null for anonymous as well as signed out,
      // so acting on the value would forget() at every launch and throw away
      // a purchase made through their Play account.
      harness();
      await pumpEventQueue();

      expect(store.identified, isEmpty);
      expect(store.forgets, 0);
    });
  });

  group('the starting position', () {
    test('a signed-in user at launch is not re-identified', () async {
      // bootstrap has already configured the store with this id. Firing on
      // the first read would be a redundant network round trip on the launch
      // path, on every launch.
      harness(signedInAs: 'uid-anushka');
      await pumpEventQueue();

      expect(store.identified, isEmpty);
      expect(store.forgets, 0);
    });

    test('a repeated value is not a transition', () async {
      // userChanges() also fires on token refresh, which is frequent and
      // means nothing here.
      final container = harness(signedInAs: 'uid-anushka');

      await becomes(container, 'uid-anushka');

      expect(store.identified, isEmpty);
      expect(store.forgets, 0);
    });
  });

  group('what the user sees', () {
    test('signing out takes the previous account Pro off the screen', () async {
      // forget() clears the cache as well as the store identity. Leaving it
      // would keep Pro on screen until the app was restarted — long enough
      // for the next person to use it.
      await EntitlementCache(prefs).write(
        EntitlementSnapshot(
          grants: {Entitlement.pro: nextYear},
          refreshedAt: now,
        ),
      );

      final container = harness(signedInAs: 'uid-anushka');
      expect(container.read(adFreeEntitlementProvider), isTrue);

      store.answer = null;
      await becomes(container, null);

      expect(container.read(adFreeEntitlementProvider), isFalse);
      expect(EntitlementCache(prefs).read(), isNull);
    });

    test('signing in shows what that account holds', () async {
      final container = harness();
      store.answer = EntitlementSnapshot(
        grants: {Entitlement.pro: nextYear},
        refreshedAt: now,
      );

      await becomes(container, 'uid-anushka');

      expect(container.read(adFreeEntitlementProvider), isTrue);
    });
  });

  test('a store that cannot be reached does not break signing in', () async {
    // Mid sign-in, on a bad connection. The account screen must finish and
    // the app must stay usable; the next launch reconciles.
    store.throwOnIdentify = true;
    final container = harness();

    await becomes(container, 'uid-anushka');

    expect(container.read(entitlementsProvider), isNotNull);
  });
}

/// A drivable stand-in for the signed-in account id.
///
/// A Notifier rather than a StateProvider: Riverpod 3 removed the latter.
class _Account extends Notifier<String?> {
  _Account(this._seed);

  final String? _seed;

  @override
  String? build() => _seed;

  void signedInAs(String? id) => state = id;
}
