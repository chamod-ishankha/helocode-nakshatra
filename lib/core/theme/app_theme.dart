import 'package:flutter/material.dart';

import '../config/app_locale.dart';

/// Placeholder palette.
///
/// Deliberately provisional — the real visual direction is decided in KAN-25.
/// These are here so screens can be built against tokens rather than hardcoded
/// colours, which makes the eventual restyle a one-file change.
abstract final class AppColors {
  static const Color primary = Color(0xFF6B4E9B);
  static const Color primaryDark = Color(0xFFB79CE0);
  static const Color accent = Color(0xFFD4A24C);

  /// Inauspicious periods — rahu kalaya, yamaganda, gulika.
  static const Color inauspicious = Color(0xFFC0392B);

  /// Auspicious windows — subha nekath.
  static const Color auspicious = Color(0xFF2E7D5B);
}

abstract final class AppTheme {
  /// Sinhala and Tamil glyphs are taller than Latin and clip at Material's
  /// default line heights. A global height multiplier is applied to body text
  /// so trilingual layouts do not need per-string fixes later.
  static const double _scriptLineHeight = 1.45;

  static const String sinhalaFont = 'NotoSansSinhala';
  static const String tamilFont = 'NotoSansTamil';

  /// Every script the app can render, regardless of the interface language.
  ///
  /// This is not the same as the UI language. Place names carry Sinhala and
  /// Tamil spellings that are shown alongside English, and the almanac uses
  /// both scripts, so an English interface still has to draw them. Without a
  /// fallback the device decides, and on many Sri Lankan phones that means
  /// empty boxes.
  static const List<String> _fallbacks = [sinhalaFont, tamilFont];

  /// The font a locale reads best in, or null to keep the Material default.
  ///
  /// English stays on the default face: Noto Sans Sinhala covers Latin, but
  /// its Latin is not what an English reader expects, and the fallback list
  /// picks it up for any Sinhala that appears anyway.
  static String? fontFor(AppLocale locale) => switch (locale) {
    AppLocale.si => sinhalaFont,
    AppLocale.ta => tamilFont,
    AppLocale.en => null,
  };

  static ThemeData light(AppLocale locale) =>
      _base(Brightness.light, AppColors.primary, locale);

  static ThemeData dark(AppLocale locale) =>
      _base(Brightness.dark, AppColors.primaryDark, locale);

  static ThemeData _base(
    Brightness brightness,
    Color seed,
    AppLocale locale,
  ) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      fontFamily: fontFor(locale),
      fontFamilyFallback: _fallbacks,
    );

    return base.copyWith(
      textTheme: _withScriptMetrics(base.textTheme),
      primaryTextTheme: _withScriptMetrics(base.primaryTextTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        elevation: 0,
      ),
    );
  }

  /// Applies the taller line height, and the fallbacks again.
  ///
  /// `ThemeData.fontFamilyFallback` does not reach every style once a
  /// TextTheme is copied, so it is restated here. Missing it shows as boxes
  /// only in the styles that were copied, which is a maddening way to find out.
  static TextTheme _withScriptMetrics(TextTheme theme) {
    TextStyle? body(TextStyle? s) =>
        s?.copyWith(height: _scriptLineHeight, fontFamilyFallback: _fallbacks);
    TextStyle? other(TextStyle? s) =>
        s?.copyWith(fontFamilyFallback: _fallbacks);

    return theme.copyWith(
      bodyLarge: body(theme.bodyLarge),
      bodyMedium: body(theme.bodyMedium),
      bodySmall: body(theme.bodySmall),
      titleLarge: other(theme.titleLarge),
      titleMedium: other(theme.titleMedium),
      titleSmall: other(theme.titleSmall),
      labelLarge: other(theme.labelLarge),
      labelMedium: other(theme.labelMedium),
      labelSmall: other(theme.labelSmall),
      headlineLarge: other(theme.headlineLarge),
      headlineMedium: other(theme.headlineMedium),
      headlineSmall: other(theme.headlineSmall),
      displayLarge: other(theme.displayLarge),
      displayMedium: other(theme.displayMedium),
      displaySmall: other(theme.displaySmall),
    );
  }
}
