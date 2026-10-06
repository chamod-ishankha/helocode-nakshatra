import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/ads/lock_preview.dart';
import '../../../core/ads/locked_content.dart';
import '../../../core/ads/rewarded_unlock.dart';
import '../../../core/astro/dasha.dart';
import '../../../core/purchases/entitlements.dart';
import '../../../core/purchases/pro_usage.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/semantic_colors.dart';
import '../../../core/ui/brand_card.dart';
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
  const DashaTimeline({
    super.key,
    required this.birthTimeKnown,
    this.showTitle = true,
  });

  /// False on the daśā screen, whose header already names it.
  final bool showTitle;

  /// Drives the accuracy warning. This matters far more for a daśā than for
  /// the houses, which is why an unknown birth time gets a caution notice
  /// at the top of this section.
  final bool birthTimeKnown;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeline = ref.watch(dashaProvider);
    final l = L10n.of(context);
    final palette = BrandPalette.of(context);

    if (timeline == null || timeline.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now().toUtc();
    final running = Vimshottari.at(timeline, now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Text(
            l.dashaTitle,
            style: BrandFonts.displayStyle(
              context,
              size: 20,
              color: palette.text,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],

        if (!birthTimeKnown) ...[
          InfoNotice(
            text: L10n.of(context).dashaUnreliableTime,
            tone: NoticeTone.caution,
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        if (running != null) ...[
          _RunningCard(snapshot: running),
          const SizedBox(height: AppSpacing.lg),
        ],

        // The periods on a rail (KAN-84): one line down the side, a dot per
        // period. Where you are in 120 years is visible before a date is read.
        Stack(
          children: [
            PositionedDirectional(
              start: _railX - 1,
              top: 24,
              bottom: 24,
              child: Container(width: 2, color: palette.line),
            ),
            Column(
              children: [
                for (final maha in timeline)
                  _MahaTile(
                    maha: maha,
                    isCurrent: running?.maha == maha,
                    isPast: !maha.end.isAfter(now),
                    currentAntara: running?.antara,
                    // Only the first period is a partial one, and only
                    // because part of it had already run when the user was
                    // born.
                    isBalance: maha == timeline.first,
                  ),
              ],
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.sm),
        Text(
          l.dashaBalanceNote,
          style: TextStyle(fontSize: 13, height: 1.5, color: palette.muted),
        ),
      ],
    );
  }
}

/// Where the rail runs, measured from the start edge: the centre of the dot.
const double _railX = 10;

class _RunningCard extends ConsumerWidget {
  const _RunningCard({required this.snapshot});

  final DashaSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context);
    final locale = ref.watch(localeProvider);
    final palette = BrandPalette.of(context);
    final semantic = context.semantic;
    final maha = snapshot.maha;
    final antara = snapshot.antara;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: semantic.accent),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          // Composited onto the card colour so both stops share its
          // transparency; see the note on the South Indian centre panel.
          colors: [
            Color.alphaBlend(
              semantic.accent.withValues(alpha: 0.18),
              palette.surface,
            ),
            palette.surface,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.dashaRunningNow,
            style: TextStyle(fontSize: 13, color: palette.muted),
          ),
          const SizedBox(height: 4),
          Text(
            antara == null
                ? maha.lord.label(locale)
                : '${maha.lord.label(locale)} — ${antara.lord.label(locale)}',
            style: BrandFonts.displayStyle(
              context,
              size: 32,
              color: palette.text,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l.dashaEnds(_longDate(context, (antara ?? maha).end)),
            style: TextStyle(fontSize: 13, color: palette.muted),
          ),
          const SizedBox(height: AppSpacing.md),
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
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        value: fraction,
        minHeight: 8,
        color: context.semantic.accent,
        backgroundColor: BrandPalette.of(context).line,
      ),
    );
  }
}

/// A period's place on the rail: past, running, or still to come.
///
/// Shape as well as colour — filled, ringed, hollow — so it reads for someone
/// who cannot tell the gold from the grey.
class _RailDot extends StatelessWidget {
  const _RailDot({required this.isCurrent, required this.isPast});

  final bool isCurrent;
  final bool isPast;

  @override
  Widget build(BuildContext context) {
    final palette = BrandPalette.of(context);
    final gold = context.semantic.accent;
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCurrent
            ? gold
            : isPast
            ? palette.muted
            : palette.background,
        border: Border.all(color: isCurrent ? gold : palette.muted, width: 2),
        boxShadow: isCurrent
            ? [BoxShadow(color: gold.withValues(alpha: 0.35), spreadRadius: 5)]
            : null,
      ),
    );
  }
}

class _MahaTile extends ConsumerWidget {
  const _MahaTile({
    required this.maha,
    required this.isCurrent,
    required this.isPast,
    required this.currentAntara,
    required this.isBalance,
  });

  final DashaPeriod maha;
  final bool isCurrent;
  final bool isPast;
  final DashaPeriod? currentAntara;
  final bool isBalance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context);
    final locale = ref.watch(localeProvider);
    final palette = BrandPalette.of(context);
    final gold = context.semantic.accent;

    return Theme(
      // No divider lines above and below an open tile: the rail is the
      // structure here.
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        // Open the period the user is living in; the rest stay shut so the
        // table does not arrive as 81 rows.
        initiallyExpanded: isCurrent,
        tilePadding: EdgeInsets.zero,
        minTileHeight: 52,
        // Right of the rail, and nothing on the far side: the sub-period card
        // is the full width of what is left, so anything centred in it is
        // centred in the card.
        childrenPadding: const EdgeInsetsDirectional.fromSTEB(
          _railX * 2 + 12,
          0,
          0,
          10,
        ),
        shape: const Border(),
        collapsedShape: const Border(),
        showTrailingIcon: false,
        leading: SizedBox(
          width: _railX * 2,
          child: Center(
            child: _RailDot(isCurrent: isCurrent, isPast: isPast),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                maha.lord.label(locale),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                  color: isCurrent ? gold : palette.text,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${_shortDate(context, maha.start)} — ${_shortDate(context, maha.end)}'
              '${isBalance ? ' *' : ''}',
              style: TextStyle(fontSize: 13, color: palette.muted),
            ),
          ],
        ),
        children: [
          Container(
            key: ValueKey('dasha-sub-${maha.start.toIso8601String()}'),
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: palette.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.dashaSubPeriods,
                  style: TextStyle(fontSize: 12, color: palette.muted),
                ),
                const SizedBox(height: AppSpacing.xs),
                for (var i = 0; i < maha.children.length; i++)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: i == 0
                          ? null
                          : Border(top: BorderSide(color: palette.line)),
                    ),
                    child: _AntaraTile(
                      antara: maha.children[i],
                      isCurrent: maha.children[i] == currentAntara,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
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
    final l = L10n.of(context);
    final locale = ref.watch(localeProvider);
    final palette = BrandPalette.of(context);
    final gold = context.semantic.accent;

    final row = Row(
      children: [
        // A dot beside the running one as well as the gold and the weight.
        if (isCurrent) ...[
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: gold, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
        ],
        Expanded(
          flex: 2,
          child: Text(
            antara.lord.label(locale),
            style: TextStyle(
              fontSize: 14,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              color: isCurrent ? gold : palette.text,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            '${_shortDate(context, antara.start)} — '
            '${_shortDate(context, antara.end)}',
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
              color: isCurrent ? gold : palette.muted,
            ),
          ),
        ),
      ],
    );

    // A depth-2 tree has nothing under this row, and an expander that opens
    // onto nothing is worse than a plain row.
    if (antara.children.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: row,
      );
    }

    final free = previewCount(antara.children.length);

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        // Never pre-expanded, not even for the running antara: it would put a
        // lock on screen before the user asked for anything.
        tilePadding: EdgeInsets.zero,
        // Even on both sides, so the lock lands in the middle of the card.
        childrenPadding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
        shape: const Border(),
        collapsedShape: const Border(),
        dense: true,
        visualDensity: VisualDensity.compact,
        iconColor: palette.muted,
        collapsedIconColor: palette.muted,
        title: row,
        // Opening a period is the use the meter reports (KAN-77). Collapsing
        // is not, and nothing is counted unless Pro is active.
        onExpansionChanged: (open) {
          if (!open) return;
          ref
              .read(proUsageRevisionProvider.notifier)
              .record(ProUsage.dashaExplored);
        },
        children: [
          // The first sub-periods in the clear, the rest behind the lock: the
          // reader sees what the third level is before being asked for it
          // (KAN-70). Unlocked, the two halves read as one list.
          for (final pratyantara in antara.children.take(free))
            _PratyantaraRow(pratyantara: pratyantara),
          LockedContent(
            unlock: RewardedUnlock.dashaDetail,
            feature: PaidFeature.fullDashaTimeline,
            title: l.unlockDashaTitle,
            body: l.unlockDashaBody,
            child: Column(
              children: [
                for (final pratyantara in antara.children.skip(free))
                  _PratyantaraRow(pratyantara: pratyantara),
              ],
            ),
          ),
        ],
      ),
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
    final locale = ref.watch(localeProvider);
    final palette = BrandPalette.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              pratyantara.lord.label(locale),
              style: TextStyle(fontSize: 13, color: palette.text),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '${_shortDate(context, pratyantara.start)} — '
              '${_shortDate(context, pratyantara.end)}',
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 12, color: palette.muted),
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

/// The running period, as a card that opens the full timeline (KAN-83).
///
/// The timeline is nine periods and eighty-one sub-periods long, and on the
/// chart screen it pushed the report tile and everything after it a long way
/// down. Almost nobody opens it to read 1997, so the chart shows what is
/// running now and the rest is one tap away.
class RunningDashaLink extends ConsumerWidget {
  const RunningDashaLink({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeline = ref.watch(dashaProvider);
    if (timeline == null || timeline.isEmpty) return const SizedBox.shrink();
    final running = Vimshottari.at(timeline, DateTime.now().toUtc());
    if (running == null) return const SizedBox.shrink();

    final l = L10n.of(context);
    final locale = ref.watch(localeProvider);
    final palette = BrandPalette.of(context);
    final semantic = context.semantic;
    final maha = running.maha;
    final antara = running.antara;
    final period = antara ?? maha;
    final total = period.duration.inSeconds;
    final done = DateTime.now().toUtc().difference(period.start).inSeconds;
    final fraction = total <= 0 ? 0.0 : (done / total).clamp(0.0, 1.0);

    return BrandCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: semantic.accentSurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.schedule_rounded, color: semantic.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.dashaRunningNow,
                  style: TextStyle(fontSize: 13, color: palette.muted),
                ),
                const SizedBox(height: 2),
                Text(
                  antara == null
                      ? maha.lord.label(locale)
                      : '${maha.lord.label(locale)} — ${antara.lord.label(locale)}',
                  style: BrandFonts.displayStyle(
                    context,
                    size: 20,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 8,
                    color: semantic.accent,
                    backgroundColor: palette.line,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, color: palette.muted),
        ],
      ),
    );
  }
}
