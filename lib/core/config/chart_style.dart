/// Which rāśi chart layout to draw.
///
/// Not cosmetic. The two styles encode the chart differently — South Indian
/// fixes the signs and marks the lagna, North Indian fixes the houses and
/// rotates the signs — and readers of one generally cannot read the other at a
/// glance. Sri Lankan and South Indian users expect South Indian, which is why
/// it is the default; North Indian matters for the North Indian market and for
/// users who learned from Hindi-language material.
enum ChartStyle {
  southIndian('South Indian'),
  northIndian('North Indian');

  const ChartStyle(this.label);

  final String label;

  static ChartStyle fromName(String? name) => ChartStyle.values.firstWhere(
    (s) => s.name == name,
    orElse: () => ChartStyle.southIndian,
  );
}
