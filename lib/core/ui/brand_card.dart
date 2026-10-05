import 'package:flutter/material.dart';

import '../theme/brand_palette.dart';
import '../theme/semantic_colors.dart';

/// How a [BrandCard] is tinted.
enum BrandCardTone {
  /// The default glass card.
  plain,

  /// Gold wash and border: something to earn or buy, or a value to read first.
  gold,
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
    final gold = tone == BrandCardTone.gold;

    return Material(
      color: gold ? semantic.accentSurface : palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: gold ? semantic.accent : palette.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
