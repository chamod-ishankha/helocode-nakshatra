import 'package:flutter/material.dart';

import '../theme/brand_palette.dart';

/// The redesign's primary action: a violet pill (KAN-80).
///
/// Never a fixed width or a single line. "Get Pro yearly" is three words in
/// English and runs to two lines in Tamil, so the label wraps and the pill
/// grows rather than truncating it.
class BrandButton extends StatelessWidget {
  const BrandButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.expand = false,
    this.trailing,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Full width, for a screen's one decisive action.
  final bool expand;

  /// A small glyph after the label, such as an arrow.
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final enabled = onPressed != null;
    // Dark text on the light violet in the dark theme, light text on the deep
    // violet in the light one: both clear 7:1.
    final foreground = dark ? const Color(0xFF1A1033) : Colors.white;
    final gradient = dark
        ? const [Color(0xFFC9A8F2), Color(0xFF8F6CC8)]
        : const [Color(0xFF7D5DB0), Color(0xFF55397F)];

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: foreground,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          Icon(trailing, size: 18, color: foreground),
        ],
      ],
    );

    return Semantics(
      button: true,
      enabled: enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(colors: gradient),
            boxShadow: [
              BoxShadow(
                color: BrandPalette.of(
                  context,
                ).violet.withValues(alpha: dark ? 0.35 : 0.25),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: onPressed,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 52),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Center(widthFactor: 1, child: content),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
