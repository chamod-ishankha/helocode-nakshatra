import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/ads/locked_content.dart';
import '../../../core/ads/rewarded_unlock.dart';
import '../../../core/astro/dasha.dart';
import '../../../core/purchases/entitlements.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/ui/info_notice.dart';
import '../../onboarding/data/profile_repository.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/chart_providers.dart';

/// The daśā tree for the current profile, all three levels.
///
/// Generated in full even for a user who has not paid, because the third level
/// is what sits behind the blur in [_AntaraTile] — a lock over a placeholder
/// sells nothing. The cost is 729 periods of arithmetic on a tree that is
/// already being built, which does not register beside the ephemeris call that
/// produced the chart.
final dashaProvider = Provider<List<DashaPeriod>?>((ref) {
  final chart = ref.watch(chartProvider)?.valueOrNull;
  if (chart == null) return null;
  return Vimshottari.forChart(chart, depth: 3);
});

/// Vimśottarī daśā, with the running period called out.
///
/// A daśā table is long — nine periods covering 120 years, each with nine
/// sub-periods — and almost nobody opens it to read 1997. They open it to see
/// what is running now, so that is stated first and the table below it is
/// collapsed by default with the current period already open.
class DashaTimeline extends ConsumerWidget {
  const DashaTimeline({super.key, required this.birthTimeKnown});

  /// Drives the accuracy warning. This matters far more for a daśā than for
  /// the houses, which is why an unknown birth time gets a caution notice
  /// at the top of this section.
  final bool birthTimeKnown;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeline = ref.watch(dashaProvider);
    final l = L10n.of(context);
    final theme = Theme.of(context);

    if (timeline == null || timeline.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now().toUtc();
    final running = Vimshottari.at(timeline, now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.dashaTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),

        if (!birthTimeKnown) ...[
          InfoNotice(
            text: L10n.of(context).dashaUnreliableTime,
            tone: NoticeTone.caution,
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        if (running != null) ...[
          _RunningCard(snapshot: running),
          const SizedBox(height: AppSpacing.md),
        ],

        for (final maha in timeline)
          _MahaTile(
            maha: maha,
            isCurrent: running?.maha == maha,
            currentAntara: running?.antara,
            // Only the first period is a partial one, and only because part
            // of it had already run when the user was born.
            isBalance: maha == timeline.first,
          ),

        const SizedBox(height: AppSpacing.sm),
        Text(
          l.dashaBalanceNote,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _RunningCard extends ConsumerWidget {
  const _RunningCard({required this.snapshot});

  final DashaSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = L10n.of(context);
    final locale = ref.watch(localeProvider);
    final maha = snapshot.maha;
    final antara = snapshot.antara;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: theme.colorScheme.primary, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.dashaRunningNow,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            antara == null
                ? maha.lord.label(locale)
                : '${maha.lord.label(locale)} — ${antara.lord.label(locale)}',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l.dashaEnds(_longDate(context, (antara ?? maha).end)),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          _Progress(period: antara ?? maha),
        ],
      ),
    );
  }
}

/// How far through the running period we are.
class _Progress extends StatelessWidget {
  const _Progress({required this.period});

  final DashaPeriod period;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc();
    final total = period.duration.inSeconds;
    final done = now.difference(period.start).inSeconds;
    final fraction = total <= 0 ? 0.0 : (done / total).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(value: fraction, minHeight: 6),
    );
  }
}

class _MahaTile extends ConsumerWidget {
  const _MahaTile({
    required this.maha,
    required this.isCurrent,
    required this.currentAntara,
    required this.isBalance,
  });

  final DashaPeriod maha;
  final bool isCurrent;
  final DashaPeriod? currentAntara;
  final bool isBalance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = L10n.of(context);
    final locale = ref.watch(localeProvider);

    return ExpansionTile(
      // Open the period the user is living in; the rest stay shut so the
      // table does not arrive as 81 rows.
      initiallyExpanded: isCurrent,
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(left: 16, bottom: 8),
      shape: const Border(),
      collapsedShape: const Border(),
      leading: Icon(
        isCurrent ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        size: 18,
        color: isCurrent
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(
        maha.lord.label(locale),
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
          color: isCurrent ? theme.colorScheme.primary : null,
        ),
      ),
      subtitle: Text(
        '${_shortDate(context, maha.start)} — ${_shortDate(context, maha.end)}'
        '${isBalance ? ' *' : ''}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            l.dashaSubPeriods,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final antara in maha.children)
          _AntaraTile(antara: antara, isCurrent: antara == currentAntara),
      ],
    );
  }
}

/// One antardaśā, opening onto its pratyantardaśās.
///
/// The third level is the paid one (KAN-36). It expands rather than navigating
/// so the lock appears in place, under the row the user tapped, next to the
/// dates it belongs to — a user who does not want it collapses the row and has
/// lost nothing.
class _AntaraTile extends ConsumerWidget {
  const _AntaraTile({required this.antara, required this.isCurrent});

  final DashaPeriod antara;
  final bool isCurrent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = L10n.of(context);
    final locale = ref.watch(localeProvider);

    final row = Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            antara.lord.label(locale),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isCurrent ? FontWeight.w700 : null,
              color: isCurrent ? theme.colorScheme.primary : null,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            '${_shortDate(context, antara.start)} — '
            '${_shortDate(context, antara.end)}',
            textAlign: TextAlign.end,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isCurrent
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );

    // A depth-2 tree has nothing under this row, and an expander that opens
    // onto nothing is worse than a plain row.
    if (antara.children.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: row,
      );
    }

    return ExpansionTile(
      // Never pre-expanded, not even for the running antara: it would put a
      // lock on screen before the user asked for anything.
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(left: 12, bottom: 8),
      shape: const Border(),
      collapsedShape: const Border(),
      dense: true,
      visualDensity: VisualDensity.compact,
      title: row,
      children: [
        LockedContent(
          unlock: RewardedUnlock.dashaDetail,
          feature: PaidFeature.fullDashaTimeline,
          title: l.unlockDashaTitle,
          body: l.unlockDashaBody,
          child: Column(
            children: [
              for (final pratyantara in antara.children)
                _PratyantaraRow(pratyantara: pratyantara),
            ],
          ),
        ),
      ],
    );
  }
}

/// One pratyantardaśā — the leaf of the tree.
///
/// Smaller and greyer than [_AntaraTile]'s row on purpose: at this depth the
/// list is read by scanning for a date, not by reading every line.
class _PratyantaraRow extends ConsumerWidget {
  const _PratyantaraRow({required this.pratyantara});

  final DashaPeriod pratyantara;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final locale = ref.watch(localeProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              pratyantara.lord.label(locale),
              style: theme.textTheme.bodySmall,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '${_shortDate(context, pratyantara.start)} — '
              '${_shortDate(context, pratyantara.end)}',
              textAlign: TextAlign.end,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Boundaries are UTC instants; a user reads them as dates where they live.
String _shortDate(BuildContext context, DateTime utc) => DateFormat.yMMM(
  Localizations.localeOf(context).languageCode,
).format(utc.toLocal());

String _longDate(BuildContext context, DateTime utc) => DateFormat.yMMMd(
  Localizations.localeOf(context).languageCode,
).format(utc.toLocal());
