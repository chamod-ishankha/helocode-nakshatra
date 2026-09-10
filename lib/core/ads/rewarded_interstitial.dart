import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ad_gate.dart';
import 'rewarded_unlock.dart';

/// What happened when a rewarded interstitial was asked for.
///
/// Three outcomes rather than a bool, because the two false-ish ones mean
/// opposite things to the cooldown. "Nothing was loaded" is nobody
/// interrupted and must cost nothing; "shown and skipped" is a full-screen
/// ad the user sat through part of, and charging them again three seconds
/// later would be the worst reading of this placement.
enum RewardedInterstitialOutcome {
  /// Nothing was ready, or it failed to appear. No interruption happened.
  notShown,

  /// It appeared, and the user left before earning the reward.
  shownOnly,

  /// It appeared and the reward was earned.
  earned;

  /// Whether the user was actually interrupted.
  bool get appeared => this != RewardedInterstitialOutcome.notShown;
}

/// Loads a rewarded interstitial in the background. Overridden in [bootstrap].
final rewardedInterstitialPreloaderProvider = Provider<Future<void> Function()>(
  (ref) => () async {},
);

/// Shows one, and says what became of it.
///
/// Indirected through a provider for the same reason the other two are: the
/// SDK cannot run under `flutter test`, and the rules about when this may
/// appear — and what it pays out — are the part worth checking without a
/// network or an AdMob account.
final rewardedInterstitialPresenterProvider =
    Provider<Future<RewardedInterstitialOutcome> Function()>(
      (ref) =>
          () async => RewardedInterstitialOutcome.notShown,
    );

/// The full-screen ad on the chart screen, and what it buys (KAN-55).
///
/// ## What this is not
///
/// KAN-55 asks for a rewarded interstitial "while a chart is generating".
/// There is no such moment: `chartProvider` is synchronous and a whole chart
/// costs 0.28 ms on the cheapest phone this targets, against a 16.7 ms frame.
/// The spinner on the chart screen is a null-guard for having no profile at
/// all, not a loading state. Manufacturing a delay to fill would mean making
/// the app slower in order to show an ad, which is not a trade this codebase
/// should make.
///
/// So it runs when the chart screen opens instead.
///
/// ## Why it pays out
///
/// A rewarded interstitial with no reward is just an interstitial with an
/// extra screen in front of it — strictly worse for everyone. This one grants
/// the day's chart unlocks: the navāṁśa and the third daśā level, both of
/// which sit on the screen it interrupts. The interruption therefore buys
/// something the user can see, on the page they are already on, rather than
/// being rent charged at the door.
///
/// ## The rules it obeys
///
/// [AdGate] already refuses this for a purchaser, before a profile exists,
/// inside the 90-second session grace, and inside the three-minute cooldown —
/// and the cooldown is shared with the plain interstitial, so a user cannot
/// get one of each in quick succession. A first-run user finishing onboarding
/// is inside two of those refusals and sees nothing.
class RewardedInterstitialController {
  const RewardedInterstitialController({
    required this.gate,
    required this.present,
    required this.preload,
  });

  final AdGate gate;
  final Future<RewardedInterstitialOutcome> Function() present;
  final Future<void> Function() preload;

  /// What a watched ad opens, for the rest of the local day.
  ///
  /// Both live on the chart screen. Paying out in something the user cannot
  /// see from where they are would make this an interruption with an
  /// invisible reward, which is the same as no reward.
  static const Set<RewardedUnlock> reward = {
    RewardedUnlock.navamsaChart,
    RewardedUnlock.dashaDetail,
  };

  /// Starts loading, so the ad is ready as the screen opens.
  ///
  /// Nothing is loaded for somebody who bought Remove Ads, or in a build with
  /// no unit id. A load they will never see still asks AdMob for an ad, still
  /// spends their data, and still reports which screen they opened.
  ///
  /// Skipped, too, when everything it pays out was already watched for today
  /// — there is nothing left to buy, so the interruption would be for nothing.
  Future<void> prepare(UnlockStore unlocks) async {
    if (gate.hasEntitlement || !gate.isConfigured) return;
    if (_watchedToday(unlocks)) return;
    await preload();
  }

  /// Shows one if the policy allows it. True only if the reward was earned.
  ///
  /// The cooldown is recorded when the ad *appeared*, not when it paid out.
  /// Somebody who skipped through the intro screen was still interrupted, and
  /// charging them again three seconds later would be the worst reading of
  /// this placement. A failed fill records nothing, because nothing happened.
  Future<bool> showIfAllowed(UnlockStore unlocks) async {
    if (!gate.allows(AdSlot.rewardedInterstitial)) return false;
    if (_watchedToday(unlocks)) return false;

    final outcome = await present();
    if (outcome.appeared) {
      await gate.recordShown(AdSlot.rewardedInterstitial);
    }

    if (outcome == RewardedInterstitialOutcome.earned) return true;

    // Nothing is loaded any more: showing consumes the ad, and a failed fill
    // never had one. Somebody who skipped it, or who got no fill, is still a
    // live prospect once the cooldown passes — so warm the next one now
    // rather than leaving the placement dead until the app restarts. Found on
    // the device: the second chart of a session showed nothing at all.
    await preload();
    return false;
  }

  /// Whether every reward was already watched for today.
  ///
  /// Deliberately [UnlockStore.earnedToday] and not `isOpen`. `isOpen` also
  /// answers true for a purchaser and for a build with no ad ids, which are
  /// the two cases the guards above exist for — so using it here would make
  /// those guards dead code that no test could reach, and the day one of them
  /// stopped being covered by accident, nothing would say so.
  bool _watchedToday(UnlockStore unlocks) => reward.every(unlocks.earnedToday);
}

final rewardedInterstitialControllerProvider =
    Provider<RewardedInterstitialController>((ref) {
      return RewardedInterstitialController(
        gate: ref.watch(adGateProvider),
        present: ref.watch(rewardedInterstitialPresenterProvider),
        preload: ref.watch(rewardedInterstitialPreloaderProvider),
      );
    });
