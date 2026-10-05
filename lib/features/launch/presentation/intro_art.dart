import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/semantic_colors.dart';
import '../../../core/ui/nakshatra_star.dart';

/// The three intro illustrations (KAN-81). Drawn, not images: they scale to
/// any screen, follow the theme, and cost nothing in the APK.
enum IntroArtKind { onPhone, languages, private }

class IntroArt extends StatefulWidget {
  const IntroArt(this.kind, {super.key});

  final IntroArtKind kind;

  @override
  State<IntroArt> createState() => _IntroArtState();
}

class _IntroArtState extends State<IntroArt> with TickerProviderStateMixin {
  /// Lines drawing in, once, when the slide arrives.
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  /// The slow ambient motion: the orbit, the pulse. Repeats while visible.
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: Duration(
      milliseconds: widget.kind == IntroArtKind.private ? 2600 : 14000,
    ),
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _enter.value = 1;
    } else {
      _enter.forward();
      _loop.repeat();
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = BrandPalette.of(context);
    final gold = context.semantic.accent;

    return AspectRatio(
      aspectRatio: 1,
      child: AnimatedBuilder(
        animation: Listenable.merge([_enter, _loop]),
        builder: (context, _) => switch (widget.kind) {
          IntroArtKind.languages => _Languages(t: _enter.value, gold: gold),
          IntroArtKind.onPhone => CustomPaint(
            painter: _OnPhonePainter(
              enter: _enter.value,
              orbit: _loop.value,
              gold: gold,
              violet: palette.violet,
              line: palette.line,
            ),
          ),
          IntroArtKind.private => CustomPaint(
            painter: _PrivatePainter(
              enter: _enter.value,
              pulse: _loop.value,
              gold: gold,
              violet: palette.violet,
            ),
          ),
        },
      ),
    );
  }
}

Paint _stroke(Color color, double width) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round
  ..color = color;

/// A phone with the star inside it, and the sky orbiting round: the chart is
/// worked out here.
class _OnPhonePainter extends CustomPainter {
  _OnPhonePainter({
    required this.enter,
    required this.orbit,
    required this.gold,
    required this.violet,
    required this.line,
  });

  final double enter, orbit;
  final Color gold, violet, line;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.shortestSide / 270);
    const c = Offset(135, 135);

    // Dotted orbit.
    final dots = _stroke(line, 1.5);
    for (var i = 0; i < 60; i++) {
      final a = i * math.pi / 30;
      canvas.drawCircle(
        c + Offset(118 * math.cos(a), 118 * math.sin(a)),
        0.9,
        dots,
      );
    }
    final a = orbit * 2 * math.pi - math.pi / 2;
    canvas
      ..drawCircle(
        c + Offset(118 * math.cos(a), 118 * math.sin(a)),
        7,
        Paint()..color = gold,
      )
      ..drawCircle(
        c +
            Offset(
              118 * math.cos(a + math.pi / 2),
              118 * math.sin(a + math.pi / 2),
            ),
        4.5,
        Paint()..color = violet,
      );

    final phone = Path()
      ..addRRect(RRect.fromLTRBR(90, 52, 180, 218, const Radius.circular(18)));
    canvas
      ..drawPath(partialPath(phone, staggered(enter, 0, 0.6)), _stroke(gold, 3))
      ..drawPath(
        partialPath(
          Path()
            ..moveTo(120, 66)
            ..lineTo(150, 66),
          staggered(enter, 0.35, 0.6),
        ),
        _stroke(gold, 3),
      )
      ..drawPath(
        partialPath(nakshatraStarPath(c, 26, 13), staggered(enter, 0.5, 1)),
        _stroke(gold, 3),
      );
  }

  @override
  bool shouldRepaint(_OnPhonePainter old) =>
      old.enter != enter || old.orbit != orbit || old.gold != gold;
}

/// A padlock whose keyhole is the star, with a slow pulse: it stays with you.
class _PrivatePainter extends CustomPainter {
  _PrivatePainter({
    required this.enter,
    required this.pulse,
    required this.gold,
    required this.violet,
  });

  final double enter, pulse;
  final Color gold, violet;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.shortestSide / 270);
    const c = Offset(135, 135);

    for (final (color, offset) in [(gold, 0.0), (violet, 0.5)]) {
      final t = (pulse + offset) % 1;
      canvas.drawCircle(
        c,
        90 * (0.6 + 0.65 * t),
        _stroke(color.withValues(alpha: 0.7 * (1 - t)), 1.2),
      );
    }

    final body = Path()
      ..addRRect(RRect.fromLTRBR(80, 128, 190, 210, const Radius.circular(8)));
    final shackle = Path()
      ..moveTo(102, 128)
      ..lineTo(102, 104)
      ..arcToPoint(const Offset(168, 104), radius: const Radius.circular(33))
      ..lineTo(168, 128);
    canvas
      ..drawPath(partialPath(body, staggered(enter, 0, 0.55)), _stroke(gold, 3))
      ..drawPath(
        partialPath(shackle, staggered(enter, 0.3, 0.75)),
        _stroke(gold, 3),
      )
      ..drawPath(
        partialPath(
          nakshatraStarPath(const Offset(135, 170), 15, 8),
          staggered(enter, 0.6, 1),
        ),
        _stroke(gold, 2.5),
      );
  }

  @override
  bool shouldRepaint(_PrivatePainter old) =>
      old.enter != enter || old.pulse != pulse || old.gold != gold;
}

/// Three cards fanning out, one per script: each language in its own letters.
class _Languages extends StatelessWidget {
  const _Languages({required this.t, required this.gold});

  final double t;
  final Color gold;

  @override
  Widget build(BuildContext context) {
    final palette = BrandPalette.of(context);

    Widget card(
      String glyph,
      String family, {
      required double angle,
      required double dx,
      required double begin,
      bool front = false,
    }) {
      final p = staggered(t, begin, begin + 0.55);
      return Opacity(
        opacity: p,
        child: Transform.translate(
          offset: Offset(dx * p, 20 * (1 - p)),
          child: Transform.rotate(
            angle: angle * p,
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 104,
              height: 134,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: front ? palette.background : palette.surfaceHigh,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: front ? gold : palette.line),
              ),
              child: Text(
                glyph,
                style: TextStyle(
                  fontFamily: family,
                  fontFamilyFallback: AppTheme.scriptFallbacks,
                  fontWeight: front ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 52,
                  color: front ? gold : palette.text,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return FittedBox(
      child: SizedBox(
        width: 270,
        height: 270,
        child: Stack(
          alignment: Alignment.center,
          children: [
            card('සි', AppTheme.sinhalaFont, angle: -0.24, dx: -46, begin: 0.1),
            card('த', AppTheme.tamilFont, angle: 0.24, dx: 46, begin: 0.2),
            card(
              'A',
              BrandFonts.display,
              angle: 0,
              dx: 0,
              begin: 0.3,
              front: true,
            ),
          ],
        ),
      ),
    );
  }
}
