import 'package:flutter/material.dart';

import '../theme/brand_palette.dart';
import '../theme/semantic_colors.dart';

/// How a [BrandCard] is tinted.
enum BrandCardTone {
  /// The default glass card.
  plain,

  /// Gold wash and border: something a short video opens, or a value to
  /// read first.
  gold,

  /// Green wash and border: free, or already yours.
  free,

  /// Violet border over a violet wash: something only Pro or a purchase
  /// opens (KAN-93).
  paid,
}

/// The redesign's card (KAN-80): one radius, one border, one padding.
///
/// The old screens mixed corner radii of 8, 10, 12 and 20 and copied the same
/// outlined `Card` + `ListTile` by hand; this is the one card the redesigned
/// screens use instead.
class BrandCard extends StatelessWidget {
  const BrandCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.tone = BrandCardTone.plain,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BrandCardTone tone;
  final VoidCallback? onTap;

  static const double radius = 24;

  @override
  Widget build(BuildContext context) {
    final palette = BrandPalette.of(context);
    final semantic = context.semantic;

    // One rule for every lock and offer in the app, so a reader can tell at a
    // glance what is free, what a video opens and what is bought. It used to
    // be the same gold card for all three.
    final (Color border, Color? fill, Gradient? wash) = switch (tone) {
      BrandCardTone.plain => (palette.line, palette.surface, null),
      BrandCardTone.gold => (semantic.accent, semantic.accentSurface, null),
      BrandCardTone.free => (
        semantic.auspicious,
        semantic.auspiciousSurface,
        null,
      ),
      // Composited onto the card colour first, so both stops share one
      // transparency and the wash fades rather than going muddy (KAN-83).
      BrandCardTone.paid => (
        palette.violet,
        null,
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
              palette.violet.withValues(alpha: 0.20),
              palette.surface,
            ),
            palette.surface,
          ],
        ),
      ),
    };

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: border),
    );

    return Material(
      type: MaterialType.transparency,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: ShapeDecoration(color: fill, gradient: wash, shape: shape),
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
