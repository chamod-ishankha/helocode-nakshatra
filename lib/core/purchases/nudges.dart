import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/onboarding/data/profile_repository.dart';
import '../ads/ad_gate.dart';
import '../ads/rewarded_unlock.dart';
import '../logging/analytics_service.dart';
import 'entitlements.dart';
import 'purchase_controller.dart';

/// A behaviour worth one honest sentence about Pro (KAN-75).
enum NudgeTrigger {
  /// Came back to the locked porondam / koota breakdown.
  compatDetail,

  /// Came back to the locked navāṁśa.
  navamsa,

  /// Tried to add a second chart and met the gate.
  family,

  /// Watched several rewarded ads in the last week.
  adWatches,
}

/// When a nudge may be shown, and everything it has to remember (KAN-75).
///
/// A paywall shown at random is an interruption. The same offer shown because
/// the user just did the thing for the third time is an answer. What keeps
/// this on the right side of that line is here, not in the widgets, so every
/// rule is testable without a screen:
///
/// - **A real threshold.** The same lock seen on three separate days, one
///   attempt at a second chart, five rewarded ads in the last seven days.
/// - **At most one nudge a day**, across every trigger. Two in a session is
///   nagging.
/// - **Never in the first session.** Somebody who installed an hour ago has no
///   habit to be nudged about.
/// - **Fourteen days' quiet** after a nudge is dismissed *or* tapped, and its
///   count starts again from nothing — so it only returns if the behaviour
///   does.
/// - **Never to a Pro subscriber**, and nothing is even counted for one.
/// - **Never where Pro cannot be bought.** "See Pro" must lead somewhere.
///
/// Nothing here leaves the device. The counts are for deciding when to speak,
/// not for reporting on the user.
class NudgeStore {
  NudgeStore({
    required SharedPreferences prefs,
    required this.isPro,
    required this.canBuy,
    required DateTime launchedAt,
    DateTime Function()? clock,
  }) : _prefs = prefs,
       _launchedAt = launchedAt,
       _clock = clock ?? DateTime.now;

  final SharedPreferences _prefs;
  final DateTime _launchedAt;
  final DateTime Function() _clock;

  final bool isPro;
  final bool canBuy;

  static const String _firstLaunchKey = 'nudge.firstLaunch';
  static const String _lastShownKey = 'nudge.lastShown';
  static const String _watchesKey = 'nudge.watches';
  static String _countKey(NudgeTrigger t) => 'nudge.count.${t.name}';
  static String _countedDayKey(NudgeTrigger t) => 'nudge.countedOn.${t.name}';
  static String _snoozeKey(NudgeTrigger t) => 'nudge.snoozeUntil.${t.name}';

  /// How long a dismissed or tapped nudge stays away.
  static const int snoozeDays = 14;

  /// The rolling window for [NudgeTrigger.adWatches], today included.
  static const int watchWindowDays = 7;

  /// How much of a behaviour it takes before each nudge is worth saying.
  ///
  /// For the two locks this counts *days*, not sightings. The compatibility
  /// screen mounts a different lock when the system toggle flips, and a chart
  /// rebuilds constantly — counting those would reach three in one visit and
  /// make "you keep coming back" untrue.
  static int threshold(NudgeTrigger t) => switch (t) {
    NudgeTrigger.compatDetail => 3,
    NudgeTrigger.navamsa => 3,
    NudgeTrigger.family => 1,
    NudgeTrigger.adWatches => 5,
  };

  /// The nudge that a lock stands for, if it has one.
  static NudgeTrigger? forUnlock(RewardedUnlock unlock) => switch (unlock) {
    RewardedUnlock.compatibilityDetail => NudgeTrigger.compatDetail,
    RewardedUnlock.navamsaChart => NudgeTrigger.navamsa,
    RewardedUnlock.dashaDetail || RewardedUnlock.futureDay => null,
  };

  DateTime get _today {
    final now = _clock();
    return DateTime(now.year, now.month, now.day);
  }

  String get _todayStamp => UnlockStore.stampFor(_today);

  // ---------------------------------------------------------------- recording

  /// Records this install's first launch, once, ever.
  ///
  /// Called from bootstrap on every launch; only the first write sticks. That
  /// is what lets "never in the first session" mean the session the app was
  /// installed in, rather than whichever session first happened to count
  /// something.
  static Future<void> noteLaunch(SharedPreferences prefs, DateTime launchedAt) {
    if (prefs.getInt(_firstLaunchKey) != null) return Future.value();
    return prefs.setInt(_firstLaunchKey, launchedAt.millisecondsSinceEpoch);
  }

  /// The same, as a fallback for a store used before bootstrap wrote it.
  void _noteFirstLaunch() => unawaited(noteLaunch(_prefs, _launchedAt));

  /// A lock that stands for a nudge was on screen. Counts once per day.
  Future<void> recordLockSeen(RewardedUnlock unlock) async {
    final trigger = forUnlock(unlock);
    if (trigger == null || isPro) return;
    if (_prefs.getString(_countedDayKey(trigger)) == _todayStamp) return;
    await _prefs.setString(_countedDayKey(trigger), _todayStamp);
    await _bump(trigger);
  }

  /// Somebody without the feature tried to add a second chart.
  Future<void> recordFamilyAttempt() => _bump(NudgeTrigger.family);

  /// A rewarded ad paid out.
  Future<void> recordWatch() async {
    if (isPro) return;
    _noteFirstLaunch();
    final kept = _recentWatches()..add(_todayStamp);
    await _prefs.setStringList(_watchesKey, kept);
  }

  Future<void> _bump(NudgeTrigger trigger) async {
    // Not even counted for a subscriber. There is nothing to nudge them
    // towards, and a count that exists invites a use.
    if (isPro) return;
    _noteFirstLaunch();
    await _prefs.setInt(_countKey(trigger), count(trigger) + 1);
  }

  // ------------------------------------------------------------------ reading

  /// How many times the behaviour behind [trigger] has happened.
  ///
  /// For [NudgeTrigger.adWatches] this is the number of rewarded ads that paid
  /// out in the last [watchWindowDays] days — the number the nudge quotes, so
  /// it has to be the real one.
  int count(NudgeTrigger trigger) => switch (trigger) {
    NudgeTrigger.adWatches => _recentWatches().length,
    _ => _prefs.getInt(_countKey(trigger)) ?? 0,
  };

  List<String> _recentWatches() {
    final t = _today;
    final oldest = UnlockStore.stampFor(
      DateTime(t.year, t.month, t.day - (watchWindowDays - 1)),
    );
    // Stamps sort as strings, so the window is a string comparison.
    return (_prefs.getStringList(_watchesKey) ?? const [])
        .where((stamp) => stamp.compareTo(oldest) >= 0)
        .toList();
  }

  bool get _isFirstSession {
    final first = _prefs.getInt(_firstLaunchKey);
    // Never recorded means nothing has happened yet on this install — which
    // is itself the first session.
    return first == null || first >= _launchedAt.millisecondsSinceEpoch;
  }

  bool get _shownToday => _prefs.getString(_lastShownKey) == _todayStamp;

  bool _snoozed(NudgeTrigger trigger) {
    final until = _prefs.getString(_snoozeKey(trigger));
    return until != null && _todayStamp.compareTo(until) < 0;
  }

  /// Whether [trigger] may be shown right now.
  bool eligible(NudgeTrigger trigger) =>
      !isPro &&
      canBuy &&
      !_isFirstSession &&
      !_shownToday &&
      !_snoozed(trigger) &&
      count(trigger) >= threshold(trigger);

  /// The first of [triggers] that may be shown, if any.
  NudgeTrigger? firstEligible(Iterable<NudgeTrigger> triggers) {
    for (final t in triggers) {
      if (eligible(t)) return t;
    }
    return null;
  }

  // -------------------------------------------------------------- the outcome

  /// Takes today's one nudge for [trigger], if it is still available.
  ///
  /// Returns false when it is not, which is the only safe answer to two
  /// screens asking at once: whoever claims first shows it, and the other
  /// shows nothing.
  Future<bool> claim(NudgeTrigger trigger) async {
    if (!eligible(trigger)) return false;
    await _prefs.setString(_lastShownKey, _todayStamp);
    return true;
  }

  /// The user answered the nudge, by dismissing it or by tapping through.
  ///
  /// Either way it goes quiet for [snoozeDays] and its count starts again, so
  /// it can only come back if the behaviour does. A tap is included on
  /// purpose: somebody who opened the paywall and did not buy has heard the
  /// offer, and repeating it tomorrow is exactly what this is meant to avoid.
  Future<void> answered(NudgeTrigger trigger) async {
    final t = _today;
    await _prefs.setString(
      _snoozeKey(trigger),
      UnlockStore.stampFor(DateTime(t.year, t.month, t.day + snoozeDays)),
    );
    if (trigger == NudgeTrigger.adWatches) {
      await _prefs.remove(_watchesKey);
    } else {
      await _prefs.remove(_countKey(trigger));
    }
  }
}

/// Records behaviour, and bumps so a waiting nudge can reconsider.
///
/// The recording methods build their own [NudgeStore] from its dependencies
/// rather than reading [nudgeStoreProvider]: that provider watches this one,
/// so reading it from in here is a dependency cycle. Riverpod would throw, the
/// throw would land in whatever lock or button called it, and a count nobody
/// needs would take a screen down with it.
class NudgeRevision extends Notifier<int> {
  @override
  int build() => 0;

  NudgeStore _store() {
    final now = ref.read(purchaseClockProvider)();
    return NudgeStore(
      prefs: ref.read(sharedPreferencesProvider),
      isPro: ref.read(entitlementsProvider).isActive(Entitlement.pro, now),
      canBuy: ref.read(purchasesAvailableProvider),
      launchedAt: ref.read(appLaunchedAtProvider),
    );
  }

  Future<void> _record(Future<void> Function(NudgeStore) write) async {
    try {
      await write(_store());
      state++;
    } on Object {
      // A count is never worth an error on screen.
    }
  }

  Future<void> lockSeen(RewardedUnlock unlock) =>
      _record((s) => s.recordLockSeen(unlock));

  Future<void> familyAttempt() => _record((s) => s.recordFamilyAttempt());

  Future<void> watched() => _record((s) => s.recordWatch());

  Future<bool> claim(NudgeTrigger trigger) async {
    final ok = await _store().claim(trigger);
    if (ok) state++;
    return ok;
  }

  Future<void> answered(NudgeTrigger trigger) async {
    await _store().answered(trigger);
    state++;
  }
}

final nudgeRevisionProvider = NotifierProvider<NudgeRevision, int>(
  NudgeRevision.new,
);

final nudgeStoreProvider = Provider<NudgeStore>((ref) {
  ref.watch(nudgeRevisionProvider);
  final now = ref.watch(purchaseClockProvider)();
  return NudgeStore(
    prefs: ref.watch(sharedPreferencesProvider),
    isPro: ref.watch(entitlementsProvider).isActive(Entitlement.pro, now),
    canBuy: ref.watch(purchasesAvailableProvider),
    launchedAt: ref.watch(appLaunchedAtProvider),
  );
});

/// Sends a nudge event. Overridden in tests to capture instead.
final nudgeLogProvider = Provider<void Function(String, Map<String, Object>)>(
  (ref) =>
      (name, params) => unawaited(AnalyticsService.log(name, params)),
);

abstract final class NudgeEvent {
  static const shown = 'nudge_shown';
  static const tapped = 'nudge_tapped';
  static const dismissed = 'nudge_dismissed';
}
