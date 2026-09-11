import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/purchases/entitlements.dart';
import 'package:nakshatra/core/purchases/products.dart';

/// The product ladder, and the arithmetic printed on the paywall (KAN-35).
void main() {
  StorePrice price(
    PurchaseProduct product,
    double amount, {
    String currency = 'LKR',
  }) => StorePrice(
    product: product,
    formatted: '$currency ${amount.toStringAsFixed(2)}',
    currencyCode: currency,
    amount: amount,
  );

  group('the ladder', () {
    test('product ids are unique and match Play Console naming', () {
      // These are typed into Play Console by hand and cannot be renamed once a
      // product exists. A mismatch is not a compile error — it is a paywall
      // row that silently never appears.
      final ids = PurchaseProduct.values.map((p) => p.id).toList();

      expect(ids.toSet(), hasLength(ids.length));
      for (final id in ids) {
        expect(id, matches(RegExp(r'^[a-z][a-z0-9_]*$')), reason: id);
      }
    });

    test('every product maps back from its id', () {
      for (final product in PurchaseProduct.values) {
        expect(PurchaseProduct.byId(product.id), product);
      }
      expect(PurchaseProduct.byId('lifetime_pro'), isNull);
    });

    test('a subscription maps back from the id the store returns', () {
      // KAN-68. Google Play has no subscription without a base plan, and
      // RevenueCat identifies one as `productId:basePlanId`. Matching on the
      // bare id looked right for as long as only the one-time products were
      // live in Play — those have no base plan, so they came back unchanged,
      // and the two Pro tiers were dropped from the paywall in silence.
      expect(
        PurchaseProduct.byStoreId('pro_monthly:monthly'),
        PurchaseProduct.proMonthly,
      );
      expect(
        PurchaseProduct.byStoreId('pro_yearly:yearly-autorenewing'),
        PurchaseProduct.proYearly,
      );

      // A one-time product arrives with no suffix and must still match.
      expect(
        PurchaseProduct.byStoreId('remove_ads'),
        PurchaseProduct.removeAds,
      );

      // Whatever the base plan is called, the product is what it belongs to.
      for (final product in PurchaseProduct.values) {
        expect(PurchaseProduct.byStoreId('${product.id}:p1m'), product);
      }

      // And an id that is genuinely not ours stays unmatched, suffix or not.
      expect(PurchaseProduct.byStoreId('lifetime_pro:monthly'), isNull);
    });

    test('both Pro tiers grant the same entitlement', () {
      // Otherwise switching between monthly and yearly would change what the
      // user can do, which is not what a tier is.
      for (final tier in PurchaseProduct.proTiers) {
        expect(tier.grants, Entitlement.pro);
        expect(tier.isSubscription, isTrue);
      }
    });

    test('only the Pro tiers are subscriptions', () {
      // Android will not return a one-time product under the subscription
      // category, so this split decides which query each product goes in. Get
      // it wrong and the product is simply absent, with no error anywhere.
      final subscriptions = PurchaseProduct.values
          .where((p) => p.isSubscription)
          .toSet();

      expect(subscriptions, PurchaseProduct.proTiers.toSet());
    });

    test('nothing is offered that unlocks nothing', () {
      // Found by running the sandbox end to end: compatibility_report showed
      // on the paywall at US$3.99 and grants an entitlement no feature gate
      // checks, so buying it would take money and change nothing.
      //
      // This list is the check. A product may only be on sale once something
      // in the app asks for what it grants — when the compatibility report is
      // built, add it back here and to PurchaseProduct.sellable together.
      expect(
        PurchaseProduct.onSale.map((p) => p.id),
        unorderedEquals([
          'remove_ads',
          'pro_monthly',
          'pro_yearly',
          'birth_chart_pdf',
        ]),
      );
      expect(PurchaseProduct.compatibilityReport.sellable, isFalse);
    });

    test('every entitlement can actually be bought', () {
      // An entitlement no product grants is a feature gate that can never
      // open — a screen locked forever with no way to pay for it.
      final grantable = PurchaseProduct.values.map((p) => p.grants).toSet();

      expect(grantable, Entitlement.values.toSet());
    });
  });

  group('the saving on the yearly tier', () {
    test('is computed from the store prices, not written into the copy', () {
      // The intended ladder: LKR 490 a month against LKR 3,900 a year. A year
      // of monthly is 5,880, so the yearly tier saves 34%. Writing "save 34%"
      // into the copy would go stale the day a price changes in Play Console,
      // and a stale discount claim is the kind of thing that gets an app
      // pulled.
      final monthly = price(PurchaseProduct.proMonthly, 490);
      final yearly = price(PurchaseProduct.proYearly, 3900);

      expect(yearly.savingAgainst(monthly), 34);
    });

    test('is null when the yearly tier is not actually cheaper', () {
      final monthly = price(PurchaseProduct.proMonthly, 300);
      final yearly = price(PurchaseProduct.proYearly, 4200);

      expect(yearly.annualised, 4200);
      expect(monthly.annualised, 3600);
      expect(yearly.savingAgainst(monthly), isNull);
    });

    test('is null across currencies', () {
      // Play prices each country separately, so two prices in different
      // currencies are not comparable at all. Subtracting them would print a
      // confident, meaningless percentage.
      final monthly = price(PurchaseProduct.proMonthly, 2.99, currency: 'USD');
      final yearly = price(PurchaseProduct.proYearly, 3900);

      expect(yearly.savingAgainst(monthly), isNull);
    });

    test('a one-time purchase has no yearly price to compare', () {
      final removeAds = price(PurchaseProduct.removeAds, 750);

      expect(removeAds.annualised, isNull);
      expect(
        removeAds.savingAgainst(price(PurchaseProduct.proMonthly, 490)),
        isNull,
      );
    });
  });

  group('what is already owned is not offered again', () {
    final now = DateTime(2026, 9, 10, 12);

    EntitlementSnapshot holding(Map<Entitlement, DateTime?> grants) =>
        EntitlementSnapshot(grants: grants, refreshedAt: now);

    test('a new user is offered the whole ladder', () {
      final nothing = EntitlementSnapshot.unknown();

      for (final product in PurchaseProduct.onSale) {
        expect(
          product.isRedundantFor(nothing, now),
          isFalse,
          reason: product.id,
        );
      }
    });

    test('the report comes off the sheet once it is bought', () {
      // Reported from the device: birth_chart_pdf was bought in the sandbox
      // and the paywall kept offering it. Play refuses the second purchase,
      // so the user would learn this from an error after a payment sheet.
      final held = holding({Entitlement.pdfReport: null});

      expect(PurchaseProduct.birthChartPdf.isRedundantFor(held, now), isTrue);
      expect(PurchaseProduct.removeAds.isRedundantFor(held, now), isFalse);
    });

    test('Pro hides remove_ads, which it already includes', () {
      // The case entitlement-comparison would miss: a Pro subscriber does not
      // hold ad_free, but they do have no ads, so remove_ads is money for
      // nothing.
      final pro = holding({Entitlement.pro: now.add(const Duration(days: 20))});

      expect(PurchaseProduct.removeAds.isRedundantFor(pro, now), isTrue);
      for (final tier in PurchaseProduct.proTiers) {
        expect(tier.isRedundantFor(pro, now), isTrue, reason: tier.id);
      }
      // Pro does not include the report, so that one stays for sale.
      expect(PurchaseProduct.birthChartPdf.isRedundantFor(pro, now), isFalse);
    });

    test('remove_ads does not hide Pro, which does much more', () {
      final adFree = holding({Entitlement.adFree: null});

      expect(PurchaseProduct.removeAds.isRedundantFor(adFree, now), isTrue);
      for (final tier in PurchaseProduct.proTiers) {
        expect(tier.isRedundantFor(adFree, now), isFalse, reason: tier.id);
      }
    });

    test('a lapsed subscription puts everything back on sale', () {
      // Well past the expiry and past the offline grace, with a refresh newer
      // than both — so this is the store's own answer, not a guess.
      final lapsed = EntitlementSnapshot(
        grants: {Entitlement.pro: now.subtract(const Duration(days: 30))},
        refreshedAt: now,
      );

      expect(PurchaseProduct.removeAds.isRedundantFor(lapsed, now), isFalse);
      expect(PurchaseProduct.proMonthly.isRedundantFor(lapsed, now), isFalse);
    });

    test('owning everything leaves nothing on sale', () {
      // What Settings uses to decide whether the row opens a paywall at all.
      final all = holding({for (final e in Entitlement.values) e: null});

      expect(
        PurchaseProduct.onSale.where((p) => !p.isRedundantFor(all, now)),
        isEmpty,
      );
    });

    test('every sellable product unlocks something', () {
      // isRedundantFor answers false for a product that opens nothing, so a
      // product like that would be offered forever, to everyone, and buying it
      // twice would still change nothing.
      for (final product in PurchaseProduct.onSale) {
        expect(product.unlocks, isNotEmpty, reason: product.id);
      }
    });
  });
}
