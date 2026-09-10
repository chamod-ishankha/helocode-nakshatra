import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ad_gate.dart';

/// Loads an interstitial in the background. Overridden in [bootstrap].
final interstitialPreloaderProvider = Provider<Future<void> Function()>(
  (ref) => () async {},
);

/// Shows a preloaded interstitial, resolving true only if it was really shown.
///
/// Indirected through a provider for the same reason the rewarded one is: the
/// SDK cannot run under `flutter test`, and the rules about when an ad may
/// appear are worth checking without a network or an AdMob account.
final interstitialPresenterProvider = Provider<Future<bool> Function()>(
  (ref) =>
      () async => false,
);

/// When a full-screen ad may appear, and remembering that one did (KAN-55).
///
/// [AdGate] holds the policy; this is what actually runs it at a placement.
/// Keeping the two apart is what lets every rule — the session grace, the
/// three-minute cooldown, the purchase — be tested once rather than at each
/// site that shows an ad.
class InterstitialController {
  const InterstitialController({
    required this.gate,
    required this.present,
    required this.preload,
  });

  final AdGate gate;
  final Future<bool> Function() present;
  final Future<void> Function() preload;

  /// Starts loading, so a placement can show instantly rather than making the
  /// user wait while an ad is fetched.
  ///
  /// ## Not for people who have paid
  ///
  /// Checked here rather than only at show time. Loading an ad for somebody
  /// who bought Remove Ads would never display it, but it still asks AdMob for
  /// one, still spends their data, and still tells a third party what screen
  /// they opened — for a user whose whole purchase was to stop that.
  ///
  /// The cooldown deliberately is *not* checked. It may well expire while the
  /// user is reading, and a loaded ad that goes unshown costs nothing, while a
  /// placement with nothing ready earns nothing.
  Future<void> prepare() async {
    if (gate.hasEntitlement || !gate.isConfigured) return;
    await preload();
  }

  /// Shows one if the policy allows it, and records the cooldown if it did.
  ///
  /// The recording is conditional on purpose. An ad that failed to fill, or
  /// failed to show, has not interrupted anybody — starting a three-minute
  /// cooldown from it would quietly suppress the next real opportunity.
  Future<bool> showIfAllowed() async {
    if (!gate.allows(AdSlot.interstitial)) return false;

    final shown = await present();
    if (shown) await gate.recordShown(AdSlot.interstitial);
    return shown;
  }
}

final interstitialControllerProvider = Provider<InterstitialController>((ref) {
  return InterstitialController(
    gate: ref.watch(adGateProvider),
    present: ref.watch(interstitialPresenterProvider),
    preload: ref.watch(interstitialPreloaderProvider),
  );
});
