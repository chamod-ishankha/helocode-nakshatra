import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/onboarding/data/profile_repository.dart';
import 'ad_gate.dart';

/// Content a user can open by watching a rewarded video (KAN-34).
///
/// Rewarded video is the money-maker here: in a low-ARPU market the eCPM beats
/// banners by a wide margin, and people would far rather watch thirty seconds
/// than pay. That only works if what sits behind it is something they actually
/// want and can see they are missing.
enum RewardedUnlock {
  /// The per-koota and per-porondam breakdown. The score itself stays free —
  /// locking the number would make the screen worthless rather than tempting.
  compatibilityDetail,

  /// Any day after today. Looking back is free; looking ahead is the ask.
  futureDay,
}

/// Why an unlock is currently open, or what it would take to open it.
enum UnlockState {
  /// Bought. Nothing to watch, ever.
  purchased,

  /// Watched today.
  earned,

  /// No ads in this build, so the content cannot be held hostage to one.
  unavailable,

  /// Watchable now.
  locked,
}

/// Grants that last until the end of the local day.
///
/// ## Why the local day and not a duration
///
/// A 24-hour timer granted at 23:50 would expire tomorrow at 23:50, which
/// silently gives some users two days from one video and others one. Expiring
/// at the day boundary is what makes it a *daily* loop: everyone comes back
/// once a day, and the reset is a moment the user can predict.
class UnlockStore {
  UnlockStore({
    required SharedPreferences prefs,
    required bool hasEntitlement,
    required bool adsConfigured,
    DateTime Function()? clock,
  }) : _prefs = prefs,
       _hasEntitlement = hasEntitlement,
       _adsConfigured = adsConfigured,
       _clock = clock ?? DateTime.now;

  final SharedPreferences _prefs;
  final bool _hasEntitlement;
  final bool _adsConfigured;
  final DateTime Function() _clock;

  static String _key(RewardedUnlock u) => 'unlock.${u.name}';

  /// The local calendar day, as a sortable stamp.
  ///
  /// Deliberately local rather than UTC: the user's midnight is the one they
  /// experience, and in Sri Lanka (UTC+5:30) a UTC boundary would reset the
  /// loop at half past five in the morning.
  static String stampFor(DateTime local) =>
      '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';

  UnlockState state(RewardedUnlock unlock) {
    // Checked first so a purchase can never be overridden by a later rule.
    if (_hasEntitlement) return UnlockState.purchased;

    // A build with no ad unit ids can never play the video that opens this,
    // so locking it would make the content permanently unreachable. A fresh
    // clone with no env file must still be a whole app.
    if (!_adsConfigured) return UnlockState.unavailable;

    final stored = _prefs.getString(_key(unlock));
    if (stored != null && stored == stampFor(_clock())) {
      return UnlockState.earned;
    }
    return UnlockState.locked;
  }

  bool isOpen(RewardedUnlock unlock) => state(unlock) != UnlockState.locked;

  /// Records a reward that was actually earned.
  ///
  /// Only ever called after the SDK reports the reward. Calling it when the
  /// user dismissed the ad early would teach them that dismissing works.
  Future<void> grant(RewardedUnlock unlock) =>
      write(_prefs, unlock, clock: _clock);

  /// The same write, reachable without an [UnlockStore] instance.
  ///
  /// [UnlockNotifier] needs to persist a grant, but it cannot read
  /// [unlockStoreProvider] to do it: that provider watches the notifier, so
  /// reading it from inside is a dependency cycle. Riverpod throws, the throw
  /// kills the await in the card, and the button spins forever with the
  /// content still locked — which is how this was found.
  static Future<void> write(
    SharedPreferences prefs,
    RewardedUnlock unlock, {
    DateTime Function()? clock,
  }) => prefs.setString(_key(unlock), stampFor((clock ?? DateTime.now)()));

  Future<void> revokeAll() async {
    for (final u in RewardedUnlock.values) {
      await _prefs.remove(_key(u));
    }
  }
}

/// Bumped after every grant so watchers rebuild.
///
/// SharedPreferences has no change notification, so without this the screen
/// that asked for the unlock would keep showing the locked state until
/// something else happened to rebuild it.
class UnlockNotifier extends Notifier<int> {
  @override
  int build() => 0;

  Future<bool> earn(RewardedUnlock unlock) async {
    final earned = await ref.read(rewardedPresenterProvider)();
    if (!earned) return false;
    await UnlockStore.write(ref.read(sharedPreferencesProvider), unlock);
    state++;
    return true;
  }
}

final unlockRevisionProvider = NotifierProvider<UnlockNotifier, int>(
  UnlockNotifier.new,
);

/// Shows a rewarded ad, resolving true only if the reward was earned.
///
/// Indirected through a provider so the unlock logic can be tested without
/// the SDK: the real one is wired in [bootstrap].
final rewardedPresenterProvider = Provider<Future<bool> Function()>(
  (ref) =>
      () async => false,
);

final unlockStoreProvider = Provider<UnlockStore>((ref) {
  // Watched, not read: the revision rebuilds this after a grant, and buying
  // Remove Ads must open everything immediately rather than at next launch.
  ref.watch(unlockRevisionProvider);
  return UnlockStore(
    prefs: ref.watch(sharedPreferencesProvider),
    hasEntitlement: ref.watch(adFreeEntitlementProvider),
    adsConfigured: AdUnits.isConfigured,
  );
});
