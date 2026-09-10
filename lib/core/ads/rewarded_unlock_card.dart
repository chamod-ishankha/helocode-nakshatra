import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../features/purchases/presentation/paywall.dart';
import '../purchases/purchase_controller.dart';
import '../theme/semantic_colors.dart';
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
    final theme = Theme.of(context);

    return Card(
      color: context.semantic.accent.withValues(alpha: 0.07),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.semantic.accent.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.lock_outline, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(widget.title, style: theme.textTheme.titleSmall),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.body,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy ? null : _watch,
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_circle_outline),
              label: Text(_busy ? l.unlockLoading : l.unlockWatch),
            ),
            // The paid path, beside the free one rather than instead of it
            // (KAN-36). Someone who would rather not watch a video every day
            // has to be able to see that there is another way out; someone who
            // will never pay keeps the button they came for.
            if (ref.watch(purchasesAvailableProvider))
              TextButton(
                onPressed: _busy
                    ? null
                    : () => showPaywall(
                        context,
                        ref,
                        reason: PaywallReason.forUnlock(widget.unlock),
                      ),
                child: Text(l.purchaseUpgrade),
              ),
            if (_failed) ...[
              const SizedBox(height: 8),
              Text(
                l.unlockFailed,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.semantic.inauspicious,
                ),
              ),
            ],
            const SizedBox(height: 4),
            // Sets the expectation that this is a day pass, so tomorrow's
            // lock reads as the design rather than as the app forgetting.
            Text(
              l.unlockLastsToday,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
