import 'package:flutter/material.dart';

import '../theme/brand_palette.dart';

/// What a [BrandButton] is for, which decides how loud it is.
enum BrandButtonTone {
  /// The screen's one decisive action: violet.
  primary,

  /// Earning something by watching a video: gold, the colour of every
  /// rewarded unlock, so "watch" reads the same wherever it appears.
  reward,

  /// The quieter second choice beside one of the others.
  outline,
}

/// The redesign's button: a pill (KAN-80).
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
    this.leading,
    this.tone = BrandButtonTone.primary,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Full width, for a screen's one decisive action.
  final bool expand;

  /// A small glyph after the label, such as an arrow.
  final IconData? trailing;

  /// A widget before the label: an icon, or a spinner while busy.
  final Widget? leading;

  final BrandButtonTone tone;

  @override
  Widget build(BuildContext context) {
    final palette = BrandPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final enabled = onPressed != null;

    // Each pairing clears 7:1 between label and fill.
    final (
      Color foreground,
      Gradient? gradient,
      Color? fill,
      Color? border,
    ) = switch (tone) {
      BrandButtonTone.primary => (
        dark ? const Color(0xFF1A1033) : Colors.white,
        LinearGradient(
          colors: dark
              ? const [Color(0xFFC9A8F2), Color(0xFF8F6CC8)]
              : const [Color(0xFF7D5DB0), Color(0xFF55397F)],
        ),
        null,
        null,
      ),
      BrandButtonTone.reward => (
        const Color(0xFF241A05),
        const LinearGradient(colors: [Color(0xFFE6BE6A), Color(0xFFC2902F)]),
        null,
        null,
      ),
      BrandButtonTone.outline => (
        palette.text,
        null,
        palette.surfaceHigh,
        palette.line,
      ),
    };

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leading != null) ...[
          IconTheme(
            data: IconThemeData(color: foreground, size: 18),
            child: leading!,
          ),
          const SizedBox(width: 8),
        ],
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
            gradient: gradient,
            color: fill,
            border: border == null ? null : Border.all(color: border),
            boxShadow: tone == BrandButtonTone.outline
                ? null
                : [
                    BoxShadow(
                      color:
                          (tone == BrandButtonTone.reward
                                  ? const Color(0xFFC2902F)
                                  : palette.violet)
                              .withValues(alpha: dark ? 0.35 : 0.25),
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
