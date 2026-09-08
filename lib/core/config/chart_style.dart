import '../../l10n/generated/app_localizations.dart';

/// Which rāśi chart layout to draw.
///
/// Not cosmetic. The two styles encode the chart differently — South Indian
/// fixes the signs and marks the lagna, North Indian fixes the houses and
/// rotates the signs — and readers of one generally cannot read the other at a
/// glance. Sri Lankan and South Indian users expect South Indian, which is why
/// it is the default; North Indian matters for the North Indian market and for
/// users who learned from Hindi-language material.
enum ChartStyle {
  southIndian,
  northIndian;

  static ChartStyle fromName(String? name) => ChartStyle.values.firstWhere(
    (s) => s.name == name,
    orElse: () => ChartStyle.southIndian,
  );
}

extension ChartStyleLabel on ChartStyle {
  /// The name to show a reader choosing between the two layouts.
  ///
  /// These were left in English on the argument that the styles are known by
  /// these names — but "South Indian" is a direction and a country, not
  /// notation, and every language the app ships in has its own words for both
  /// (KAN-58).
  String label(L10n l10n) => switch (this) {
    ChartStyle.southIndian => l10n.chartStyleSouthIndian,
    ChartStyle.northIndian => l10n.chartStyleNorthIndian,
  };
}
