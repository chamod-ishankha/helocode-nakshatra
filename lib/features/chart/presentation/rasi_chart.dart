import 'package:flutter/material.dart';

import '../../../core/astro/models.dart';
import '../../../core/theme/app_theme.dart';

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
  });

  final BirthChart chart;

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
                      Text('රාශි', style: theme.textTheme.titleMedium),
                      Text('Rāśi chart', style: theme.textTheme.bodySmall),
                      const SizedBox(height: 8),
                      Text(
                        'Lagna: ${chart.lagnaRasi.en}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.accent,
                        ),
                      ),
                      if (approximateHouses)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'approximate',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.inauspicious,
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
    required this.isLagna,
  });

  final Rasi rasi;
  final List<GrahaPosition> grahas;
  final bool isLagna;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        color: isLagna
            ? AppColors.accent.withValues(alpha: 0.10)
            : Colors.transparent,
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
                    'La',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  rasi.en,
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
                  Text(
                    // Two-letter abbreviations keep nine grahas legible in a
                    // cell that is roughly 70px wide on a small phone.
                    '${g.graha.en.substring(0, 2)}${g.isRetrograde ? '℞' : ''}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: g.isRetrograde
                          ? AppColors.inauspicious
                          : theme.colorScheme.onSurface,
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
