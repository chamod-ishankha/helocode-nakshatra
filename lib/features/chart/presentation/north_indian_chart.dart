import 'package:flutter/material.dart';

import '../../../core/astro/models.dart';
import '../../../core/theme/app_theme.dart';

/// North Indian rāśi chart.
///
/// The inverse of the South Indian layout: here the **houses** are fixed and
/// the rāśi rotate. House 1 is always the top-centre diamond, and the sign
/// occupying it is written as a number. Houses run anticlockwise from there.
///
/// A square with both diagonals plus an inner diamond divides into twelve
/// regions — four rhombi at the compass points and eight corner triangles.
class NorthIndianChart extends StatelessWidget {
  const NorthIndianChart({
    super.key,
    required this.chart,
    this.approximateHouses = false,
  });

  final BirthChart chart;
  final bool approximateHouses;

  /// Unit-square outline of each house, house 1 first.
  ///
  /// Derived from the square's corners, edge midpoints, centre, and the four
  /// points where the diagonals cross the inner diamond.
  static const List<List<Offset>> _houses = [
    // 1 — top rhombus
    [Offset(.5, 0), Offset(.75, .25), Offset(.5, .5), Offset(.25, .25)],
    // 2 — upper-left triangle
    [Offset(.5, 0), Offset(.25, .25), Offset(0, 0)],
    // 3 — left-upper triangle
    [Offset(0, 0), Offset(.25, .25), Offset(0, .5)],
    // 4 — left rhombus
    [Offset(0, .5), Offset(.25, .25), Offset(.5, .5), Offset(.25, .75)],
    // 5 — left-lower triangle
    [Offset(0, .5), Offset(.25, .75), Offset(0, 1)],
    // 6 — lower-left triangle
    [Offset(0, 1), Offset(.25, .75), Offset(.5, 1)],
    // 7 — bottom rhombus
    [Offset(.5, 1), Offset(.25, .75), Offset(.5, .5), Offset(.75, .75)],
    // 8 — lower-right triangle
    [Offset(.5, 1), Offset(.75, .75), Offset(1, 1)],
    // 9 — right-lower triangle
    [Offset(1, 1), Offset(.75, .75), Offset(1, .5)],
    // 10 — right rhombus
    [Offset(1, .5), Offset(.75, .75), Offset(.5, .5), Offset(.75, .25)],
    // 11 — right-upper triangle
    [Offset(1, .5), Offset(.75, .25), Offset(1, 0)],
    // 12 — upper-right triangle
    [Offset(1, 0), Offset(.75, .25), Offset(.5, 0)],
  ];

  static Offset _centroid(List<Offset> pts) {
    var x = 0.0, y = 0.0;
    for (final p in pts) {
      x += p.dx;
      y += p.dy;
    }
    return Offset(x / pts.length, y / pts.length);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final byHouse = <int, List<GrahaPosition>>{};
    for (final p in chart.positions.values) {
      byHouse.putIfAbsent(p.house, () => []).add(p);
    }
    final lagnaSign = chart.lagnaRasi.index;

    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.maxWidth;
          return Stack(
            children: [
              CustomPaint(
                size: Size.square(size),
                painter: _NorthIndianPainter(color: theme.dividerColor),
              ),
              for (var h = 1; h <= 12; h++)
                _label(context, size, h, byHouse[h] ?? const [], lagnaSign),
            ],
          );
        },
      ),
    );
  }

  Widget _label(
    BuildContext context,
    double size,
    int house,
    List<GrahaPosition> grahas,
    int lagnaSign,
  ) {
    final theme = Theme.of(context);
    final c = _centroid(_houses[house - 1]);

    // The sign occupying this house, counted forward from the lagna.
    final rasiNumber = ((lagnaSign + house - 1) % 12) + 1;

    // Regions differ a lot in area, so the label box is sized generously and
    // allowed to overflow rather than clipping graha names in the triangles.
    const boxW = 0.30, boxH = 0.24;
    return Positioned(
      left: (c.dx - boxW / 2) * size,
      top: (c.dy - boxH / 2) * size,
      width: boxW * size,
      height: boxH * size,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$rasiNumber',
            style: theme.textTheme.labelSmall?.copyWith(
              color: house == 1
                  ? AppColors.accent
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: house == 1 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Flexible(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 3,
              children: [
                for (final g in grahas)
                  Text(
                    '${g.graha.en.substring(0, 2)}${g.isRetrograde ? '℞' : ''}',
                    style: theme.textTheme.labelSmall?.copyWith(
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

class _NorthIndianPainter extends CustomPainter {
  _NorthIndianPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final w = size.width, h = size.height;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), paint);

    // Both diagonals.
    canvas.drawLine(Offset.zero, Offset(w, h), paint);
    canvas.drawLine(Offset(w, 0), Offset(0, h), paint);

    // Inner diamond joining the edge midpoints.
    final diamond = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w, h / 2)
      ..lineTo(w / 2, h)
      ..lineTo(0, h / 2)
      ..close();
    canvas.drawPath(diamond, paint);
  }

  @override
  bool shouldRepaint(_NorthIndianPainter old) => old.color != color;
}
