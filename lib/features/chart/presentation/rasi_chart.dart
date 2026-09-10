import 'package:flutter/material.dart';

import '../../../core/astro/models.dart';
import '../../../core/config/app_locale.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/semantic_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'detail_sheets.dart';
import 'graha_label.dart';

/// South Indian rāśi chart.
///
/// A 4x4 grid with the centre hollow. Unlike the North Indian style the signs
/// sit in **fixed** positions — Meena top-left, then clockwise — and the lagna
/// is marked rather than being placed first. This is the layout Sri Lankan and
/// most South Indian users expect; showing them a North Indian diamond reads as
/// simply wrong.
class RasiChart extends StatelessWidget {
  const RasiChart({
    super.key,
    required this.chart,
    this.approximateHouses = false,
    this.caption,
  });

  final BirthChart chart;

  /// What to call this chart in the centre of the grid.
  ///
  /// Defaults to "Rāśi chart". A [Varga] projection is a BirthChart like any
  /// other — which is what lets every renderer work on it unchanged — so
  /// without this the navāṁśa draws itself and then labels itself the rāśi
  /// chart, which is the one thing on screen that is plainly false.
  final String? caption;

  /// True when the birth time was unknown, so the lagna is a convention rather
  /// than a computation and must not be presented as fact.
  final bool approximateHouses;

  /// Grid position of each rāśi, clockwise from Meena at top-left.
  static const List<int> _layout = [
    11, 0, 1, 2, //
    10, -1, -1, 3, //
    9, -1, -1, 4, //
    8, 7, 6, 5, //
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = L10n.of(context);
    final locale = AppLocale.of(context);
    final byRasi = <int, List<GrahaPosition>>{};
    for (final p in chart.positions.values) {
      byRasi.putIfAbsent(p.rasi.index, () => []).add(p);
    }
    final lagnaIndex = chart.lagnaRasi.index;

    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cell = constraints.maxWidth / 4;
          return Stack(
            children: [
              for (var i = 0; i < 16; i++)
                if (_layout[i] >= 0)
                  Positioned(
                    left: (i % 4) * cell,
                    top: (i ~/ 4) * cell,
                    width: cell,
                    height: cell,
                    child: _Cell(
                      rasi: Rasi.values[_layout[i]],
                      grahas: byRasi[_layout[i]] ?? const [],
                      // Whole-sign houses: counted forward from the lagna.
                      house: ((_layout[i] - lagnaIndex) % 12) + 1,
                      isLagna: _layout[i] == lagnaIndex,
                    ),
                  ),
              // Centre panel, where the hollow would otherwise be.
              Positioned(
                left: cell,
                top: cell,
                width: cell * 2,
                height: cell * 2,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Was a hardcoded Sinhala word above an English one,
                      // which was wrong in all three languages at once.
                      Text(
                        caption ?? l10n.chartCentreCaption,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        // "Virgo lagna", not "Lagna: Virgo" — the sign
                        // qualifies the lagna, and that is the order Sinhala
                        // and Tamil put it in.
                        l10n.chartLagnaOf(chart.lagnaRasi.label(locale)),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: context.semantic.accent,
                        ),
                      ),
                      if (approximateHouses)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            l10n.chartApproximateShort,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: context.semantic.inauspicious,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.rasi,
    required this.grahas,
    required this.house,
    required this.isLagna,
  });

  final Rasi rasi;
  final List<GrahaPosition> grahas;
  final int house;
  final bool isLagna;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocale.of(context);
    final l10n = L10n.of(context);
    return GestureDetector(
      // The cell, not the two-letter graha label: that label is a few pixels
      // wide on a 360 dp screen, and an empty house would have no tap target
      // at all.
      onTap: () =>
          showHouseDetail(context, rasi: rasi, house: house, grahas: grahas),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          color: isLagna ? context.semantic.accentSurface : Colors.transparent,
        ),
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isLagna)
                  Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: Text(
                      // Short for the word for "lagna" in each language, not a
                      // transliteration of the English "La", which would spell
                      // out a sound that means nothing (KAN-58).
                      l10n.chartLagnaMark,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: context.semantic.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Expanded(
                  child: Text(
                    rasi.label(locale),
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Wrap(
                spacing: 4,
                runSpacing: 2,
                children: [
                  for (final g in grahas)
                    GrahaLabel(position: g, style: theme.textTheme.labelMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
