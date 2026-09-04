import 'package:sweph/sweph.dart';

/// The nine grahas of Vedic astrology.
///
/// Rahu and Ketu are the lunar nodes, not physical bodies: they sit exactly
/// opposite one another, so only Rahu is computed and Ketu is derived.
enum Graha {
  sun('Sun', 'සූර්ය', 'சூரியன்'),
  moon('Moon', 'චන්ද්‍ර', 'சந்திரன்'),
  mars('Mars', 'කුජ', 'செவ்வாய்'),
  mercury('Mercury', 'බුධ', 'புதன்'),
  jupiter('Jupiter', 'ගුරු', 'குரு'),
  venus('Venus', 'ශුක්‍ර', 'சுக்கிரன்'),
  saturn('Saturn', 'ශනි', 'சனி'),
  rahu('Rahu', 'රාහු', 'ராகு'),
  ketu('Ketu', 'කේතු', 'கேது');

  const Graha(this.en, this.si, this.ta);

  final String en;
  final String si;
  final String ta;

  /// The Swiss Ephemeris body for this graha, or null for Ketu, which is
  /// derived from Rahu rather than computed.
  HeavenlyBody? get body => switch (this) {
    Graha.sun => HeavenlyBody.SE_SUN,
    Graha.moon => HeavenlyBody.SE_MOON,
    Graha.mars => HeavenlyBody.SE_MARS,
    Graha.mercury => HeavenlyBody.SE_MERCURY,
    Graha.jupiter => HeavenlyBody.SE_JUPITER,
    Graha.venus => HeavenlyBody.SE_VENUS,
    Graha.saturn => HeavenlyBody.SE_SATURN,
    // Vedic practice uses the mean node, not the true (oscillating) node.
    Graha.rahu => HeavenlyBody.SE_MEAN_NODE,
    Graha.ketu => null,
  };
}

/// The twelve rāśi (zodiac signs), in sidereal order from Aries.
enum Rasi {
  mesha('Aries', 'මේෂ', 'மேஷம்'),
  vrishabha('Taurus', 'වෘෂභ', 'ரிஷபம்'),
  mithuna('Gemini', 'මිථුන', 'மிதுனம்'),
  karka('Cancer', 'කටක', 'கடகம்'),
  simha('Leo', 'සිංහ', 'சிம்மம்'),
  kanya('Virgo', 'කන්‍යා', 'கன்னி'),
  tula('Libra', 'තුලා', 'துலாம்'),
  vrischika('Scorpio', 'වෘශ්චික', 'விருச்சிகம்'),
  dhanu('Sagittarius', 'ධනු', 'தனுசு'),
  makara('Capricorn', 'මකර', 'மகரம்'),
  kumbha('Aquarius', 'කුම්භ', 'கும்பம்'),
  meena('Pisces', 'මීන', 'மீனம்');

  const Rasi(this.en, this.si, this.ta);

  final String en;
  final String si;
  final String ta;

  /// The rāśi containing [longitude] (sidereal degrees, 0-360).
  static Rasi fromLongitude(double longitude) =>
      Rasi.values[(_norm(longitude) ~/ 30) % 12];
}

/// The 27 nakṣatra. Each spans 13°20' of the sidereal zodiac.
enum Nakshatra {
  ashwini('Ashwini'),
  bharani('Bharani'),
  krittika('Krittika'),
  rohini('Rohini'),
  mrigashira('Mrigashira'),
  ardra('Ardra'),
  punarvasu('Punarvasu'),
  pushya('Pushya'),
  ashlesha('Ashlesha'),
  magha('Magha'),
  purvaPhalguni('Purva Phalguni'),
  uttaraPhalguni('Uttara Phalguni'),
  hasta('Hasta'),
  chitra('Chitra'),
  swati('Swati'),
  vishakha('Vishakha'),
  anuradha('Anuradha'),
  jyeshtha('Jyeshtha'),
  mula('Mula'),
  purvaAshadha('Purva Ashadha'),
  uttaraAshadha('Uttara Ashadha'),
  shravana('Shravana'),
  dhanishta('Dhanishta'),
  shatabhisha('Shatabhisha'),
  purvaBhadrapada('Purva Bhadrapada'),
  uttaraBhadrapada('Uttara Bhadrapada'),
  revati('Revati');

  const Nakshatra(this.en);
  final String en;

  /// Span of one nakṣatra in degrees: 360 / 27.
  static const double span = 360 / 27;

  static Nakshatra fromLongitude(double longitude) =>
      Nakshatra.values[(_norm(longitude) ~/ span).toInt() % 27];

  /// Pada (quarter) 1-4 within the nakṣatra containing [longitude].
  static int padaFromLongitude(double longitude) =>
      ((_norm(longitude) % span) ~/ (span / 4)).toInt() + 1;
}

/// A single graha's computed position.
class GrahaPosition {
  const GrahaPosition({
    required this.graha,
    required this.longitude,
    required this.latitude,
    required this.speed,
    required this.house,
  });

  final Graha graha;

  /// Sidereal ecliptic longitude in degrees, 0-360.
  final double longitude;

  final double latitude;

  /// Degrees per day. Negative means retrograde.
  final double speed;

  /// Whole-sign house, 1-12.
  final int house;

  Rasi get rasi => Rasi.fromLongitude(longitude);
  Nakshatra get nakshatra => Nakshatra.fromLongitude(longitude);
  int get pada => Nakshatra.padaFromLongitude(longitude);

  /// Rahu and Ketu are always shown retrograde by convention; their computed
  /// mean motion is negative anyway.
  bool get isRetrograde => speed < 0;

  /// Position within its rāśi, 0-30 degrees.
  double get degreeInRasi => _norm(longitude) % 30;

  @override
  String toString() =>
      '${graha.en} ${degreeInRasi.toStringAsFixed(2)}° ${rasi.en}'
      '${isRetrograde ? ' (R)' : ''} H$house';
}

/// A computed birth chart.
class BirthChart {
  const BirthChart({
    required this.julianDayUt,
    required this.ascendant,
    required this.midheaven,
    required this.ayanamsa,
    required this.positions,
  });

  /// Julian day in Universal Time, the value actually fed to the ephemeris.
  final double julianDayUt;

  /// Sidereal longitude of the ascendant (lagna) in degrees.
  final double ascendant;

  final double midheaven;

  /// Ayanāṃśa applied, in degrees — the tropical/sidereal offset.
  final double ayanamsa;

  final Map<Graha, GrahaPosition> positions;

  Rasi get lagnaRasi => Rasi.fromLongitude(ascendant);
  Nakshatra get lagnaNakshatra => Nakshatra.fromLongitude(ascendant);

  /// The Moon's nakṣatra, which seeds the Vimśottarī daśā sequence (KAN-18)
  /// and drives most compatibility matching.
  Nakshatra get birthNakshatra => positions[Graha.moon]!.nakshatra;

  GrahaPosition operator [](Graha g) => positions[g]!;
}

double _norm(double degrees) {
  final d = degrees % 360;
  return d < 0 ? d + 360 : d;
}
