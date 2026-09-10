import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/astro/dasha.dart';
import '../../../core/theme/semantic_colors.dart';
import '../../onboarding/data/profile_repository.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/chart_providers.dart';

/// The daśā tree for the current profile, two levels deep.
///
/// Pratyantardaśā is a Pro feature (KAN-36) and is deliberately not generated
/// here: showing a third level behind a lock that does nothing would be worse
/// than not showing it. The engine supports `depth: 3` when the paywall lands.
final dashaProvider = Provider<List<DashaPeriod>?>((ref) {
  final chart = ref.watch(chartProvider)?.valueOrNull;
  if (chart == null) return null;
  return Vimshottari.forChart(chart, depth: 2);
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
  /// the houses: see [_UnreliableTimeWarning].
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
        const SizedBox(height: 8),

        if (!birthTimeKnown) ...[
          const _UnreliableTimeWarning(),
          const SizedBox(height: 12),
        ],

        if (running != null) ...[
          _RunningCard(snapshot: running),
          const SizedBox(height: 12),
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

        const SizedBox(height: 8),
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

/// The one warning on this screen that is stronger than the houses one.
///
/// An unknown birth time is handled elsewhere by assuming sunrise, which
/// leaves the planets accurate and only the lagna approximate. A daśā is not
/// so forgiving: it is seeded by how far the Moon has travelled through its
/// nakṣatra, the Moon moves about half a degree an hour, and a nakṣatra is
/// only 13°20' wide. Half a day of uncertainty is therefore up to half a
/// nakṣatra — which can move every date by years and can put the sequence
/// under the wrong ruling planet entirely.
class _UnreliableTimeWarning extends StatelessWidget {
  const _UnreliableTimeWarning();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: context.semantic.inauspicious.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: context.semantic.inauspicious,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              L10n.of(context).dashaUnreliableTime,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
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
          const SizedBox(height: 4),
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
        const SizedBox(height: 4),
        for (final antara in maha.children)
          _AntaraRow(antara: antara, isCurrent: antara == currentAntara),
      ],
    );
  }
}

class _AntaraRow extends ConsumerWidget {
  const _AntaraRow({required this.antara, required this.isCurrent});

  final DashaPeriod antara;
  final bool isCurrent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final locale = ref.watch(localeProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
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
