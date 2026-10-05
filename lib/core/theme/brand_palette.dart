import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'semantic_colors.dart';

/// The surfaces of the redesign (KAN-80): night sky in dark, parchment in
/// light.
///
/// Separate from the Material [ColorScheme] for now, because the redesign
/// lands a screen at a time and the screens not yet redrawn still read the
/// seeded scheme. Once every screen is on these, the scheme is generated from
/// them rather than from a single seed.
///
/// Gold is not here. It already exists, contrast-checked, as
/// [SemanticColors.accent], and two golds that drift apart is exactly the
/// problem that class was written to stop.
@immutable
class BrandPalette {
  const BrandPalette({
    required this.background,
    required this.backgroundDeep,
    required this.surface,
    required this.surfaceHigh,
    required this.line,
    required this.text,
    required this.muted,
    required this.violet,
    required this.skyDot,
  });

  /// The splash background. In dark it is the native splash colour exactly
  /// (`flutter_native_splash` in pubspec.yaml), so the hand-off from the
  /// platform splash to the first Flutter frame does not flash.
  final Color background;

  /// The bottom of the background gradient.
  final Color backgroundDeep;

  /// A card sitting on [background].
  final Color surface;

  /// A raised or selected card.
  final Color surfaceHigh;

  /// Hairlines and card borders.
  final Color line;

  final Color text;

  /// Secondary text. Still clears 4.5:1 on [background].
  final Color muted;

  /// The second accent, for orbits and the primary button. Never carries
  /// meaning on its own.
  final Color violet;

  /// The twinkling stars: white at night, gold on parchment.
  final Color skyDot;

  static const dark = BrandPalette(
    background: Color(0xFF171437),
    backgroundDeep: Color(0xFF0A0818),
    surface: Color(0x0FFFFFFF),
    surfaceHigh: Color(0x1AFFFFFF),
    line: Color(0x1FFFFFFF),
    text: Color(0xFFF3EFFA),
    muted: Color(0xFFA9A2C2),
    violet: Color(0xFFB79CE0),
    skyDot: Color(0xFFFFFFFF),
  );

  static const light = BrandPalette(
    background: Color(0xFFFBF6EC),
    backgroundDeep: Color(0xFFEDE2CB),
    surface: Color(0xBFFFFFFF),
    surfaceHigh: Color(0xFFFFFFFF),
    line: Color(0x1F3C285A),
    text: Color(0xFF241C3A),
    muted: Color(0xFF6F6785),
    violet: Color(0xFF6B4E9B),
    skyDot: Color(0xFF8C6521),
  );

  static BrandPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  /// The night-to-deep gradient every full-bleed brand screen sits on.
  LinearGradient get backdrop => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [background, backgroundDeep],
  );
}

/// The faces the redesign adds. Both bundled, never fetched: the app works
/// with no connection, and that includes how it looks.
abstract final class BrandFonts {
  /// Fraunces, for times, titles and the brand name. Latin only; the script
  /// fallbacks carry Sinhala and Tamil.
  static const String display = 'Fraunces';

  /// Geist, for the HeloCode wordmark and nothing else.
  static const String heloCode = 'Geist';

  /// A display style that still draws Sinhala and Tamil.
  ///
  /// Sinhala and Tamil sit taller than Latin, so a script headline gets more
  /// line height and a smaller size. Measured against the intro copy, where
  /// the Tamil title runs to three lines at the English size.
  static TextStyle displayStyle(
    BuildContext context, {
    required double size,
    required Color color,
  }) {
    final latin = Localizations.localeOf(context).languageCode == 'en';
    return TextStyle(
      fontFamily: display,
      fontFamilyFallback: AppTheme.scriptFallbacks,
      fontWeight: FontWeight.w600,
      fontSize: latin ? size : size * 0.84,
      height: latin ? 1.15 : 1.35,
      color: color,
    );
  }
}

/// HeloCode Labs' own colours, for the publisher's moment at first launch.
///
/// Not themed on purpose: it is the same on every HeloCode app, in either
/// theme. Values from the brand guide in the helocode.top repository.
abstract final class HeloCodeBrand {
  static const Color green = Color(0xFF3EE7A0);
  static const Color blue = Color(0xFF38BDF8);
  static const Color ink = Color(0xFFFAFAFA);
  static const Color grey = Color(0xFF7D7D88);
  static const Color background = Color(0xFF05060D);
}
