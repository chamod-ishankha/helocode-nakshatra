import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/purchases/presentation/paywall.dart';
import '../../l10n/generated/app_localizations.dart';
import '../purchases/entitlements.dart';
import '../purchases/purchase_controller.dart';
import '../theme/app_spacing.dart';
import '../theme/semantic_colors.dart';
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

  @override
  ConsumerState<LockedContent> createState() => _LockedContentState();
}

class _LockedContentState extends ConsumerState<LockedContent> {
  bool _busy = false;
  bool _failed = false;

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
    final theme = Theme.of(context);

    return Card(
      color: context.semantic.accentSurface,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.semantic.accent.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Whichever doors are actually open. With both, the video leads;
            // with only the purchase, it becomes the primary button rather
            // than a text link floating under nothing.
            if (canWatch)
              FilledButton.icon(
                onPressed: busy ? null : onWatch,
                icon: busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_circle_outline),
                label: Text(busy ? l.unlockLoading : l.unlockWatch),
              ),
            if (canBuy)
              canWatch
                  ? TextButton(
                      onPressed: busy ? null : onBuy,
                      child: Text(l.purchaseUpgrade),
                    )
                  : FilledButton(
                      onPressed: busy ? null : onBuy,
                      child: Text(l.purchaseUpgrade),
                    ),
            if (failed && canWatch) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l.unlockFailed,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.semantic.inauspicious,
                ),
              ),
            ],
            // Sets the expectation that a watched video is a day pass, so
            // tomorrow's lock reads as the design rather than as the app
            // forgetting. Untrue of a purchase, so it goes with the video.
            if (canWatch) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                l.unlockLastsToday,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
