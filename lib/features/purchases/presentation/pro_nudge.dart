import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/purchases/nudges.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/ui/brand_card.dart';
import '../../../core/ui/round_icon_button.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'paywall.dart';

/// One honest sentence about Pro, beside the thing it is about (KAN-75).
///
/// Given the nudges that make sense where it is placed, it shows the first
/// that [NudgeStore] allows — or nothing at all, which is almost always. Every
/// rule about when is in the store; this only asks, and reports the answer.
///
/// A one-line banner in the page, never over it. The lock beside it works
/// exactly as it did: the nudge is an aside, not a gate, and closing it costs
/// one tap that is remembered for two weeks.
class ProNudge extends ConsumerStatefulWidget {
  const ProNudge({required this.triggers, super.key});

  /// Candidates in priority order. The first eligible one is shown.
  final List<NudgeTrigger> triggers;

  @override
  ConsumerState<ProNudge> createState() => _ProNudgeState();
}

class _ProNudgeState extends ConsumerState<ProNudge> {
  NudgeTrigger? _showing;

  /// Whether this instance has already had its say. Once shown and answered —
  /// or once it has decided to claim — it never asks again while mounted, so
  /// a rebuild cannot produce a second nudge.
  bool _settled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _consider());
  }

  Future<void> _consider() async {
    if (_settled || !mounted) return;

    final trigger = ref.read(nudgeStoreProvider).firstEligible(widget.triggers);
    if (trigger == null) return;

    _settled = true;
    // Claimed rather than just shown: two screens mounting at once must not
    // both take today's one nudge.
    final claimed = await ref
        .read(nudgeRevisionProvider.notifier)
        .claim(trigger);
    if (!claimed || !mounted) return;

    setState(() => _showing = trigger);
    ref.read(nudgeLogProvider)(NudgeEvent.shown, {'trigger': trigger.name});
  }

  Future<void> _answer(NudgeTrigger trigger, {required bool tapped}) async {
    setState(() => _showing = null);
    ref.read(nudgeLogProvider)(
      tapped ? NudgeEvent.tapped : NudgeEvent.dismissed,
      {'trigger': trigger.name},
    );
    await ref.read(nudgeRevisionProvider.notifier).answered(trigger);

    if (tapped && mounted) {
      await showPaywall(context, ref, reason: reasonFor(trigger));
    }
  }

  /// The paywall that answers each nudge.
  static PaywallReason reasonFor(NudgeTrigger trigger) => switch (trigger) {
    NudgeTrigger.compatDetail => PaywallReason.compatibilityDetail,
    NudgeTrigger.navamsa => PaywallReason.navamsaChart,
    NudgeTrigger.family => PaywallReason.multipleProfiles,
    NudgeTrigger.adWatches => PaywallReason.general,
  };

  @override
  Widget build(BuildContext context) {
    // A count that crosses its threshold while this screen is open may make a
    // nudge eligible now. Reconsidered once, and only if nothing was decided.
    ref.listen(nudgeRevisionProvider, (_, _) => _consider());

    final trigger = _showing;
    if (trigger == null) return const SizedBox.shrink();

    final l = L10n.of(context);
    final store = ref.read(nudgeStoreProvider);

    final text = switch (trigger) {
      NudgeTrigger.compatDetail => l.nudgeCompat,
      NudgeTrigger.navamsa => l.nudgeNavamsa,
      NudgeTrigger.family => l.nudgeFamily,
      // The real count, from the real counter — never a round number.
      NudgeTrigger.adWatches => l.nudgeAdWatches(
        store.count(NudgeTrigger.adWatches),
      ),
    };

    final palette = BrandPalette.of(context);

    // Violet, the paid colour (KAN-93). It was a gold strip, the same gold as
    // the cards that a video opens, so "watch to see this" and "pay to never
    // see ads" looked like one offer.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: BrandCard(
        tone: BrandCardTone.paid,
        padding: const EdgeInsets.fromLTRB(18, 14, 14, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: palette.text,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                RoundIconButton(
                  icon: Icons.close,
                  dimension: 32,
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => _answer(trigger, tapped: false),
                ),
              ],
            ),
            TextButton(
              onPressed: () => _answer(trigger, tapped: true),
              style: TextButton.styleFrom(
                foregroundColor: palette.violet,
                padding: EdgeInsets.zero,
                minimumSize: const Size(48, 40),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
              child: Text(l.nudgeSeePro),
            ),
          ],
        ),
      ),
    );
  }
}
