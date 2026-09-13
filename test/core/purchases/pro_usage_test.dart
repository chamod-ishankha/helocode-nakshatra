import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/config/flavor.dart';
import 'package:nakshatra/core/purchases/entitlements.dart';
import 'package:nakshatra/core/purchases/pro_usage.dart';
import 'package:nakshatra/core/purchases/purchase_controller.dart';
import 'package:nakshatra/features/compatibility/domain/compatibility_providers.dart';
import 'package:nakshatra/features/onboarding/data/profile_repository.dart';
import 'package:nakshatra/features/onboarding/domain/birth_profile.dart';
import 'package:nakshatra/features/purchases/presentation/pro_tiles.dart';
import 'package:nakshatra/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_purchase_gateway.dart';

/// The Pro value meter (KAN-77).
///
/// A subscriber reads these numbers as a statement of what they got for their
/// money, so a count that includes the week before they subscribed, or last
/// month, or a zero dressed up as an achievement, is a false statement. Each
/// of those is pinned here.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  var now = DateTime(2026, 9, 14, 10);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    now = DateTime(2026, 9, 14, 10);
  });

  ProUsageStore store({bool isPro = true}) =>
      ProUsageStore(prefs: prefs, isPro: isPro, clock: () => now);

  group('counting', () {
    test('each use adds one, while Pro is active', () async {
      await store().record(ProUsage.dashaExplored);
      await store().record(ProUsage.dashaExplored);
      await store().record(ProUsage.chartAdded);

      expect(store().count(ProUsage.dashaExplored), 2);
      expect(store().count(ProUsage.chartAdded), 1);
      expect(store().count(ProUsage.compatibilityCheck), 0);
    });

    test('nothing is counted without Pro', () async {
      // "This month with Nakshatra Pro" must not include the week before the
      // subscription started.
      await store(isPro: false).record(ProUsage.chartAdded);
      await store(isPro: false).record(ProUsage.dashaExplored);

      for (final u in ProUsage.values) {
        expect(store().count(u), 0, reason: '$u');
      }
    });
  });

  group('the month', () {
    test('a new month reads as nothing, before anything is recorded', () async {
      now = DateTime(2026, 9, 30, 23, 59);
      await store().record(ProUsage.compatibilityCheck);

      now = DateTime(2026, 10, 1, 0, 1);
      expect(store().count(ProUsage.compatibilityCheck), 0);
    });

    test('the first use in a new month starts every count again', () async {
      now = DateTime(2026, 9, 20);
      await store().record(ProUsage.chartAdded);
      await store().record(ProUsage.dashaExplored);
      await store().record(ProUsage.dashaExplored);

      now = DateTime(2026, 10, 2);
      await store().record(ProUsage.dashaExplored);

      expect(store().count(ProUsage.dashaExplored), 1);
      expect(store().count(ProUsage.chartAdded), 0);
    });

    test('the same month in a different year is a different month', () async {
      now = DateTime(2026, 9, 10);
      await store().record(ProUsage.chartAdded);

      now = DateTime(2027, 9, 10);
      expect(store().count(ProUsage.chartAdded), 0);
    });

    test('the month is the local one', () {
      expect(
        ProUsageStore.monthStamp(DateTime(2026, 9, 30, 23, 59)),
        '2026-09',
      );
      expect(ProUsageStore.monthStamp(DateTime(2026, 10, 1)), '2026-10');
    });
  });

  group('through the providers', () {
    final pro = EntitlementSnapshot(
      grants: {Entitlement.pro: DateTime.now().add(const Duration(days: 30))},
      refreshedAt: DateTime.now(),
    );

    Future<ProviderContainer> containerWith({required bool isPro}) async {
      final gateway = FakePurchaseGateway()..answer = isPro ? pro : null;
      final c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          purchaseGatewayProvider.overrideWithValue(gateway),
        ],
      );
      addTearDown(c.dispose);
      if (isPro) await c.read(entitlementsProvider.notifier).refresh();
      return c;
    }

    final partner = BirthProfile(
      name: 'Partner',
      birthDate: DateTime(1992, 3, 4),
      birthTime: Duration(hours: 6),
      birthTimeKnown: true,
      place: Place(
        en: 'Colombo',
        latitude: 6.9271,
        longitude: 79.8612,
        district: 'Colombo',
        timezone: 'Asia/Colombo',
      ),
    );

    test('entering a partner counts a compatibility check for Pro', () async {
      final c = await containerWith(isPro: true);

      c.read(partnerProvider.notifier).set(partner);
      await Future<void>.delayed(Duration.zero);

      expect(
        c.read(proUsageStoreProvider).count(ProUsage.compatibilityCheck),
        1,
      );
    });

    test('and counts nothing for anyone else', () async {
      final c = await containerWith(isPro: false);

      c.read(partnerProvider.notifier).set(partner);
      await Future<void>.delayed(Duration.zero);

      expect(prefs.getInt('proUsage.count.compatibilityCheck'), isNull);
    });

    test('recording does not form a provider cycle', () async {
      // The store provider watches the revision notifier; a notifier that
      // read the store from inside would throw into the screen that called it.
      final c = await containerWith(isPro: true);

      await c
          .read(proUsageRevisionProvider.notifier)
          .record(ProUsage.dashaExplored);

      expect(c.read(proUsageStoreProvider).count(ProUsage.dashaExplored), 1);
    });
  });

  group('the meter on the Pro tile', () {
    Future<void> pump(WidgetTester tester, {required bool isPro}) async {
      FlavorConfig.initialize(Flavor.dev);
      final gateway = FakePurchaseGateway()
        ..answer = isPro
            ? EntitlementSnapshot(
                grants: {
                  Entitlement.pro: DateTime.now().add(const Duration(days: 30)),
                },
                refreshedAt: DateTime.now(),
              )
            : null;
      final c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          purchaseGatewayProvider.overrideWithValue(gateway),
        ],
      );
      addTearDown(c.dispose);
      if (isPro) await c.read(entitlementsProvider.notifier).refresh();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            localizationsDelegates: L10n.localizationsDelegates,
            supportedLocales: L10n.supportedLocales,
            home: const Scaffold(
              body: SingleChildScrollView(child: ProTiles()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    /// Counts recorded this real month, since the widget uses the real clock.
    Future<void> seed(Map<ProUsage, int> counts) async {
      final real = ProUsageStore(prefs: prefs, isPro: true);
      for (final MapEntry(key: u, value: n) in counts.entries) {
        for (var i = 0; i < n; i++) {
          await real.record(u);
        }
      }
    }

    testWidgets('a subscriber sees the month, and only the real counts', (
      tester,
    ) async {
      await seed({ProUsage.chartAdded: 1, ProUsage.dashaExplored: 12});
      await pump(tester, isPro: true);

      expect(find.text('This month with Nakshatra Pro'), findsOneWidget);
      expect(find.text('1 family chart added'), findsOneWidget);
      expect(find.text('12 daśā periods explored'), findsOneWidget);
      expect(find.text('No ads while Pro is active'), findsOneWidget);
    });

    testWidgets('a count of zero is left out, not shown as zero', (
      tester,
    ) async {
      await seed({ProUsage.dashaExplored: 3});
      await pump(tester, isPro: true);

      expect(find.textContaining('compatibility check'), findsNothing);
      expect(find.textContaining('family chart'), findsNothing);
      expect(find.text('3 daśā periods explored'), findsOneWidget);
    });

    testWidgets('nobody without Pro sees it', (tester) async {
      await seed({ProUsage.dashaExplored: 5});
      await pump(tester, isPro: false);

      expect(find.text('This month with Nakshatra Pro'), findsNothing);
      expect(find.text('No ads while Pro is active'), findsNothing);
    });
  });
}
