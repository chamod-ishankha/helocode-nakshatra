import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/onboarding/data/profile_repository.dart';
import 'entitlements.dart';
import 'purchase_controller.dart';

/// Something a Pro subscriber did with what they pay for (KAN-77).
enum ProUsage {
  /// Added another person's chart.
  chartAdded,

  /// Entered a partner's details and got a match.
  compatibilityCheck,

  /// Opened a daśā period to its third level.
  dashaExplored,
}

/// What this month's subscription has actually been used for (KAN-77).
///
/// Churn happens when a subscriber cannot remember why they pay. The meter on
/// the Pro tile is the answer, and it is only worth anything if every number
/// in it is true. So:
///
/// - **Counted only while Pro is active.** The heading says "this month with
///   Nakshatra Pro"; a chart added the week before subscribing was not added
///   with Pro, and counting it would make the line a small lie. This is also
///   why these counts do not share [NudgeStore]'s: the nudges count only
///   people *without* Pro. The two stores count opposite populations.
/// - **Reset on the first of the month.** A count read in October never
///   includes September.
/// - **Nothing padded, nothing converted.** No "you saved LKR X" — turning
///   ads not shown into money is a claim about what those ads would have been
///   worth, and this app cannot back it.
///
/// Nothing here leaves the device.
class ProUsageStore {
  ProUsageStore({
    required SharedPreferences prefs,
    required this.isPro,
    DateTime Function()? clock,
  }) : _prefs = prefs,
       _clock = clock ?? DateTime.now;

  final SharedPreferences _prefs;
  final DateTime Function() _clock;
  final bool isPro;

  static const String _monthKey = 'proUsage.month';
  static String _countKey(ProUsage u) => 'proUsage.count.${u.name}';

  /// The local calendar month, as a sortable stamp.
  static String monthStamp(DateTime local) =>
      '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}';

  String get _thisMonth => monthStamp(_clock());

  bool get _storedIsThisMonth => _prefs.getString(_monthKey) == _thisMonth;

  /// How many times [usage] happened with Pro active, this calendar month.
  int count(ProUsage usage) =>
      _storedIsThisMonth ? (_prefs.getInt(_countKey(usage)) ?? 0) : 0;

  /// Records one [usage]. Does nothing unless Pro is active right now.
  Future<void> record(ProUsage usage) async {
    if (!isPro) return;

    // A new month starts every count at nothing before adding this one.
    if (!_storedIsThisMonth) {
      for (final u in ProUsage.values) {
        await _prefs.remove(_countKey(u));
      }
      await _prefs.setString(_monthKey, _thisMonth);
    }
    await _prefs.setInt(_countKey(usage), count(usage) + 1);
  }
}

/// Records usage, and bumps so the meter redraws.
///
/// Builds its own [ProUsageStore] rather than reading [proUsageStoreProvider],
/// which watches this notifier — reading it from inside would be a provider
/// cycle, and the throw would land in the screen that recorded the usage.
class ProUsageRevision extends Notifier<int> {
  @override
  int build() => 0;

  Future<void> record(ProUsage usage) async {
    try {
      final now = ref.read(purchaseClockProvider)();
      await ProUsageStore(
        prefs: ref.read(sharedPreferencesProvider),
        isPro: ref.read(entitlementsProvider).isActive(Entitlement.pro, now),
      ).record(usage);
      state++;
    } on Object {
      // A count is never worth an error on screen.
    }
  }
}

final proUsageRevisionProvider = NotifierProvider<ProUsageRevision, int>(
  ProUsageRevision.new,
);

final proUsageStoreProvider = Provider<ProUsageStore>((ref) {
  ref.watch(proUsageRevisionProvider);
  final now = ref.watch(purchaseClockProvider)();
  return ProUsageStore(
    prefs: ref.watch(sharedPreferencesProvider),
    isPro: ref.watch(entitlementsProvider).isActive(Entitlement.pro, now),
  );
});
