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
}
