import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/rendering.dart';

/// The eight-point star from the app icon, as a path.
///
/// Tips on the compass points and the diagonals, valleys between them. Drawn
/// rather than shipped as an image so it can draw itself on the splash and be
/// reused, at any size, as a motif elsewhere.
Path nakshatraStarPath(Offset center, double tip, double valley) {
  final path = Path();
  for (var i = 0; i < 16; i++) {
    final angle = (-90 + i * 22.5) * math.pi / 180;
    final r = i.isOdd ? valley : tip;
    final point = center + Offset(r * math.cos(angle), r * math.sin(angle));
    i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
  }
  return path..close();
}

/// The first [t] of [path]'s length, for a line that draws itself.
Path partialPath(Path path, double t) {
  if (t <= 0) return Path();
  if (t >= 1) return path;

  final metrics = path.computeMetrics().toList();
  var remaining = metrics.fold<double>(0, (sum, m) => sum + m.length) * t;
  final out = Path();
  for (final metric in metrics) {
    final take = math.min(remaining, metric.length);
    out.addPath(metric.extractPath(0, take), Offset.zero);
    remaining -= take;
    if (remaining <= 0) break;
  }
  return out;
}

/// [t] mapped onto the window [begin]..[end], eased. Before the window it is
/// 0 and after it 1, so one controller can stagger several parts.
double staggered(
  double t,
  double begin,
  double end, {
  Curve curve = Curves.easeOutCubic,
}) => curve.transform(((t - begin) / (end - begin)).clamp(0.0, 1.0));

/// The star, drawn to [progress]: outline first, then the inner star, then the
/// spokes, then the centre.
///
/// At 1 it is the finished mark, so a caller that should not animate — reduced
/// motion, or a returning user picking up from the platform splash — passes 1
/// and gets the logo.
class NakshatraStarPainter extends CustomPainter {
  NakshatraStarPainter({
    required this.progress,
    required this.color,
    this.glow = 0,
  });

  final double progress;
  final Color color;

  /// 0..1 strength of the halo behind the lines.
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    // Geometry is in a 220-unit box, the size the mock was drawn at.
    final unit = size.shortestSide / 220;
    final c = size.center(Offset.zero);

    final outer = partialPath(
      nakshatraStarPath(c, 96 * unit, 50 * unit),
      staggered(progress, 0, 0.55),
    );
    final inner = partialPath(
      nakshatraStarPath(c, 70 * unit, 38 * unit),
      staggered(progress, 0.3, 0.8),
    );
    final spokeT = staggered(progress, 0.45, 0.9);
    final spokes = Path();
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      spokes
        ..moveTo(c.dx, c.dy)
        ..lineTo(
          c.dx + 96 * unit * spokeT * math.cos(a),
          c.dy + 96 * unit * spokeT * math.sin(a),
        );
    }
    final coreT = staggered(progress, 0.85, 1);

    void lines(Paint base) {
      canvas
        ..drawPath(outer, Paint.from(base)..strokeWidth = 5 * unit)
        ..drawPath(inner, Paint.from(base)..strokeWidth = 3.4 * unit);
      if (spokeT > 0) {
        canvas.drawPath(spokes, Paint.from(base)..strokeWidth = 3.4 * unit);
      }
    }

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = color;

    if (glow > 0) {
      lines(
        Paint.from(stroke)
          ..color = color.withValues(alpha: 0.45 * glow)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 * unit),
      );
    }
    lines(stroke);
    if (coreT > 0) {
      canvas.drawCircle(
        c,
        5 * unit,
        Paint()..color = color.withValues(alpha: coreT),
      );
    }
  }

  @override
  bool shouldRepaint(NakshatraStarPainter old) =>
      old.progress != progress || old.color != color || old.glow != glow;
}
