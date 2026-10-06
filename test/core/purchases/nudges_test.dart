import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/ads/ad_gate.dart';
import 'package:nakshatra/core/ads/rewarded_unlock.dart';
import 'package:nakshatra/core/config/flavor.dart';
import 'package:nakshatra/core/purchases/entitlements.dart';
import 'package:nakshatra/core/purchases/nudges.dart';
import 'package:nakshatra/core/purchases/purchase_controller.dart';
import 'package:nakshatra/features/onboarding/data/profile_repository.dart';
import 'package:nakshatra/features/purchases/presentation/pro_nudge.dart';
import 'package:nakshatra/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_purchase_gateway.dart';

/// Behavioural Pro nudges (KAN-75).
///
/// Every rule on the ticket is the ticket: a nudge that ignores the daily cap,
/// fires in the first session or comes back the day after it was dismissed is
/// the nagging this was built to avoid. So each rule is pinned here against
/// the store, with the clock and the launch under the test's control.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  final install = DateTime(2026, 9, 1, 9);
  final laterLaunch = DateTime(2026, 9, 2, 9);
  var now = DateTime(2026, 9, 2, 10);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    now = DateTime(2026, 9, 2, 10);
    // The install happened yesterday; the test runs in a later session.
    await NudgeStore.noteLaunch(prefs, install);
  });

  NudgeStore store({
    bool isPro = false,
    bool canBuy = true,
    DateTime? launchedAt,
  }) => NudgeStore(
    prefs: prefs,
    isPro: isPro,
    canBuy: canBuy,
    launchedAt: launchedAt ?? laterLaunch,
    clock: () => now,
  );

  /// Moves the clock on by whole days.
  void advance(int days) => now = now.add(Duration(days: days));

  /// Sees [unlock]'s lock once on each of [days] separate days.
  Future<void> seeOnDays(RewardedUnlock unlock, int days) async {
    for (var i = 0; i < days; i++) {
      await store().recordLockSeen(unlock);
      if (i < days - 1) advance(1);
    }
  }

  group('thresholds', () {
    test('the navāṁśa lock needs three separate days', () async {
      await seeOnDays(RewardedUnlock.navamsaChart, 2);
      expect(store().eligible(NudgeTrigger.navamsa), isFalse);

      advance(1);
      await store().recordLockSeen(RewardedUnlock.navamsaChart);
      expect(store().eligible(NudgeTrigger.navamsa), isTrue);
    });

    test('the compatibility lock needs three separate days', () async {
      await seeOnDays(RewardedUnlock.compatibilityDetail, 3);
      expect(store().eligible(NudgeTrigger.compatDetail), isTrue);
    });

    test('many sightings in one day count once', () async {
      // The compatibility screen swaps locks when the system toggle flips;
      // "you keep coming back" must not become true inside one visit.
      for (var i = 0; i < 10; i++) {
        await store().recordLockSeen(RewardedUnlock.compatibilityDetail);
      }
      expect(store().count(NudgeTrigger.compatDetail), 1);
      expect(store().eligible(NudgeTrigger.compatDetail), isFalse);
    });

    test(
      'one attempt at a second chart is enough for the family nudge',
      () async {
        await store().recordFamilyAttempt();
        expect(store().eligible(NudgeTrigger.family), isTrue);
      },
    );

    test('locks with no nudge of their own count nothing', () async {
      await seeOnDays(RewardedUnlock.dashaDetail, 5);
      await seeOnDays(RewardedUnlock.futureDay, 5);
      for (final t in NudgeTrigger.values) {
        expect(store().eligible(t), isFalse, reason: '$t');
      }
    });
  });

  group('the ad-watch count', () {
    test('five rewarded ads in the last seven days', () async {
      for (var i = 0; i < 4; i++) {
        await store().recordWatch();
      }
      expect(store().eligible(NudgeTrigger.adWatches), isFalse);

      await store().recordWatch();
      expect(store().eligible(NudgeTrigger.adWatches), isTrue);
      expect(store().count(NudgeTrigger.adWatches), 5);
    });

    test('watches older than the week fall out of the count', () async {
      // Four watches on day one, one a week later: the nudge quotes the real
      // number for *this* week, so it must say one, not five.
      for (var i = 0; i < 4; i++) {
        await store().recordWatch();
      }
      advance(7);
      await store().recordWatch();

      expect(store().count(NudgeTrigger.adWatches), 1);
      expect(store().eligible(NudgeTrigger.adWatches), isFalse);
    });

    test('the seventh day back is still inside the week', () async {
      for (var i = 0; i < 4; i++) {
        await store().recordWatch();
      }
      advance(6);
      await store().recordWatch();

      expect(store().count(NudgeTrigger.adWatches), 5);
    });
  });

  group('at most one nudge a day', () {
    test('claiming one takes today for every trigger', () async {
      await store().recordFamilyAttempt();
      await seeOnDays(RewardedUnlock.navamsaChart, 3);

      expect(await store().claim(NudgeTrigger.family), isTrue);
      expect(store().eligible(NudgeTrigger.navamsa), isFalse);
      expect(await store().claim(NudgeTrigger.navamsa), isFalse);
    });

    test('a second claim of the same nudge the same day is refused', () async {
      await store().recordFamilyAttempt();

      expect(await store().claim(NudgeTrigger.family), isTrue);
      expect(await store().claim(NudgeTrigger.family), isFalse);
    });

    test('tomorrow is a new day', () async {
      await store().recordFamilyAttempt();
      await seeOnDays(RewardedUnlock.navamsaChart, 3);
      await store().claim(NudgeTrigger.family);

      advance(1);
      expect(store().eligible(NudgeTrigger.navamsa), isTrue);
    });
  });

  group('never in the first session', () {
    test(
      'nothing is eligible in the session the app was installed in',
      () async {
        SharedPreferences.setMockInitialValues({});
        prefs = await SharedPreferences.getInstance();
        await NudgeStore.noteLaunch(prefs, install);

        final firstSession = store(launchedAt: install);
        await firstSession.recordFamilyAttempt();

        expect(firstSession.eligible(NudgeTrigger.family), isFalse);
        expect(store().eligible(NudgeTrigger.family), isTrue);
      },
    );

    test('only the first launch is ever recorded', () async {
      await NudgeStore.noteLaunch(prefs, laterLaunch);
      await NudgeStore.noteLaunch(prefs, DateTime(2026, 12, 1));

      // Still the September install, so a December launch is a later session.
      await store(launchedAt: DateTime(2026, 12, 1)).recordFamilyAttempt();
      expect(
        store(launchedAt: DateTime(2026, 12, 1)).eligible(NudgeTrigger.family),
        isTrue,
      );
    });
  });

  group('answering a nudge', () {
    test('it stays away for fourteen days', () async {
      await store().recordFamilyAttempt();
      await store().answered(NudgeTrigger.family);

      // Behaviour repeats straight away, and still nothing for thirteen days.
      await store().recordFamilyAttempt();
      advance(13);
      expect(store().eligible(NudgeTrigger.family), isFalse);

      advance(1);
      expect(store().eligible(NudgeTrigger.family), isTrue);
    });

    test(
      'its count starts again, so only new behaviour brings it back',
      () async {
        await seeOnDays(RewardedUnlock.navamsaChart, 3);
        await store().answered(NudgeTrigger.navamsa);

        advance(14);
        expect(store().count(NudgeTrigger.navamsa), 0);
        expect(store().eligible(NudgeTrigger.navamsa), isFalse);
      },
    );

    test('the ad-watch count starts again too', () async {
      for (var i = 0; i < 5; i++) {
        await store().recordWatch();
      }
      await store().answered(NudgeTrigger.adWatches);

      expect(store().count(NudgeTrigger.adWatches), 0);
    });

    test('snoozing one nudge leaves the others alone', () async {
      await store().recordFamilyAttempt();
      await seeOnDays(RewardedUnlock.navamsaChart, 3);

      await store().answered(NudgeTrigger.family);
      expect(store().eligible(NudgeTrigger.navamsa), isTrue);
    });
  });

  group('who never sees one', () {
    test('a Pro subscriber: nothing counted, nothing shown', () async {
      final pro = store(isPro: true);
      await pro.recordFamilyAttempt();
      await pro.recordWatch();
      await pro.recordLockSeen(RewardedUnlock.navamsaChart);

      // Not merely hidden — never counted, so lapsing does not unleash a
      // backlog of nudges built up while they were paying.
      for (final t in NudgeTrigger.values) {
        expect(store().count(t), 0, reason: '$t');
        expect(pro.eligible(t), isFalse, reason: '$t');
      }
    });

    test('anyone, in a build that cannot sell', () async {
      await store().recordFamilyAttempt();
      expect(store(canBuy: false).eligible(NudgeTrigger.family), isFalse);
    });
  });

  test('priority: the first eligible candidate wins', () async {
    await seeOnDays(RewardedUnlock.navamsaChart, 3);
    for (var i = 0; i < 5; i++) {
      await store().recordWatch();
    }

    expect(
      store().firstEligible([NudgeTrigger.navamsa, NudgeTrigger.adWatches]),
      NudgeTrigger.navamsa,
    );
    expect(
      store().firstEligible([NudgeTrigger.adWatches, NudgeTrigger.navamsa]),
      NudgeTrigger.adWatches,
    );
    expect(store().firstEligible([NudgeTrigger.family]), isNull);
  });

  group('through the providers', () {
    ProviderContainer container({
      required FakePurchaseGateway gateway,
      List<(String, Map<String, Object>)>? log,
    }) {
      final c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appLaunchedAtProvider.overrideWithValue(laterLaunch),
          purchaseGatewayProvider.overrideWithValue(gateway),
          nudgeLogProvider.overrideWithValue((n, p) => log?.add((n, p))),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('recording from a lock does not form a provider cycle', () async {
      // The same trap UnlockNotifier fell into: the store provider watches
      // the revision, so a notifier that reads the store from inside throws —
      // and the throw would land in the lock that called it.
      final c = container(gateway: FakePurchaseGateway());

      await c.read(nudgeRevisionProvider.notifier).familyAttempt();

      expect(c.read(nudgeStoreProvider).count(NudgeTrigger.family), 1);
    });

    test('a paid-out rewarded ad is counted as a watch', () async {
      final c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appLaunchedAtProvider.overrideWithValue(laterLaunch),
          purchaseGatewayProvider.overrideWithValue(FakePurchaseGateway()),
          rewardedPresenterProvider.overrideWithValue(() async => true),
        ],
      );
      addTearDown(c.dispose);

      await c
          .read(unlockRevisionProvider.notifier)
          .earn(RewardedUnlock.futureDay, day: DateTime(2026, 10, 8));
      // The watch is recorded without awaiting, like analytics.
      await Future<void>.delayed(Duration.zero);

      expect(c.read(nudgeStoreProvider).count(NudgeTrigger.adWatches), 1);
    });

    test('an ad that did not pay out is not counted', () async {
      final c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appLaunchedAtProvider.overrideWithValue(laterLaunch),
          purchaseGatewayProvider.overrideWithValue(FakePurchaseGateway()),
          rewardedPresenterProvider.overrideWithValue(() async => false),
        ],
      );
      addTearDown(c.dispose);

      await c
          .read(unlockRevisionProvider.notifier)
          .earn(RewardedUnlock.futureDay, day: DateTime(2026, 10, 8));
      await Future<void>.delayed(Duration.zero);

      expect(c.read(nudgeStoreProvider).count(NudgeTrigger.adWatches), 0);
    });

    test(
      'a Pro subscriber is not counted, even through the notifier',
      () async {
        final gateway = FakePurchaseGateway()
          ..answer = EntitlementSnapshot(
            grants: {
              Entitlement.pro: DateTime.now().add(const Duration(days: 30)),
            },
            refreshedAt: DateTime.now(),
          );
        final c = container(gateway: gateway);
        await c.read(entitlementsProvider.notifier).refresh();

        await c.read(nudgeRevisionProvider.notifier).familyAttempt();

        expect(prefs.getInt('nudge.count.family'), isNull);
      },
    );
  });

  group('the banner', () {
    late List<(String, Map<String, Object>)> log;

    setUp(() => log = []);

    Future<void> pump(WidgetTester tester, List<NudgeTrigger> triggers) async {
      FlavorConfig.initialize(Flavor.dev);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            appLaunchedAtProvider.overrideWithValue(laterLaunch),
            purchaseGatewayProvider.overrideWithValue(FakePurchaseGateway()),
            nudgeLogProvider.overrideWithValue((n, p) => log.add((n, p))),
          ],
          child: MaterialApp(
            localizationsDelegates: L10n.localizationsDelegates,
            supportedLocales: L10n.supportedLocales,
            home: Scaffold(body: ProNudge(triggers: triggers)),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders nothing when no nudge is due', (tester) async {
      await pump(tester, NudgeTrigger.values);

      expect(find.text('See Pro'), findsNothing);
      expect(log, isEmpty);
    });

    testWidgets('shows a due nudge once, and reports it', (tester) async {
      await prefs.setInt('nudge.count.family', 1);

      await pump(tester, [NudgeTrigger.family]);

      expect(
        find.text('Comparing another chart? Save the whole family with Pro.'),
        findsOneWidget,
      );
      expect(log.map((e) => e.$1), [NudgeEvent.shown]);
      expect(log.single.$2, {'trigger': 'family'});
    });

    testWidgets('closing it hides it, snoozes it, and says so', (tester) async {
      await prefs.setInt('nudge.count.family', 1);
      await pump(tester, [NudgeTrigger.family]);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('See Pro'), findsNothing);
      expect(log.map((e) => e.$1), [NudgeEvent.shown, NudgeEvent.dismissed]);
      expect(prefs.getString('nudge.snoozeUntil.family'), isNotNull);
    });

    testWidgets('the ad count it quotes is the real one', (tester) async {
      final today = UnlockStore.stampFor(DateTime.now());
      await prefs.setStringList('nudge.watches', List.filled(6, today));

      await pump(tester, [NudgeTrigger.adWatches]);

      expect(
        find.text('You have watched 6 ads this week. Pro has none.'),
        findsOneWidget,
      );
    });
  });
}
