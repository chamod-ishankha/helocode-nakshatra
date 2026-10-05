import 'package:flutter/material.dart';

import '../../../core/astro/models.dart';
import '../../../core/config/app_locale.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/brand_palette.dart';
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
    final palette = BrandPalette.of(context);
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
                    // A gap between cells rather than shared borders: twelve
                    // separate tiles read as twelve signs at a glance.
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: _Cell(
                        rasi: Rasi.values[_layout[i]],
                        grahas: byRasi[_layout[i]] ?? const [],
                        // Whole-sign houses: counted forward from the lagna.
                        house: ((_layout[i] - lagnaIndex) % 12) + 1,
                        isLagna: _layout[i] == lagnaIndex,
                      ),
                    ),
                  ),
              // Centre panel, where the hollow would otherwise be.
              Positioned(
                left: cell,
                top: cell,
                width: cell * 2,
                height: cell * 2,
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: palette.line),
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.2),
                        // The gold is composited onto the card colour first,
                        // so both stops share its transparency. A gradient
                        // from a nearly clear gold to a three-quarter white
                        // interpolates colour and alpha separately, and its
                        // middle was a fairly opaque ochre: a brown smudge.
                        colors: [
                          Color.alphaBlend(
                            context.semantic.accent.withValues(
                              alpha: theme.brightness == Brightness.dark
                                  ? 0.16
                                  : 0.08,
                            ),
                            palette.surface,
                          ),
                          palette.surface,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Was a hardcoded Sinhala word above an English one,
                          // which was wrong in all three languages at once.
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                caption ?? l10n.chartCentreCaption,
                                style: BrandFonts.displayStyle(
                                  context,
                                  size: 19,
                                  color: palette.text,
                                ),
                              ),
                            ),
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
                              // A warning sign as well as the red, and the word:
                              // the lagna on this chart is a convention, and
                              // that must survive a grey print of the share.
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    size: 13,
                                    color: context.semantic.inauspicious,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    l10n.chartApproximateShort,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: context.semantic.inauspicious,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
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
    final palette = BrandPalette.of(context);
    final semantic = context.semantic;
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
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isLagna ? semantic.accent : palette.line),
          color: isLagna ? semantic.accentSurface : palette.surface,
        ),
        padding: const EdgeInsets.fromLTRB(5, 4, 5, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Scaled down to fit rather than cut off. "விருச்சிகம்" in a
                // 76 dp cell ellipsised to "விருச்…", which is not a sign.
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      rasi.label(locale),
                      maxLines: 1,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: palette.muted,
                      ),
                    ),
                  ),
                ),
                if (isLagna)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 3),
                    child: Text(
                      // Short for the word for "lagna" in each language, not a
                      // transliteration of the English "La", which would spell
                      // out a sound that means nothing (KAN-58).
                      l10n.chartLagnaMark,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: semantic.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.bottomStart,
                child: Wrap(
                  spacing: 4,
                  runSpacing: 1,
                  children: [
                    for (final g in grahas)
                      GrahaLabel(
                        position: g,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: palette.text,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
