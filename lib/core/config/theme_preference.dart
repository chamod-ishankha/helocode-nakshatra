import 'package:flutter/material.dart';

/// Light, dark, or whatever the phone is set to.
///
/// Defaults to following the system. Overriding matters more here than in most
/// apps: a lot of this audience checks nekath outdoors in strong sunlight,
/// where a dark theme is unreadable regardless of what the phone prefers.
enum ThemePreference {
  system,
  light,
  dark;

  ThemeMode get mode => switch (this) {
    ThemePreference.system => ThemeMode.system,
    ThemePreference.light => ThemeMode.light,
    ThemePreference.dark => ThemeMode.dark,
  };

  static ThemePreference fromName(String? name) =>
      ThemePreference.values.firstWhere(
        (p) => p.name == name,
        orElse: () => ThemePreference.system,
      );
}
