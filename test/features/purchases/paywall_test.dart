import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/config/app_locale.dart';
import 'package:nakshatra/core/ads/rewarded_unlock.dart';
import 'package:nakshatra/core/config/flavor.dart';
import 'package:nakshatra/core/purchases/entitlements.dart';
import 'package:nakshatra/core/purchases/products.dart';
import 'package:nakshatra/core/purchases/purchase_controller.dart';
import 'package:nakshatra/core/theme/app_theme.dart';
import 'package:nakshatra/features/onboarding/data/profile_repository.dart';
import 'package:nakshatra/features/purchases/presentation/paywall.dart';
import 'package:nakshatra/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_purchase_gateway.dart';
import '../../support/fonts.dart';

/// The paywall (KAN-36).
///
/// Two things are worth pumping rather than reading: that it draws in Sinhala
/// and Tamil on a cheap phone without overflowing, and that it never shows a
/// price the store did not give it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadAppFonts);

  late SharedPreferences prefs;
  late FakePurchaseGateway store;

  StorePrice price(PurchaseProduct product, double amount, {int trial = 0}) =>
      StorePrice(
        product: product,
        formatted: 'LKR ${amount.toStringAsFixed(0)}',
        currencyCode: 'LKR',
        amount: amount,
        freeTrialDays: trial,
      );

  /// The intended ladder from KAN-35.
  List<StorePrice> ladder() => [
    price(PurchaseProduct.proMonthly, 490),
    price(PurchaseProduct.proYearly, 3900),
    price(PurchaseProduct.removeAds, 750),
  ];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    FlavorConfig.initialize(Flavor.dev);
    store = FakePurchaseGateway()..catalogue = ladder();
  });

  Future<void> open(
    WidgetTester tester, {
    AppLocale locale = AppLocale.en,
    PaywallReason reason = PaywallReason.general,
    EntitlementSnapshot? held,
  }) async {
    // A 360x640 logical screen: the cheap Android phones this app is aimed at.
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        purchaseGatewayProvider.overrideWithValue(store),
      ],
    );
    addTearDown(container.dispose);

    // What the user already owns, as the store would report it on launch.
    if (held != null) {
      store.answer = held;
      await container.read(entitlementsProvider.notifier).refresh();
    }

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: Locale(locale.code),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          theme: AppTheme.light(locale),
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showPaywall(context, ref, reason: reason),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  for (final locale in AppLocale.values) {
    testWidgets('the paywall fits in ${locale.englishName}', (tester) async {
      // Sinhala and Tamil run taller and longer than the English this was
      // composed in, and a paywall that overflows is money on the floor —
      // it is the one screen whose whole job is to be read and acted on.
      await open(tester, locale: locale);

      expect(
        tester.takeException(),
        isNull,
        reason: 'the paywall broke in ${locale.englishName}',
      );

      // What this does and does not prove. The sheet scrolls, so it will not
      // overflow vertically however long the copy runs — the exception check
      // is really about the Rows inside it. Deliberately squeezing the tier
      // row did not trip it, so treat that as untested; what is checked is
      // that both prices actually render in this script, and that no row has
      // been squeezed into a vertical ribbon, which is the shape KAN-60 took
      // in Tamil without ever throwing.
      expect(find.text('LKR 490'), findsOneWidget);
      expect(find.text('LKR 3900'), findsOneWidget);

      for (var i = 0; i < find.byType(Card).evaluate().length; i++) {
        final height = tester.getSize(find.byType(Card).at(i)).height;
        // 200 since KAN-91: the redesigned tier card is taller by design —
        // a 52px pill button and a 24px display-face price — and in this test
        // Latin draws in the wide placeholder face. The failure this guards
        // against is KAN-60's, a row squeezed into a ribbon several hundred
        // pixels tall, which 200 still catches.
        expect(
          height,
          lessThan(200),
          reason:
              'a tier row is ${height.toStringAsFixed(0)}px tall in '
              '${locale.englishName} — its text column has been squeezed',
        );
      }
    });
  }

  testWidgets('the saving is worked out from the store prices', (tester) async {
    // LKR 490 a month is LKR 5,880 a year against LKR 3,900 — a 34% saving.
    // Written into the copy it would go stale the day a price changes in Play
    // Console, and a stale discount claim is how an app gets pulled.
    await open(tester);

    expect(find.text('Save 34%'), findsOneWidget);
  });

  testWidgets('no trial is claimed when the store offers none', (tester) async {
    await open(tester);

    expect(find.textContaining('days free'), findsNothing);
  });

  testWidgets('a trial is shown when the store really gives one', (
    tester,
  ) async {
    store.catalogue = [
      price(PurchaseProduct.proMonthly, 490),
      price(PurchaseProduct.proYearly, 3900, trial: 7),
    ];

    await open(tester);

    expect(find.textContaining('7 days free'), findsOneWidget);
  });

  testWidgets('a store that says nothing offers nothing to buy', (
    tester,
  ) async {
    // The important negative. With no prices there must be no row that looks
    // buyable, and above all no number — a price written into the app is one
    // it cannot honour.
    store.catalogue = const [];

    await open(tester);

    expect(find.textContaining('LKR'), findsNothing);
    expect(find.byType(Card), findsNothing);
    expect(
      find.text('Prices are not available right now. Please try again later.'),
      findsOneWidget,
    );
  });

  testWidgets('a contextual paywall says what it was opened for', (
    tester,
  ) async {
    await open(tester, reason: PaywallReason.compatibilityDetail);

    expect(find.text('See the full compatibility working'), findsOneWidget);
  });

  testWidgets('opening it from settings has no contextual line', (
    tester,
  ) async {
    await open(tester);

    expect(find.text('See the full compatibility working'), findsNothing);
    expect(find.text('Look further ahead'), findsNothing);
  });

  testWidgets('the free video path is hidden when ads cannot play', (
    tester,
  ) async {
    // A test build has no ad unit ids, so the video could never run. Offering
    // it would be a button that does nothing — the device check for the other
    // half of this rule is on the ticket.
    await open(tester, reason: PaywallReason.futureDay);

    expect(find.text('Or watch a short video'), findsNothing);
  });

  testWidgets('every rewarded unlock has a paywall to sit beside', (
    tester,
  ) async {
    // KAN-36 asks for the paid option next to the free one everywhere the
    // free one appears. This is the mapping that makes that possible.
    for (final unlock in RewardedUnlock.values) {
      expect(PaywallReason.forUnlock(unlock).rewarded, unlock);
    }
  });

  group('KAN-71: the purchase controls a buyer sees', () {
    testWidgets('yearly comes first, because it is the highlighted plan', (
      tester,
    ) async {
      await open(tester);

      final yearly = tester.getTopLeft(find.text('Get Pro yearly'));
      final monthly = tester.getTopLeft(find.text('Get Pro monthly'));
      expect(yearly.dy, lessThan(monthly.dy));
    });

    testWidgets('each button names the period it bills for, and buys it', (
      tester,
    ) async {
      await open(tester);

      await tester.ensureVisible(find.text('Get Pro monthly'));
      await tester.tap(find.text('Get Pro monthly'));
      await tester.pumpAndSettle();
      expect(store.bought, [PurchaseProduct.proMonthly]);
    });

    testWidgets('touching the price does not start a purchase', (tester) async {
      // The whole card used to be the button. Reading the price is not asking
      // to pay it.
      await open(tester);

      // Scrolled into view first. Below the fold a tap lands on nothing, and
      // this test would pass whether the card buys or not — which it did,
      // until a deliberately broken card proved it.
      await tester.ensureVisible(find.text('LKR 3900'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('LKR 3900'));
      await tester.pumpAndSettle();
      expect(store.bought, isEmpty);
    });

    testWidgets('the renewal terms sit between the plans and anything else', (
      tester,
    ) async {
      // Play requires price, period, renewal and cancellation to be clear
      // before the purchase. A line below the one-time products and the video
      // offer is not that.
      await open(tester);

      final legal = find.text(
        'Subscriptions renew automatically until cancelled. '
        'Cancel any time in Google Play.',
      );
      expect(legal, findsOneWidget);

      final lastPlan = tester.getBottomLeft(find.text('Get Pro monthly')).dy;
      final terms = tester.getTopLeft(legal).dy;
      final removeAds = tester
          .getTopLeft(find.textContaining('Just remove the ads'))
          .dy;

      expect(terms, greaterThan(lastPlan));
      expect(terms, lessThan(removeAds));
    });

    testWidgets('a sheet selling no subscription carries no renewal terms', (
      tester,
    ) async {
      store.catalogue = [price(PurchaseProduct.birthChartPdf, 1490)];

      await open(tester, reason: PaywallReason.birthChartPdf);

      expect(find.textContaining('renew automatically'), findsNothing);
    });

    testWidgets('there is a visible close button, and it closes the sheet', (
      tester,
    ) async {
      await open(tester);

      expect(find.byIcon(Icons.close), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Get Pro yearly'), findsNothing);
    });

    testWidgets('restore is on the sheet and asks the store', (tester) async {
      store.answer = EntitlementSnapshot.empty(DateTime.now());
      await open(tester);

      await tester.ensureVisible(find.text('Restore purchases'));
      await tester.tap(find.text('Restore purchases'));
      await tester.pumpAndSettle();

      expect(store.restores, 1);
    });

    testWidgets('restore is hidden in a build that cannot sell', (
      tester,
    ) async {
      store.isReady = false;
      await open(tester);

      expect(find.text('Restore purchases'), findsNothing);
    });

    testWidgets('a subscriber is told they have Pro, not sold it again', (
      tester,
    ) async {
      final until = DateTime.now().add(const Duration(days: 200));
      await open(
        tester,
        held: EntitlementSnapshot(
          grants: {Entitlement.pro: until},
          refreshedAt: DateTime.now(),
        ),
      );

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.textContaining('Pro until'), findsOneWidget);
      // No plan to buy, and no list of reasons to buy what they hold.
      expect(find.text('Get Pro yearly'), findsNothing);
      expect(find.text('Get Pro monthly'), findsNothing);
      expect(find.text('Understand your deeper chart'), findsNothing);
    });

    testWidgets('somebody who owns nothing sees no owned list', (tester) async {
      await open(tester);

      expect(find.byIcon(Icons.check_circle), findsNothing);
    });

    for (final locale in AppLocale.values) {
      testWidgets('the buttons and terms draw in ${locale.englishName}', (
        tester,
      ) async {
        await open(tester, locale: locale);

        expect(tester.takeException(), isNull);
        expect(find.byType(FilledButton), findsOneWidget);
        expect(find.byType(OutlinedButton), findsWidgets);
      });
    }
  });

  group('KAN-74: the benefit the user came for leads', () {
    test('every order is the whole list, once each', () {
      // Reordering must never drop a benefit or show one twice — the list is
      // what Pro promises, and gates_test ties each line to a real gate.
      for (final reason in PaywallReason.values) {
        final order = reason.benefitOrder;
        expect(order.toSet(), PaywallBenefit.values.toSet(), reason: '$reason');
        expect(order, hasLength(PaywallBenefit.values.length));
      }
    });

    test('each reason puts its own benefit first', () {
      expect(
        PaywallReason.multipleProfiles.benefitOrder.first,
        PaywallBenefit.profiles,
      );
      expect(
        PaywallReason.navamsaChart.benefitOrder.first,
        PaywallBenefit.charts,
      );
      expect(
        PaywallReason.dashaDetail.benefitOrder.first,
        PaywallBenefit.dasha,
      );
      expect(
        PaywallReason.compatibilityDetail.benefitOrder.first,
        PaywallBenefit.compat,
      );
    });

    test('a reason with no benefit of its own keeps the usual order', () {
      for (final reason in [
        PaywallReason.general,
        PaywallReason.futureDay,
        PaywallReason.birthChartPdf,
      ]) {
        expect(reason.benefitOrder, PaywallBenefit.values, reason: '$reason');
      }
    });

    testWidgets('opened from "Add a family member", family is read first', (
      tester,
    ) async {
      await open(tester, reason: PaywallReason.multipleProfiles);

      final family = tester.getTopLeft(
        find.text('Everyone at home, in one app'),
      );
      final noAds = tester.getTopLeft(
        find.text('Nothing between you and the almanac'),
      );
      expect(family.dy, lessThan(noAds.dy));
    });

    testWidgets('opened from Settings, no ads still comes first', (
      tester,
    ) async {
      await open(tester);

      final family = tester.getTopLeft(
        find.text('Everyone at home, in one app'),
      );
      final noAds = tester.getTopLeft(
        find.text('Nothing between you and the almanac'),
      );
      expect(noAds.dy, lessThan(family.dy));
    });
  });
}
