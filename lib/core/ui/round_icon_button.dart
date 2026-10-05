import 'package:flutter/material.dart';

import '../theme/brand_palette.dart';

/// A 40px round button with a hairline border: back, share, close (KAN-80).
///
/// The tooltip is required. An icon with no words is invisible to a screen
/// reader, and several of the old app bar's icons shipped without one.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.dimension = 40,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  /// 40 by default; 32 where it closes something small, like a nudge.
  final double dimension;

  @override
  Widget build(BuildContext context) {
    final palette = BrandPalette.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: palette.surface,
        shape: CircleBorder(side: BorderSide(color: palette.line)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox.square(
            dimension: dimension,
            child: Icon(icon, size: dimension / 2, color: palette.text),
          ),
        ),
      ),
    );
  }
}
