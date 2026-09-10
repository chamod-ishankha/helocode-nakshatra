import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/ads/ad_gate.dart';
import 'package:nakshatra/core/purchases/entitlement_cache.dart';
import 'package:nakshatra/core/purchases/entitlements.dart';
import 'package:nakshatra/core/purchases/products.dart';
import 'package:nakshatra/core/purchases/purchase_controller.dart';
import 'package:nakshatra/core/purchases/purchase_gateway.dart';
import 'package:nakshatra/features/onboarding/data/profile_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_purchase_gateway.dart';

/// Buying, restoring, and staying bought (KAN-35).
void main() {
  late SharedPreferences prefs;
  late FakePurchaseGateway store;

  final now = DateTime(2026, 1, 20);
  final nextYear = DateTime(2027, 1, 20);

  EntitlementSnapshot holding(
    Map<Entitlement, DateTime?> grants, {
    DateTime? at,
  }) => EntitlementSnapshot(grants: grants, refreshedAt: at ?? now);

  ProviderContainer harness() {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        purchaseGatewayProvider.overrideWithValue(store),
        purchaseClockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    store = FakePurchaseGateway();
  });

  group('what the first frame knows', () {
    test('a cached entitlement is live on the very first read', () async {
      // The first frame decides whether to draw a banner ad. Waiting for the
      // network would mean either a hole in the layout or an ad shown to
      // somebody who paid to remove it.
      await EntitlementCache(prefs).write(holding({Entitlement.adFree: null}));

      final container = harness();

      expect(container.read(entitlementsProvider).isEmpty, isFalse);
      expect(container.read(featureProvider(PaidFeature.removeAds)), isTrue);
      expect(store.refreshes, 0, reason: 'nothing was asked yet');
    });

    test('no cache means nothing is held', () {
      final container = harness();

      expect(container.read(entitlementsProvider).isEmpty, isTrue);
      expect(container.read(featureProvider(PaidFeature.removeAds)), isFalse);
    });
  });

  group('refreshing', () {
    test('takes the store answer and remembers it', () async {
      store.answer = holding({Entitlement.pro: nextYear});
      final container = harness();

      await container.read(entitlementsProvider.notifier).refresh();

      expect(
        container.read(featureProvider(PaidFeature.fullDashaTimeline)),
        isTrue,
      );
      expect(
        EntitlementCache(prefs).read()?.isActive(Entitlement.pro, now),
        isTrue,
        reason: 'the next launch must not have to ask again',
      );
    });

    test('a store that cannot be reached does not revoke anything', () async {
      // The expensive mistake. A paying customer on a bad connection who
      // suddenly sees ads asks for a refund; the reverse costs nothing.
      await EntitlementCache(prefs).write(holding({Entitlement.pro: nextYear}));
      store.answer = null;

      final container = harness();
      await container.read(entitlementsProvider.notifier).refresh();

      expect(
        container.read(featureProvider(PaidFeature.fullDashaTimeline)),
        isTrue,
      );
    });

    test('a store that says the subscription is gone is believed', () async {
      // The other direction: an answer, not a failure. A cancellation has to
      // land, or nobody would ever leave.
      await EntitlementCache(prefs).write(holding({Entitlement.pro: nextYear}));
      store.answer = EntitlementSnapshot.empty(now);

      final container = harness();
      await container.read(entitlementsProvider.notifier).refresh();

      expect(
        container.read(featureProvider(PaidFeature.fullDashaTimeline)),
        isFalse,
      );
      expect(EntitlementCache(prefs).read()?.isEmpty, isTrue);
    });
  });

  group('buying', () {
    test('a completed purchase takes effect immediately', () async {
      store.nextPurchase = PurchaseAttempt(
        PurchaseOutcome.purchased,
        entitlements: holding({Entitlement.adFree: null}),
      );

      final container = harness();
      final result = await container
          .read(entitlementsProvider.notifier)
          .buy(PurchaseProduct.removeAds);

      expect(result.isSuccess, isTrue);
      expect(container.read(adFreeEntitlementProvider), isTrue);
    });

    test('a pending payment grants nothing yet', () async {
      // Cash at a counter, a wallet, some carrier billing — all common here,
      // and all of them return PENDING and settle later. Granting now would be
      // giving the product away.
      store.nextPurchase = const PurchaseAttempt(PurchaseOutcome.pending);

      final container = harness();
      final result = await container
          .read(entitlementsProvider.notifier)
          .buy(PurchaseProduct.proMonthly);

      expect(result.outcome, PurchaseOutcome.pending);
      expect(
        container.read(featureProvider(PaidFeature.fullDashaTimeline)),
        isFalse,
      );
    });

    test('a pending payment that settles later arrives on its own', () async {
      // Through the store listener and through nothing else — the app never
      // asks again, because the user has long since left the screen.
      final container = harness();
      await container.read(entitlementsProvider.notifier).start();

      store.pushUpdate(holding({Entitlement.pro: nextYear}));
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(featureProvider(PaidFeature.fullDashaTimeline)),
        isTrue,
      );
    });

    test('a cancelled purchase changes nothing at all', () async {
      await EntitlementCache(prefs).write(holding({Entitlement.adFree: null}));
      store.nextPurchase = const PurchaseAttempt(PurchaseOutcome.cancelled);

      final container = harness();
      await container
          .read(entitlementsProvider.notifier)
          .buy(PurchaseProduct.proYearly);

      expect(container.read(adFreeEntitlementProvider), isTrue);
    });
  });

  group('restoring', () {
    test('finds what the account already owns', () async {
      store.answer = holding({Entitlement.adFree: null});
      final container = harness();

      final outcome = await container
          .read(entitlementsProvider.notifier)
          .restore();

      expect(outcome, RestoreOutcome.restored);
      expect(container.read(adFreeEntitlementProvider), isTrue);
    });

    test('says so when the account owns nothing', () async {
      // A different sentence on screen from a failure. Someone tapping
      // Restore because they are seeing ads they paid to remove has to be told
      // which of the two happened.
      store.answer = EntitlementSnapshot.empty(now);
      final container = harness();

      expect(
        await container.read(entitlementsProvider.notifier).restore(),
        RestoreOutcome.nothingFound,
      );
    });

    test('says so when the store could not be reached', () async {
      store.answer = null;
      final container = harness();

      expect(
        await container.read(entitlementsProvider.notifier).restore(),
        RestoreOutcome.failed,
      );
    });

    test('says so in a build that cannot sell anything', () async {
      store.isReady = false;
      final container = harness();

      expect(
        await container.read(entitlementsProvider.notifier).restore(),
        RestoreOutcome.unavailable,
      );
      expect(store.restores, 0);
    });

    test('an expired subscription is not a restore', () async {
      // The store answered, and what it returned is past its date. Reporting
      // "restored" would leave the user staring at a screen that still shows
      // everything locked.
      store.answer = holding({
        Entitlement.pro: DateTime(2025, 12, 1),
      }, at: DateTime(2025, 12, 2));
      final container = harness();

      expect(
        await container.read(entitlementsProvider.notifier).restore(),
        RestoreOutcome.nothingFound,
      );
    });
  });

  group('signing out', () {
    test('leaves nothing of the previous account on screen', () async {
      await EntitlementCache(prefs).write(holding({Entitlement.pro: nextYear}));
      final container = harness();
      expect(container.read(adFreeEntitlementProvider), isTrue);

      store.answer = null;
      await container.read(entitlementsProvider.notifier).forget();

      expect(container.read(adFreeEntitlementProvider), isFalse);
      expect(EntitlementCache(prefs).read(), isNull);
      expect(store.forgets, 1);
    });
  });

  group('a build with no store', () {
    test('is a whole free app rather than a broken one', () async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          purchaseClockProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(purchasesAvailableProvider), isFalse);
      expect(container.read(adFreeEntitlementProvider), isFalse);
      expect(await container.read(storePricesProvider.future), isEmpty);

      final attempt = await container
          .read(entitlementsProvider.notifier)
          .buy(PurchaseProduct.removeAds);
      expect(attempt.outcome, PurchaseOutcome.unavailable);
    });
  });
}
