import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/astro/dignity.dart';
import '../../../core/astro/models.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../onboarding/data/profile_repository.dart';

/// Detail sheets for a tapped graha or house (KAN-53).
///
/// A rendered chart is dense by necessity — nine grahas as two-letter
/// abbreviations in cells about 70 px wide on a small phone. Everything the
/// abbreviation leaves out lives here.

/// Opens the sheet for one graha.
Future<void> showGrahaDetail(BuildContext context, GrahaPosition position) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => _GrahaDetail(position: position),
    );

/// Opens the sheet for one house, listing what sits in it.
///
/// The cell is the tap target rather than the two-letter graha label: that
/// label is a few pixels wide, and a house with nothing in it would otherwise
/// have no way to be tapped at all.
Future<void> showHouseDetail(
  BuildContext context, {
  required Rasi rasi,
  required int house,
  required List<GrahaPosition> grahas,
}) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => _HouseDetail(rasi: rasi, house: house, grahas: grahas),
    );

class _GrahaDetail extends ConsumerWidget {
  const _GrahaDetail({required this.position});

  final GrahaPosition position;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = L10n.of(context);
    final locale = ref.watch(localeProvider);
    final dignity = GrahaDignity.of(position.graha, position.rasi);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    position.graha.label(locale),
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                if (position.isRetrograde)
                  _Chip(
                    label: l.detailRetrograde,
                    colour: AppColors.inauspicious,
                  ),
                if (dignity != null && dignity != Dignity.neutral) ...[
                  const SizedBox(width: 6),
                  _Chip(
                    label: switch (dignity) {
                      Dignity.own => l.dignityOwn,
                      Dignity.exalted => l.dignityExalted,
                      Dignity.debilitated => l.dignityDebilitated,
                      Dignity.neutral => '',
                    },
                    colour: dignity == Dignity.debilitated
                        ? AppColors.inauspicious
                        : AppColors.auspicious,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            _Row(l.chartColumnRasi, position.rasi.label(locale)),
            _Row(
              l.chartColumnDegree,
              '${position.degreeInRasi.toStringAsFixed(2)}°',
            ),
            _Row(l.chartColumnNakshatra, position.nakshatra.en),
            _Row(l.chartColumnPada, '${position.pada}'),
            _Row(l.chartColumnHouse, l.detailHouse(position.house)),

            // Where the peak of exaltation sits, so a reader can see how near
            // it this placement is — a printed chart never tells them.
            if (GrahaDignity.exaltationSign(position.graha) case final sign?)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  l.detailExaltedIn(
                    sign.label(locale),
                    GrahaDignity.exaltationDegree(position.graha)!,
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  l.dignityNodeNote,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HouseDetail extends ConsumerWidget {
  const _HouseDetail({
    required this.rasi,
    required this.house,
    required this.grahas,
  });

  final Rasi rasi;
  final int house;
  final List<GrahaPosition> grahas;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = L10n.of(context);
    final locale = ref.watch(localeProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(rasi.label(locale), style: theme.textTheme.headlineSmall),
            Text(
              l.detailHouse(house),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            if (grahas.isEmpty)
              Text(l.detailNoGraha, style: theme.textTheme.bodyMedium)
            else
              for (final g in grahas)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(g.graha.label(locale)),
                  subtitle: Text(
                    '${g.degreeInRasi.toStringAsFixed(2)}° · '
                    '${g.nakshatra.en} ${g.pada}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Replace rather than stack: two sheets deep on a phone
                    // leaves nothing of the chart visible behind them.
                    Navigator.of(context).pop();
                    showGrahaDetail(context, g);
                  },
                ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.colour});

  final String label;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colour.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: colour),
      ),
    );
  }
}
