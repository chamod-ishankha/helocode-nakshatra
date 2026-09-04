import 'package:flutter/material.dart';

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

  static ThemeData light() => _base(Brightness.light, AppColors.primary);
  static ThemeData dark() => _base(Brightness.dark, AppColors.primaryDark);

  static ThemeData _base(Brightness brightness, Color seed) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    final base = ThemeData(colorScheme: scheme, useMaterial3: true);

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        bodyLarge: base.textTheme.bodyLarge?.copyWith(
          height: _scriptLineHeight,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          height: _scriptLineHeight,
        ),
        bodySmall: base.textTheme.bodySmall?.copyWith(
          height: _scriptLineHeight,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        elevation: 0,
      ),
    );
  }
}
