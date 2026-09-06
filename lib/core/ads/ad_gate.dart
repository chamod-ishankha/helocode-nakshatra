import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/onboarding/data/profile_repository.dart';

/// The kinds of ad this app shows.
enum AdSlot {
  /// Always on at the bottom of the daily screen.
  banner,

  /// Full screen, shown between actions. The intrusive one, so the one the
  /// caps exist for.
  interstitial,

  /// Watched deliberately in exchange for something. The user asked for it,
  /// so it is not rate-limited the way the others are.
  rewarded,
}

/// Why an ad was withheld. Useful in logs, and in tests, where "no ad" with
/// no reason is indistinguishable from a bug.
enum AdRefusal {
  purchased,
  noProfileYet,
  withinSessionGrace,
  withinCooldown,
  notConfigured,
}

/// The numbers, in one place so they can be argued about without reading code.
abstract final class AdPolicy {
  /// From KAN-34: one interstitial per three minutes.
  static const Duration interstitialCooldown = Duration(minutes: 3);

  /// Nothing full-screen until the app has been open this long.
  ///
  /// "No ad before the user has seen any value" is the requirement. Someone
  /// who opens the app to check rāhu kālaya and is met with a full-screen ad
  /// uninstalls it, and this is a daily-use app — one bad first minute costs
  /// every future impression from that person.
  static const Duration sessionGrace = Duration(seconds: 90);
}

/// Decides whether an ad may be shown. Pure policy, no SDK.
///
/// Separated from the ad loading so it can be tested without a network, an
/// AdMob account, or a device. Every rule here is one that costs real money
/// when it is wrong — in refunds, in uninstalls, or in an AdMob ban.
class AdGate {
  AdGate({
    required SharedPreferences prefs,
    required this.hasEntitlement,
    required this.hasProfile,
    required this.isConfigured,
    required DateTime launchedAt,
    DateTime Function()? clock,
  })  : _prefs = prefs,
        _launchedAt = launchedAt,
        _clock = clock ?? DateTime.now;

  final SharedPreferences _prefs;
  final DateTime _launchedAt;
  final DateTime Function() _clock;

  /// True once the user has bought Remove Ads or any Pro tier.
  final bool hasEntitlement;

  /// Onboarding writes the profile. Before that the user has been given
  /// nothing, so there is nothing to interrupt.
  final bool hasProfile;

  /// Whether ad unit ids actually exist in this build.
  final bool isConfigured;

  static const _lastInterstitialKey = 'ad_last_interstitial_v1';

  /// Null when the ad may be shown, otherwise why not.
  AdRefusal? refuse(AdSlot slot) {
    if (hasEntitlement) return AdRefusal.purchased;
    if (!isConfigured) return AdRefusal.notConfigured;
    if (!hasProfile) return AdRefusal.noProfileYet;

    // A rewarded ad is something the user chose to watch in exchange for
    // something. Rate-limiting it would only withhold what they asked for.
    if (slot == AdSlot.rewarded) return null;

    // The banner sits in the layout rather than interrupting, so it needs no
    // grace period once there is a profile to see it alongside.
    if (slot == AdSlot.banner) return null;

    if (_clock().difference(_launchedAt) < AdPolicy.sessionGrace) {
      return AdRefusal.withinSessionGrace;
    }

    final last = _lastInterstitial;
    if (last != null &&
        _clock().difference(last) < AdPolicy.interstitialCooldown) {
      return AdRefusal.withinCooldown;
    }

    return null;
  }

  bool allows(AdSlot slot) => refuse(slot) == null;

  DateTime? get _lastInterstitial {
    final raw = _prefs.getInt(_lastInterstitialKey);
    return raw == null ? null : DateTime.fromMillisecondsSinceEpoch(raw);
  }

  /// Records that an interstitial was shown.
  ///
  /// Persisted rather than held in memory: otherwise killing and reopening
  /// the app resets the cooldown, and the three-minute rule would mean
  /// nothing to the user it is meant to protect.
  Future<void> recordShown(AdSlot slot) async {
    if (slot != AdSlot.interstitial) return;
    await _prefs.setInt(
      _lastInterstitialKey,
      _clock().millisecondsSinceEpoch,
    );
  }

  /// Clears the cooldown. Only for tests and for a purchase, where the
  /// history stops mattering.
  Future<void> reset() => _prefs.remove(_lastInterstitialKey);
}

/// When this launch started, for the session grace period.
///
/// Set once at startup. Reading `DateTime.now()` inside the gate instead would
/// make the grace period restart on every rebuild, which is to say never end.
final appLaunchedAtProvider = Provider<DateTime>(
  (ref) => throw UnimplementedError('appLaunchedAtProvider not overridden'),
);

/// Whether the user has paid to remove ads.
///
/// Always false until RevenueCat lands in KAN-35, which overrides this. It
/// exists now so every ad site is already asking the right question — wiring
/// entitlements later is then one provider, not an audit of every placement.
final adFreeEntitlementProvider = Provider<bool>((ref) => false);

final adGateProvider = Provider<AdGate>((ref) {
  return AdGate(
    prefs: ref.watch(sharedPreferencesProvider),
    hasEntitlement: ref.watch(adFreeEntitlementProvider),
    hasProfile: ref.watch(profileProvider) != null,
    isConfigured: AdUnits.isConfigured,
    launchedAt: ref.watch(appLaunchedAtProvider),
  );
});

/// Ad unit ids for this build.
///
/// The values come from `--dart-define-from-file`, so a fresh clone with no
/// env file gets empty strings and [isConfigured] turns every placement off
/// rather than crashing the SDK with a blank id.
abstract final class AdUnits {
  static const String banner = String.fromEnvironment(
    'ADMOB_BANNER_UNIT_ID',
  );
  static const String interstitial = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_UNIT_ID',
  );
  static const String rewarded = String.fromEnvironment(
    'ADMOB_REWARDED_UNIT_ID',
  );

  /// Devices that must always be served test creatives, comma separated.
  ///
  /// ## Why this exists
  ///
  /// A release build put on Play's internal test track is the only place some
  /// faults show up: R8 stripping the SDK, the real application id in the
  /// manifest, the release signing config, adaptive sizing on a real screen.
  /// All of that needs the *live* unit ids to be exercised honestly.
  ///
  /// But an internal tester tapping a live ad is invalid traffic, and the
  /// AdMob ban for it is account-level and not appealable in practice. Listing
  /// the testers' device ids here means Google returns test creatives through
  /// the live units: the whole path is real, the impressions are not.
  ///
  /// Find an id by running the app and reading logcat for the line the SDK
  /// prints — "Use RequestConfiguration.Builder().setTestDeviceIds(...)".
  /// The id is per device *and* per app install.
  static const String _testDeviceIds = String.fromEnvironment(
    'ADMOB_TEST_DEVICE_IDS',
  );

  static List<String> get testDeviceIds => _testDeviceIds
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList(growable: false);

  static bool get isConfigured => banner.isNotEmpty && rewarded.isNotEmpty;

  static String? forSlot(AdSlot slot) => switch (slot) {
    AdSlot.banner => banner.isEmpty ? null : banner,
    AdSlot.interstitial => interstitial.isEmpty ? null : interstitial,
    AdSlot.rewarded => rewarded.isEmpty ? null : rewarded,
  };
}
