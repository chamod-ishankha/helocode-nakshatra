import 'models.dart';

/// Divisional (varga) charts — currently just the navāṃśa (KAN-53).
///
/// A varga takes each sign, cuts it into equal parts, and maps each part onto
/// a whole sign of its own. The result is read as a chart in its own right.
abstract final class Varga {
  /// Width of one navāṃśa: a sign divided into nine.
  static const double navamsaSpan = 30 / 9;

  /// The sign a longitude falls into in the navāṃśa.
  ///
  /// The classical rule is stated per sign type — movable signs count from
  /// themselves, fixed signs from the ninth, dual signs from the fifth — but
  /// all three collapse into counting navāṃśas continuously from 0° Aries,
  /// which is what this does. `navamsaSignFor` in the tests checks the
  /// collapsed form against the classical one for all twelve signs, because
  /// the equivalence is the sort of thing that is easy to assert and hard to
  /// believe.
  static Rasi navamsaSign(double longitude) {
    final norm = longitude % 360;
    return Rasi.values[(norm ~/ navamsaSpan).toInt() % 12];
  }

  /// The longitude a body occupies in the navāṃśa chart.
  ///
  /// The 3°20' the body sits in is stretched across the whole 30° of its
  /// navāṃśa sign, which is what lets a divisional chart be drawn and read
  /// with the same machinery as the rāśi chart.
  static double navamsaLongitude(double longitude) {
    final norm = longitude % 360;
    final within = norm % navamsaSpan;
    return navamsaSign(norm).index * 30 + within * 9;
  }

  /// Re-projects a whole chart into the navāṃśa.
  ///
  /// Returns a [BirthChart] so every existing renderer, table and detail sheet
  /// works on it unchanged — a D9 is a chart, not a special case.
  ///
  /// Speed and latitude are carried over untouched: they belong to the body,
  /// not to the division, and a "retrograde in the navāṃśa" reading is the
  /// same retrograde.
  static BirthChart navamsa(BirthChart chart) {
    final lagna = navamsaLongitude(chart.ascendant);
    final lagnaSign = Rasi.fromLongitude(lagna).index;

    return BirthChart(
      julianDayUt: chart.julianDayUt,
      ascendant: lagna,
      midheaven: navamsaLongitude(chart.midheaven),
      ayanamsa: chart.ayanamsa,
      positions: {
        for (final entry in chart.positions.entries)
          entry.key: () {
            final projected = navamsaLongitude(entry.value.longitude);
            return GrahaPosition(
              graha: entry.value.graha,
              longitude: projected,
              latitude: entry.value.latitude,
              speed: entry.value.speed,
              // Whole-sign houses again, counted from the navāṃśa lagna.
              house: ((Rasi.fromLongitude(projected).index - lagnaSign) % 12) +
                  1,
            );
          }(),
      },
    );
  }
}
