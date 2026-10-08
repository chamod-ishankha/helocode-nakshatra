import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/semantic_colors.dart';
import '../../../core/ui/nakshatra_star.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../core/ui/disclaimer.dart';

/// The publisher's moment: the HeloCode "Slash H" drawing itself (KAN-81).
///
/// Always dark and never translated. It is the same few seconds on every
/// HeloCode app, which is the point of it.
class HeloCodePresents extends StatelessWidget {
  const HeloCodePresents({super.key, required this.progress});

  /// 0..1 across the scene.
  final double progress;

  @override
  Widget build(BuildContext context) {
    final word = staggered(progress, 0.33, 0.58);
    final presents = staggered(progress, 0.44, 0.69);

    return DecoratedBox(
      // Both stops opaque. The overlay sits on top of the first screen, and a
      // translucent centre let the language list show through the mark.
      // The inner stop is the brand green at 10% already composited onto the
      // background.
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          radius: 0.6,
          colors: [Color(0xFF0B1D1C), HeloCodeBrand.background],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 96,
              child: CustomPaint(painter: HeloCodeMarkPainter(progress)),
            ),
            const SizedBox(height: 18),
            _Rise(
              t: word,
              child: const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'helo'),
                    TextSpan(
                      text: 'code',
                      style: TextStyle(
                        color: HeloCodeBrand.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                style: TextStyle(
                  fontFamily: BrandFonts.heloCode,
                  fontWeight: FontWeight.w600,
                  fontSize: 30,
                  letterSpacing: -1.2,
                  color: HeloCodeBrand.ink,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _Rise(
              t: presents,
              child: const Text(
                // English in every language, like the mark: it is the
                // publisher's signature, not app copy.
                'PRESENTS',
                style: TextStyle(
                  fontFamily: BrandFonts.heloCode,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  letterSpacing: 4,
                  color: HeloCodeBrand.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The Slash H: two bars rise, then the gradient slash draws across them.
///
/// Geometry is the brand SVG's 64-unit box, unchanged, so the mark here and on
/// helocode.top are the same drawing.
class HeloCodeMarkPainter extends CustomPainter {
  HeloCodeMarkPainter(this.progress, {this.stems = HeloCodeBrand.ink});

  final double progress;
  final Color stems;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.shortestSide / 64;
    canvas.scale(u);

    void stem(double x, double t) {
      if (t <= 0) return;
      const top = 13.0, height = 38.0;
      canvas.drawRRect(
        RRect.fromLTRBR(
          x,
          top + height * (1 - t),
          x + 9,
          top + height,
          const Radius.circular(4.5),
        ),
        Paint()..color = stems,
      );
    }

    stem(15, staggered(progress, 0, 0.23));
    stem(40, staggered(progress, 0.05, 0.28));

    final slash = staggered(progress, 0.19, 0.4);
    if (slash > 0) {
      const from = Offset(21, 40.5), to = Offset(43, 23.5);
      canvas.drawLine(
        from,
        Offset.lerp(from, to, slash)!,
        Paint()
          ..strokeWidth = 8.5
          ..strokeCap = StrokeCap.round
          ..shader = const LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [HeloCodeBrand.green, HeloCodeBrand.blue],
          ).createShader(const Rect.fromLTWH(0, 0, 64, 64)),
      );
    }
  }

  @override
  bool shouldRepaint(HeloCodeMarkPainter old) =>
      old.progress != progress || old.stems != stems;
}

/// The Nakshatra splash (KAN-81).
///
/// [brief] is the returning user's version: the star is already finished and
/// centred, where the platform splash left it, and only the name and tagline
/// arrive. A daily-use app does not make its readers watch it draw itself
/// every morning.
class NakshatraSplash extends StatelessWidget {
  const NakshatraSplash({
    super.key,
    required this.progress,
    required this.brief,
  });

  final double progress;
  final bool brief;

  @override
  Widget build(BuildContext context) {
    final palette = BrandPalette.of(context);
    final l10n = L10n.of(context);

    final star = brief
        ? 1.0
        : staggered(progress, 0, 0.6, curve: Curves.linear);
    final glow = brief
        ? staggered(progress, 0, 0.5)
        : staggered(progress, 0.45, 0.75);
    double fade(double a, double b) => brief
        ? staggered(progress, a * 0.4, b * 0.4 + 0.2)
        : staggered(progress, a, b);

    final title = Column(
      children: [
        _Rise(
          t: fade(0.4, 0.62),
          child: Text(
            'Nakshatra',
            style: BrandFonts.displayStyle(
              context,
              size: 40,
              color: palette.text,
            ).copyWith(fontSize: 40, height: 1.1),
          ),
        ),
        const SizedBox(height: 8),
        _Rise(
          t: fade(0.48, 0.7),
          // The name in the other two scripts, shown in every language: the
          // bridge word is the point of the name.
          child: Text(
            'නක්ෂත්‍ර · நட்சத்திரம்',
            style: TextStyle(
              fontFamily: AppTheme.sinhalaFont,
              fontFamilyFallback: AppTheme.scriptFallbacks,
              fontSize: 15,
              color: palette.muted,
            ),
          ),
        ),
        const SizedBox(height: 18),
        _Rise(
          t: fade(0.56, 0.8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              l10n.splashTagline,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.5, color: palette.muted),
            ),
          ),
        ),
      ],
    );

    final footer = Opacity(
      opacity: fade(0.66, 0.9),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox.square(
                dimension: 16,
                child: CustomPaint(
                  painter: HeloCodeMarkPainter(1, stems: palette.text),
                ),
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  l10n.splashPublisher,
                  style: TextStyle(fontSize: 12.5, color: palette.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Disclaimer(),
        ],
      ),
    );

    // A stack, not a column: the star is pinned to the centre of the whole
    // screen, the name hangs below it and the footer sits on the bottom edge.
    // A column split the screen into fixed halves, and on a short window the
    // lower half overflowed. Here a short window only brings the name closer
    // to the footer.
    return DecoratedBox(
      decoration: BoxDecoration(gradient: palette.backdrop),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.05),
                radius: 0.75,
                colors: [
                  _logoGold.withValues(alpha: 0.22),
                  _logoGold.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          const StaticSky(),
          // Centred on the whole screen, not a SafeArea, and sized and
          // coloured to the platform splash's own star: the hand-off reads as
          // one image settling rather than two swapping.
          Center(
            child: SizedBox.square(
              dimension: _starSize,
              child: CustomPaint(
                painter: NakshatraStarPainter(
                  progress: star,
                  color: _logoGold,
                  glow: glow,
                ),
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, box) => Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: box.maxHeight / 2 + _starSize / 2 + 26,
                  child: title,
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 28 + MediaQuery.paddingOf(context).bottom,
                  child: footer,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const double _starSize = 200;
}

/// The gold of the logo and the platform splash image.
///
/// Not [SemanticColors.accent]: that gold is darkened in the light theme so
/// text clears 4.5:1, and the star is a picture, not text. Using it here made
/// the star visibly change colour at the hand-off from the platform splash.
const _logoGold = Color(0xFFD6A537);

/// A field of small stars at fixed places.
///
/// Static on purpose. A twinkle is a repeating animation, and one behind a
/// screen that otherwise rests keeps the GPU awake for nothing — on the cheap
/// phones this market uses, that is battery.
class StaticSky extends StatelessWidget {
  const StaticSky({super.key, this.count = 26});

  final int count;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(
      painter: _SkyPainter(BrandPalette.of(context).skyDot, count),
    ),
  );
}

class _SkyPainter extends CustomPainter {
  _SkyPainter(this.color, this.count);

  final Color color;
  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    // Seeded, so the sky is the same every launch rather than reshuffling.
    final random = math.Random(27);
    for (var i = 0; i < count; i++) {
      final p = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height * 0.7,
      );
      canvas.drawCircle(
        p,
        0.6 + random.nextDouble() * 0.9,
        Paint()
          ..color = color.withValues(alpha: 0.25 + random.nextDouble() * 0.5),
      );
    }
  }

  @override
  bool shouldRepaint(_SkyPainter old) =>
      old.color != color || old.count != count;
}

/// Fades a child in while lifting it into place.
class _Rise extends StatelessWidget {
  const _Rise({required this.t, required this.child});

  final double t;
  final Widget child;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: t,
    child: Transform.translate(offset: Offset(0, 10 * (1 - t)), child: child),
  );
}
