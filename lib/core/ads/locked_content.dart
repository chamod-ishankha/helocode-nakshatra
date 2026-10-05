import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/purchases/presentation/paywall.dart';
import '../../l10n/generated/app_localizations.dart';
import '../purchases/entitlements.dart';
import '../purchases/purchase_controller.dart';
import '../theme/app_spacing.dart';
import '../theme/brand_palette.dart';
import '../ui/brand_button.dart';
import '../theme/semantic_colors.dart';
import '../purchases/nudges.dart';
import 'rewarded_analytics.dart';
import 'rewarded_unlock.dart';

/// Real content, blurred, with both ways past it on top (KAN-36).
///
/// ## Why this and not RewardedUnlockCard
///
/// The card replaces the content with a description of it. That is the right
/// shape when the locked thing is a list of numbers nobody can picture. It is
/// the wrong shape when the locked thing *looks* like something — a chart, a
/// timeline — because then the picture is the pitch. Somebody who can see the
/// shape of a navamsa behind the blur knows what they are being offered; the
/// same person reading "see the navamsa chart" does not.
///
/// The blur has to be real. A low sigma that leaves text legible is worse than
/// no lock at all: it gives the content away and annoys the user at the same
/// time. [_sigma] is set where 11pt body text is shape without letters.
///
/// ## Whichever doors are open
///
/// Video first, purchase second — the same order as [RewardedUnlockCard], and
/// for the same reason (KAN-34): in this market the rewarded eCPM is the
/// business, and somebody who will never pay must keep the button they came
/// for.
///
/// Neither button is unconditional. A build with no ad ids cannot play a
/// video and a build with no store key cannot sell, so each hides when it
/// cannot deliver — and when *neither* can, the content simply opens, because
/// a lock nobody can ever pass is worse than no lock. Somebody who bought
/// Remove Ads is not offered a video either: the promise was no ads anywhere,
/// and an opt-in ad is still an ad.
class LockedContent extends ConsumerStatefulWidget {
  const LockedContent({
    required this.unlock,
    required this.feature,
    required this.title,
    required this.body,
    required this.child,
    super.key,
  });

  /// The video that opens this for the rest of the day.
  final RewardedUnlock unlock;

  /// The entitlement that opens it for good.
  final PaidFeature feature;

  final String title;
  final String body;

  /// The genuine content. Always built, even while locked — it is what is
  /// behind the blur, and a placeholder there would sell nothing.
  final Widget child;

  /// On the prompt card, so a test can measure where it sits without
  /// depending on what kind of box it is drawn with.
  static const promptKey = ValueKey('locked-content-prompt');

  @override
  ConsumerState<LockedContent> createState() => _LockedContentState();
}

class _LockedContentState extends ConsumerState<LockedContent> {
  bool _busy = false;
  bool _failed = false;

  /// Whether this lock's offer has been counted (KAN-70).
  ///
  /// Unlike the card, this widget stays mounted locked and unlocked, and
  /// build reruns constantly — so it counts the first build that actually
  /// shows a watch button, and never again for this lock.
  bool _offerCounted = false;

  /// Enough blur that no glyph survives it.
  static const double _sigma = 9;

  Future<void> _watch() async {
    setState(() {
      _busy = true;
      _failed = false;
    });

    final earned = await ref
        .read(unlockRevisionProvider.notifier)
        .earn(widget.unlock);

    if (!mounted) return;
    setState(() {
      _busy = false;
      _failed = !earned;
    });
  }

  @override
  Widget build(BuildContext context) {
    final owned = ref.watch(featureProvider(widget.feature));
    final earned = ref.watch(unlockStoreProvider).earnedToday(widget.unlock);

    // Which doors exist at all. Deliberately not UnlockStore.isOpen, which
    // treats "this user has no ads" as "this user owns it" — true for a
    // rewarded-only unlock, wrong for a feature sold under Pro.
    final canWatch = ref.watch(rewardedAvailableProvider);
    final canBuy = ref.watch(purchasesAvailableProvider);

    // A lock with no way past it is worse than no lock. A clone with no env
    // file has neither ad ids nor a store key, and must still be a whole app
    // rather than a screen of blurred rectangles nobody can ever open.
    if (owned || earned || (!canWatch && !canBuy)) return widget.child;

    if (!_offerCounted) {
      _offerCounted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Only when the video door exists: a lock offering nothing but Pro is
        // not a rewarded offer, and counting it would dilute the watch rate.
        if (canWatch) {
          ref
              .read(unlockRevisionProvider.notifier)
              .offered(widget.unlock, RewardedSurface.lock);
        }
        // Counted whether or not a video can be watched. Somebody who bought
        // Remove Ads and keeps returning to the navāṁśa is the likeliest Pro
        // buyer there is (KAN-75).
        ref.read(nudgeRevisionProvider.notifier).lockSeen(widget.unlock);
      });
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // TileMode.decal so the blur does not smear the edge pixels outward
        // into a halo past the content's own bounds.
        ImageFiltered(
          imageFilter: ui.ImageFilter.blur(
            sigmaX: _sigma,
            sigmaY: _sigma,
            tileMode: TileMode.decal,
          ),
          // Not just unreadable — unreachable. Without these a tap lands on
          // whatever is under the blur, and a screen reader reads out the
          // locked content word for word.
          child: ExcludeSemantics(child: IgnorePointer(child: widget.child)),
        ),

        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: _Prompt(
            key: LockedContent.promptKey,
            title: widget.title,
            body: widget.body,
            busy: _busy,
            failed: _failed,
            canWatch: canWatch,
            canBuy: canBuy,
            onWatch: _watch,
            onBuy: () => showPaywall(
              context,
              ref,
              reason: PaywallReason.forUnlock(widget.unlock),
            ),
          ),
        ),
      ],
    );
  }
}

/// The card that floats over the blur.
///
/// Its own widget so the [Stack] above stays readable, and so the surface is
/// opaque: a translucent card over a blur is where this pattern usually goes
/// wrong, because the text then sits on whatever colour happens to be behind
/// it and the contrast is different on every screen.
class _Prompt extends ConsumerWidget {
  const _Prompt({
    super.key,
    required this.title,
    required this.body,
    required this.busy,
    required this.failed,
    required this.canWatch,
    required this.canBuy,
    required this.onWatch,
    required this.onBuy,
  });

  final String title;
  final String body;
  final bool busy;
  final bool failed;
  final bool canWatch;
  final bool canBuy;
  final VoidCallback onWatch;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context);
    final palette = BrandPalette.of(context);
    final semantic = context.semantic;

    // An opaque card, not a tint: it sits on a blurred chart, and a
    // translucent one let the blurred lines run through the words (KAN-83).
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: semantic.accent),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 18, color: semantic.accent),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: palette.text,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, height: 1.5, color: palette.muted),
            ),
            const SizedBox(height: AppSpacing.md),
            if (canWatch)
              BrandButton(
                tone: BrandButtonTone.reward,
                expand: true,
                onPressed: busy ? null : onWatch,
                leading: busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow_rounded),
                label: busy ? l.unlockLoading : l.unlockWatch,
              ),
            if (canBuy) ...[
              if (canWatch) const SizedBox(height: AppSpacing.sm),
              BrandButton(
                tone: canWatch
                    ? BrandButtonTone.outline
                    : BrandButtonTone.primary,
                expand: true,
                onPressed: busy ? null : onBuy,
                label: l.purchaseUpgrade,
              ),
            ],
            if (failed && canWatch) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l.unlockFailed,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: semantic.inauspicious),
              ),
            ],
            // Sets the expectation that a watched video is a day pass, so
            // tomorrow's lock reads as the design rather than as the app
            // forgetting. Untrue of a purchase, so it goes with the video.
            if (canWatch) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l.unlockLastsToday,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: palette.muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
