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
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

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
            dimension: 40,
            child: Icon(icon, size: 20, color: palette.text),
          ),
        ),
      ),
    );
  }
}
