import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/ads/ad_gate.dart';
import 'package:nakshatra/core/ads/interstitial.dart';
import 'package:nakshatra/core/ads/rewarded_interstitial.dart';
import 'package:nakshatra/core/ads/rewarded_unlock.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The rewarded interstitial on the chart screen (KAN-55 placement 2).
///
/// The controller is built directly rather than through a container, matching
/// `interstitial_test.dart`: what is under test is the policy, and Riverpod
/// adds nothing to that but ceremony.
void main() {
  late SharedPreferences prefs;

  final launched = DateTime(2026, 9, 11, 8);
  var now = launched.add(const Duration(minutes: 5));

  AdGate gate({
    bool entitled = false,
    bool configured = true,
    bool profile = true,
  }) => AdGate(
    prefs: prefs,
    hasEntitlement: entitled,
    hasProfile: profile,
    isConfigured: configured,
    launchedAt: launched,
    clock: () => now,
  );

  UnlockStore unlocks({bool entitled = false, bool adsConfigured = true}) =>
      UnlockStore(
        prefs: prefs,
        hasEntitlement: entitled,
        adsConfigured: adsConfigured,
        clock: () => now,
      );

  /// A controller whose ad always resolves to [outcome], counting the asks.
  ({
    RewardedInterstitialController controller,
    int Function() shows,
    int Function() loads,
  })
  build(RewardedInterstitialOutcome outcome, {bool entitled = false}) {
    var shows = 0;
    var loads = 0;

    return (
      controller: RewardedInterstitialController(
        gate: gate(entitled: entitled),
        present: () async {
          shows++;
          return outcome;
        },
        preload: () async => loads++,
      ),
      shows: () => shows,
      loads: () => loads,
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    now = launched.add(const Duration(minutes: 5));
  });

  group('when it may appear', () {
    test('a watched ad pays out and spends the cooldown', () async {
      final ad = build(RewardedInterstitialOutcome.earned);

      expect(await ad.controller.showIfAllowed(unlocks()), isTrue);
      expect(ad.shows(), 1);

      // Straight back to the chart. The cooldown is what stops a second one.
      expect(await ad.controller.showIfAllowed(unlocks()), isFalse);
      expect(ad.shows(), 1);
    });

    test('the cooldown expires after three minutes', () async {
      final first = build(RewardedInterstitialOutcome.earned);
      await first.controller.showIfAllowed(unlocks());

      now = now.add(const Duration(minutes: 3, seconds: 1));

      final second = build(RewardedInterstitialOutcome.earned);
      expect(await second.controller.showIfAllowed(unlocks()), isTrue);
    });
  });

  group('what spends the cooldown', () {
    test('an ad shown but skipped spends it, and pays nothing', () async {
      // They sat through part of a full-screen ad. Charging them again three
      // seconds later because they did not finish it would be the worst
      // reading of this placement.
      final ad = build(RewardedInterstitialOutcome.shownOnly);

      expect(await ad.controller.showIfAllowed(unlocks()), isFalse);

      final next = build(RewardedInterstitialOutcome.earned);
      expect(await next.controller.showIfAllowed(unlocks()), isFalse);
    });

    test('an ad that never filled spends nothing', () async {
      // No fill is the common case in a small market. Treating it as an
      // interruption would mean the worse the fill rate got, the fewer ads
      // anyone saw — and the less the app earned.
      final ad = build(RewardedInterstitialOutcome.notShown);

      expect(await ad.controller.showIfAllowed(unlocks()), isFalse);

      final next = build(RewardedInterstitialOutcome.earned);
      expect(await next.controller.showIfAllowed(unlocks()), isTrue);
    });

    test('it shares the cooldown with the plain interstitial', () async {
      // Two full-screen ads a minute apart are two interruptions however the
      // second one is labelled. They write the same timestamp.
      final plain = InterstitialController(
        gate: gate(),
        present: () async => true,
        preload: () async {},
      );
      expect(await plain.showIfAllowed(), isTrue);

      final ad = build(RewardedInterstitialOutcome.earned);
      expect(await ad.controller.showIfAllowed(unlocks()), isFalse);
    });

    test('and the plain interstitial respects this one', () async {
      final ad = build(RewardedInterstitialOutcome.earned);
      expect(await ad.controller.showIfAllowed(unlocks()), isTrue);

      final plain = InterstitialController(
        gate: gate(),
        present: () async => true,
        preload: () async {},
      );
      expect(await plain.showIfAllowed(), isFalse);
    });
  });

  group('warming the next one', () {
    test('a skipped ad leaves another loading', () async {
      // Showing consumes the loaded ad. Without a reload the placement is
      // dead for the rest of the session however long it runs — which is
      // exactly what the device showed before this existed.
      final ad = build(RewardedInterstitialOutcome.shownOnly);

      await ad.controller.showIfAllowed(unlocks());

      expect(ad.loads(), 1);
    });

    test('a failed fill leaves another loading', () async {
      final ad = build(RewardedInterstitialOutcome.notShown);

      await ad.controller.showIfAllowed(unlocks());

      expect(ad.loads(), 1);
    });

    test(
      'a watched ad does not, because there is nothing left to sell',
      () async {
        // They hold both rewards until midnight. Loading an ad that cannot be
        // shown spends their data for nothing.
        final ad = build(RewardedInterstitialOutcome.earned);

        expect(await ad.controller.showIfAllowed(unlocks()), isTrue);

        expect(ad.loads(), 0);
      },
    );

    test('a refusal loads nothing, because nothing was consumed', () async {
      now = launched.add(const Duration(seconds: 30));
      final ad = build(RewardedInterstitialOutcome.earned);

      await ad.controller.showIfAllowed(unlocks());

      expect(ad.loads(), 0);
    });
  });

  group('who never sees it', () {
    test('somebody who bought Remove Ads', () async {
      final ad = build(RewardedInterstitialOutcome.earned, entitled: true);

      await ad.controller.prepare(unlocks(entitled: true));
      expect(
        await ad.controller.showIfAllowed(unlocks(entitled: true)),
        isFalse,
      );

      expect(ad.loads(), 0, reason: 'a purchaser must not even be loaded for');
      expect(ad.shows(), 0);
    });

    test('anyone inside the session grace', () async {
      // A first-run user finishing onboarding is here, and it is the moment
      // an ad would do the most damage.
      now = launched.add(const Duration(seconds: 30));
      final ad = build(RewardedInterstitialOutcome.earned);

      expect(await ad.controller.showIfAllowed(unlocks()), isFalse);
    });

    test('anyone who already holds what it pays out', () async {
      // Nothing left to buy, so the interruption would be for nothing.
      for (final unlock in RewardedInterstitialController.reward) {
        await UnlockStore.write(prefs, unlock, clock: () => now);
      }

      final ad = build(RewardedInterstitialOutcome.earned);
      await ad.controller.prepare(unlocks());

      expect(await ad.controller.showIfAllowed(unlocks()), isFalse);
      expect(ad.loads(), 0);
      expect(ad.shows(), 0);
    });

    test('a build with no ad unit ids', () async {
      var loads = 0;
      final controller = RewardedInterstitialController(
        gate: gate(configured: false),
        present: () async => RewardedInterstitialOutcome.earned,
        preload: () async => loads++,
      );

      await controller.prepare(unlocks(adsConfigured: false));
      expect(
        await controller.showIfAllowed(unlocks(adsConfigured: false)),
        isFalse,
      );
      expect(loads, 0);
    });
  });

  test('yesterday\'s unlocks do not count as already held', () async {
    // The grants expire at the local day boundary, so a user who watched one
    // yesterday is a fresh prospect this morning.
    await UnlockStore.write(
      prefs,
      RewardedUnlock.navamsaChart,
      clock: () => now.subtract(const Duration(days: 1)),
    );
    await UnlockStore.write(
      prefs,
      RewardedUnlock.dashaDetail,
      clock: () => now.subtract(const Duration(days: 1)),
    );

    final ad = build(RewardedInterstitialOutcome.earned);
    await ad.controller.prepare(unlocks());

    expect(await ad.controller.showIfAllowed(unlocks()), isTrue);
    expect(ad.loads(), 1);
  });
}
