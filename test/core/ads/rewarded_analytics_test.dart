import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/ads/ad_gate.dart';
import 'package:nakshatra/core/ads/rewarded_analytics.dart';
import 'package:nakshatra/core/ads/rewarded_interstitial.dart';
import 'package:nakshatra/core/ads/rewarded_unlock.dart';
import 'package:nakshatra/features/onboarding/data/profile_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The rewarded-ad events behind KAN-70's decision.
///
/// These numbers will decide whether the daily reset on the chart unlocks is
/// tightened — a change that moves real money between AdMob and Pro. A count
/// that double-fires, or quietly misses one path, would make that decision on
/// fiction. So every rule about when an event is and is not sent is pinned
/// here, and none of it depends on Firebase.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late List<(String, Map<String, Object>)> sent;

  void capture(String name, Map<String, Object> params) =>
      sent.add((name, params));

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    sent = [];
  });

  group('watching through the lock or the card', () {
    ProviderContainer containerWith({required bool rewardEarned}) {
      final c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          rewardedPresenterProvider.overrideWithValue(() async => rewardEarned),
          rewardedLogProvider.overrideWithValue(capture),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('an ad that pays out sends exactly one earned event', () async {
      final c = containerWith(rewardEarned: true);

      await c
          .read(unlockRevisionProvider.notifier)
          .earn(RewardedUnlock.navamsaChart);

      expect(sent, hasLength(1));
      expect(sent.single.$1, RewardedEvent.earned);
      expect(sent.single.$2, {'unlock': 'navamsaChart'});
    });

    test('an ad that does not pay out says so, once', () async {
      // No fill and an early dismiss are the same to the SDK. Both still
      // count: a lock people tap and never get through is exactly the thing
      // this measurement exists to find.
      final c = containerWith(rewardEarned: false);

      await c
          .read(unlockRevisionProvider.notifier)
          .earn(RewardedUnlock.dashaDetail);

      expect(sent, hasLength(1));
      expect(sent.single.$1, RewardedEvent.notEarned);
      expect(sent.single.$2, {'unlock': 'dashaDetail'});
    });

    test('two attempts are two events, one per unlock', () {
      // Asserting the order the log and the write happen in would be testing
      // the implementation. What matters is that one attempt is one event.
      final c = containerWith(rewardEarned: true);
      final notifier = c.read(unlockRevisionProvider.notifier);

      return Future.wait([
        notifier.earn(RewardedUnlock.futureDay),
        notifier.earn(RewardedUnlock.compatibilityDetail),
      ]).then((_) {
        expect(sent.map((e) => e.$1), [
          RewardedEvent.earned,
          RewardedEvent.earned,
        ]);
        expect(sent.map((e) => e.$2['unlock']).toSet(), {
          'futureDay',
          'compatibilityDetail',
        });
      });
    });

    test('an offer names the unlock and where it was offered', () {
      final c = containerWith(rewardEarned: true);

      c
          .read(unlockRevisionProvider.notifier)
          .offered(RewardedUnlock.navamsaChart, RewardedSurface.lock);
      c
          .read(unlockRevisionProvider.notifier)
          .offered(RewardedUnlock.futureDay, RewardedSurface.card);

      // Compared field by field: a record holding a Map is only == to itself.
      expect(sent.map((e) => e.$1), [
        RewardedEvent.offered,
        RewardedEvent.offered,
      ]);
      expect(sent[0].$2, {'unlock': 'navamsaChart', 'surface': 'lock'});
      expect(sent[1].$2, {'unlock': 'futureDay', 'surface': 'card'});
    });

    test('offering an ad records nothing as watched', () {
      final c = containerWith(rewardEarned: true);

      c
          .read(unlockRevisionProvider.notifier)
          .offered(RewardedUnlock.navamsaChart, RewardedSurface.lock);

      expect(prefs.getString('unlock.navamsaChart'), isNull);
    });
  });

  group('what the events may contain', () {
    test('only the unlock and the surface, never anything about the user', () {
      // The same rule as the purchase events. Four keys would be a leak
      // waiting for someone to add a birth date "just for debugging".
      for (final unlock in RewardedUnlock.values) {
        for (final surface in [...RewardedSurface.values, null]) {
          final params = rewardedParams(unlock, surface);
          expect(
            params.keys.toSet().difference({'unlock', 'surface'}),
            isEmpty,
          );
        }
      }
    });

    test('a missing surface is left out rather than sent as null', () {
      expect(rewardedParams(RewardedUnlock.futureDay), {'unlock': 'futureDay'});
    });

    test('every value fits Firebase limits', () {
      // Firebase drops an event with a name over 40 characters or a parameter
      // value over 100 — silently, which here would read as nobody watching.
      for (final name in [
        RewardedEvent.offered,
        RewardedEvent.earned,
        RewardedEvent.notEarned,
        RewardedEvent.interstitial,
      ]) {
        expect(name.length, lessThanOrEqualTo(40), reason: name);
        expect(name, matches(RegExp(r'^[a-z][a-z0-9_]*$')), reason: name);
      }
      for (final unlock in RewardedUnlock.values) {
        expect(unlock.name.length, lessThanOrEqualTo(100));
      }
    });
  });

  group('the chart-screen rewarded interstitial', () {
    final launched = DateTime(2026, 9, 13, 8);
    var now = launched.add(const Duration(minutes: 5));

    setUp(() => now = launched.add(const Duration(minutes: 5)));

    AdGate gate({bool entitled = false}) => AdGate(
      prefs: prefs,
      hasEntitlement: entitled,
      hasProfile: true,
      isConfigured: true,
      launchedAt: launched,
      clock: () => now,
    );

    UnlockStore unlocks() => UnlockStore(
      prefs: prefs,
      hasEntitlement: false,
      adsConfigured: true,
      clock: () => now,
    );

    RewardedInterstitialController controller(
      RewardedInterstitialOutcome outcome, {
      bool entitled = false,
    }) => RewardedInterstitialController(
      gate: gate(entitled: entitled),
      present: () async => outcome,
      preload: () async {},
      log: capture,
    );

    for (final outcome in RewardedInterstitialOutcome.values) {
      test(
        'an attempt that ended ${outcome.name} is recorded as such',
        () async {
          await controller(outcome).showIfAllowed(unlocks());

          expect(sent, hasLength(1));
          expect(sent.single.$1, RewardedEvent.interstitial);
          expect(sent.single.$2, {'outcome': outcome.name});
        },
      );
    }

    test('nothing is sent when the policy refuses the ad', () async {
      // Refused inside the cooldown, and refused for a purchaser. Neither is
      // an attempt, and counting them would make the fill rate look terrible
      // for a reason that has nothing to do with fill.
      await controller(
        RewardedInterstitialOutcome.earned,
      ).showIfAllowed(unlocks());
      sent.clear();

      await controller(
        RewardedInterstitialOutcome.earned,
      ).showIfAllowed(unlocks());
      expect(sent, isEmpty, reason: 'inside the cooldown');

      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      await controller(
        RewardedInterstitialOutcome.earned,
        entitled: true,
      ).showIfAllowed(unlocks());
      expect(sent, isEmpty, reason: 'a purchaser');
    });

    test(
      'nothing is sent once both rewards were already watched today',
      () async {
        await UnlockStore.write(
          prefs,
          RewardedUnlock.navamsaChart,
          clock: () => now,
        );
        await UnlockStore.write(
          prefs,
          RewardedUnlock.dashaDetail,
          clock: () => now,
        );

        await controller(
          RewardedInterstitialOutcome.earned,
        ).showIfAllowed(unlocks());

        expect(sent, isEmpty);
      },
    );

    test('a controller built without a logger still works', () async {
      // The default is a no-op, so every existing caller that never heard of
      // KAN-70 behaves exactly as it did.
      final plain = RewardedInterstitialController(
        gate: gate(),
        present: () async => RewardedInterstitialOutcome.earned,
        preload: () async {},
      );

      expect(await plain.showIfAllowed(unlocks()), isTrue);
    });
  });
}
