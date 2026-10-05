import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../features/purchases/presentation/paywall.dart';
import '../purchases/purchase_controller.dart';
import '../theme/app_spacing.dart';
import '../theme/brand_palette.dart';
import '../ui/brand_button.dart';
import '../ui/brand_card.dart';
import '../theme/semantic_colors.dart';
import '../purchases/nudges.dart';
import 'rewarded_analytics.dart';
import 'rewarded_unlock.dart';

/// The "watch a short video to see this" prompt (KAN-34).
///
/// ## Why this is not a banner
///
/// A rewarded ad is asked for, not sprung. The user reads what they will get,
/// decides, and taps — so unlike a banner this may sit right next to the
/// content it opens. The AdMob ban rule is about *accidental* clicks beside a
/// reveal; a deliberate opt-in button is the format working as intended.
///
/// Always says what is behind the video before the video plays. A prompt that
/// hides what it is selling gets watched once and never again.
class RewardedUnlockCard extends ConsumerStatefulWidget {
  const RewardedUnlockCard({
    required this.unlock,
    required this.title,
    required this.body,
    super.key,
  });

  final RewardedUnlock unlock;
  final String title;
  final String body;

  @override
  ConsumerState<RewardedUnlockCard> createState() => _RewardedUnlockCardState();
}

class _RewardedUnlockCardState extends ConsumerState<RewardedUnlockCard> {
  bool _busy = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    // Every caller mounts this card only while its content is locked and an
    // ad can be watched, so appearing is being offered. Counted on mount
    // rather than in build, which reruns on every tap (KAN-70).
    ref
        .read(unlockRevisionProvider.notifier)
        .offered(widget.unlock, RewardedSurface.card);
    ref.read(nudgeRevisionProvider.notifier).lockSeen(widget.unlock);
  }

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
      // No ad filled, or it was dismissed early. Said plainly rather than
      // leaving a button that appears to do nothing.
      _failed = !earned;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final palette = BrandPalette.of(context);
    final semantic = context.semantic;
    final canBuy = ref.watch(purchasesAvailableProvider);

    // Gold is "earned" in the one lock hierarchy (KAN-93): the same card as
    // the lock prompt over a blurred chart, so a gold card with a gold button
    // means "watch to open" wherever it appears. Paid is violet, free green.
    return BrandCard(
      tone: BrandCardTone.gold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, size: 20, color: semantic.accent),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  widget.title,
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
            widget.body,
            style: TextStyle(fontSize: 14, height: 1.5, color: palette.muted),
          ),
          const SizedBox(height: AppSpacing.lg),
          BrandButton(
            tone: BrandButtonTone.reward,
            expand: true,
            onPressed: _busy ? null : _watch,
            leading: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow_rounded),
            label: _busy ? l.unlockLoading : l.unlockWatch,
          ),
          if (canBuy) ...[
            const SizedBox(height: AppSpacing.sm),
            BrandButton(
              tone: BrandButtonTone.outline,
              expand: true,
              onPressed: _busy
                  ? null
                  : () => showPaywall(
                      context,
                      ref,
                      reason: PaywallReason.forUnlock(widget.unlock),
                    ),
              label: l.purchaseUpgrade,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            l.unlockLastsToday,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: palette.muted),
          ),
          if (_failed) ...[
            const SizedBox(height: AppSpacing.sm),
            // A warning mark as well as the red: the line has to read as a
            // problem to someone who cannot tell the red from the gold.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: semantic.inauspicious,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l.unlockFailed,
                    style: TextStyle(
                      fontSize: 13,
                      color: semantic.inauspicious,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
