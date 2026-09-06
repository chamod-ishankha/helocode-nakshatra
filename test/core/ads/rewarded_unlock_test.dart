import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/ads/rewarded_unlock.dart';
import 'package:nakshatra/features/onboarding/data/profile_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Rewarded unlock expiry (KAN-34).
///
/// The rule is "until the end of today", which is not the same as "for 24
/// hours" and not the same as "until UTC midnight". Both of those look right
/// in casual use and go wrong at the edges — one silently hands some users a
/// second day, the other resets the loop at half past five in the morning in
/// Sri Lanka. None of it is visible on screen, so it is tested here.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  UnlockStore store({
    bool entitled = false,
    bool configured = true,
    required DateTime now,
  }) =>
      UnlockStore(
        prefs: prefs,
        hasEntitlement: entitled,
        adsConfigured: configured,
        clock: () => now,
      );

  group('who never has to watch', () {
    test('a purchaser has everything open', () {
      final s = store(entitled: true, now: DateTime(2026, 9, 6, 10));
      for (final u in RewardedUnlock.values) {
        expect(s.state(u), UnlockState.purchased, reason: u.name);
        expect(s.isOpen(u), isTrue);
      }
    });

    test('purchase outranks an unconfigured build', () {
      final s = store(
        entitled: true,
        configured: false,
        now: DateTime(2026, 9, 6),
      );
      expect(s.state(RewardedUnlock.futureDay), UnlockState.purchased);
    });

    test('a build with no ad ids leaves the content open', () {
      // Otherwise a fresh clone, or a release built without the env file,
      // would hold content behind a video that can never play — content
      // locked forever with no way to reach it.
      final s = store(configured: false, now: DateTime(2026, 9, 6));
      for (final u in RewardedUnlock.values) {
        expect(s.state(u), UnlockState.unavailable, reason: u.name);
        expect(s.isOpen(u), isTrue);
      }
    });
  });

  group('earning and expiry', () {
    test('locked until something is earned', () {
      final s = store(now: DateTime(2026, 9, 6, 9));
      expect(s.state(RewardedUnlock.futureDay), UnlockState.locked);
      expect(s.isOpen(RewardedUnlock.futureDay), isFalse);
    });

    test('open for the rest of the same day', () async {
      await store(now: DateTime(2026, 9, 6, 9)).grant(RewardedUnlock.futureDay);

      expect(
        store(now: DateTime(2026, 9, 6, 23, 59)).state(RewardedUnlock.futureDay),
        UnlockState.earned,
      );
    });

    test('locked again the next calendar day', () async {
      await store(now: DateTime(2026, 9, 6, 9)).grant(RewardedUnlock.futureDay);

      expect(
        store(now: DateTime(2026, 9, 7, 9)).state(RewardedUnlock.futureDay),
        UnlockState.locked,
      );
    });

    test('a late-night grant expires at midnight, not 24 hours later',
        () async {
      // The case that separates a day pass from a 24-hour timer. Earned at
      // 23:50, a timer would still be running at 23:00 the following night
      // and would have given this user nearly two days from one video.
      await store(now: DateTime(2026, 9, 6, 23, 50))
          .grant(RewardedUnlock.futureDay);

      expect(
        store(now: DateTime(2026, 9, 7, 0, 1)).state(RewardedUnlock.futureDay),
        UnlockState.locked,
      );
    });

    test('unlocks do not open each other', () async {
      // Sharing one key would mean watching a video for tomorrow's nekath
      // also revealed the compatibility breakdown, halving the inventory.
      await store(now: DateTime(2026, 9, 6)).grant(RewardedUnlock.futureDay);

      final s = store(now: DateTime(2026, 9, 6));
      expect(s.state(RewardedUnlock.futureDay), UnlockState.earned);
      expect(s.state(RewardedUnlock.compatibilityDetail), UnlockState.locked);
    });

    test('revokeAll closes everything', () async {
      final s = store(now: DateTime(2026, 9, 6));
      for (final u in RewardedUnlock.values) {
        await s.grant(u);
      }
      await s.revokeAll();

      for (final u in RewardedUnlock.values) {
        expect(s.state(u), UnlockState.locked, reason: u.name);
      }
    });
  });

  group('the day stamp', () {
    test('is the local date, zero padded so it compares as text', () {
      expect(UnlockStore.stampFor(DateTime(2026, 9, 6, 23, 59)), '2026-09-06');
      expect(UnlockStore.stampFor(DateTime(2026, 12, 31)), '2026-12-31');
    });

    test('does not shift with the time of day', () {
      // Same day, opposite ends of it.
      expect(
        UnlockStore.stampFor(DateTime(2026, 9, 6, 0, 0)),
        UnlockStore.stampFor(DateTime(2026, 9, 6, 23, 59, 59)),
      );
    });

    test('a stored stamp from another day never matches today', () async {
      // Guards against a comparison that accidentally comes out true for
      // every value, which would make the lock permanently open.
      await store(now: DateTime(2026, 1, 1)).grant(RewardedUnlock.futureDay);

      for (final day in [
        DateTime(2025, 12, 31),
        DateTime(2026, 1, 2),
        DateTime(2026, 2, 1),
        DateTime(2027, 1, 1),
      ]) {
        expect(
          store(now: day).state(RewardedUnlock.futureDay),
          UnlockState.locked,
          reason: '$day',
        );
      }
    });
  });

  group('earning through the provider', () {
    // The store is only half the feature. Everything above was green while
    // the button on the device span forever: UnlockNotifier.earn read
    // unlockStoreProvider, which watches the notifier, so Riverpod threw
    // CircularDependencyError. The throw killed the await in the card, so
    // nothing ever cleared the spinner and the content stayed locked with
    // the reward already paid for. Driving earn() through a real container
    // is what catches that; testing the store alone never will.
    ProviderContainer containerWith({required bool rewardEarned}) {
      final c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          rewardedPresenterProvider.overrideWithValue(() async => rewardEarned),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('a watched video persists the unlock and bumps the revision',
        () async {
      final c = containerWith(rewardEarned: true);
      final before = c.read(unlockRevisionProvider);

      final ok = await c
          .read(unlockRevisionProvider.notifier)
          .earn(RewardedUnlock.futureDay);

      expect(ok, isTrue);
      expect(c.read(unlockRevisionProvider), greaterThan(before));
      // Persisted under today's stamp, so a rebuild reads it back as earned.
      expect(
        prefs.getString('unlock.futureDay'),
        UnlockStore.stampFor(DateTime.now()),
      );
    });

    test('a dismissed video grants nothing', () async {
      final c = containerWith(rewardEarned: false);

      final ok = await c
          .read(unlockRevisionProvider.notifier)
          .earn(RewardedUnlock.futureDay);

      expect(ok, isFalse);
      expect(prefs.getString('unlock.futureDay'), isNull);
    });

    test('the store provider resolves without a dependency cycle', () {
      // Reading it at all is the assertion: a cycle throws on first read.
      final c = containerWith(rewardEarned: true);
      expect(() => c.read(unlockStoreProvider), returnsNormally);
    });
  });
}
