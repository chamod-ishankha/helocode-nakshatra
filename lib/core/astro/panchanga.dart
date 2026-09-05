import 'package:sweph/sweph.dart';
import 'package:timezone/timezone.dart' as tz;

import 'ephemeris.dart';
import 'models.dart';
import 'panchanga_models.dart';

/// Panchanga — the five limbs of the almanac — and the day's solar times.
///
/// ## Sunrise convention
///
/// Uses the Hindu rising convention: disc centre, no refraction. This is what
/// Indian and Sri Lankan almanacs use, and it differs from ordinary civil
/// sunrise (upper limb, with refraction) by two to four minutes.
///
/// That gap matters more than it looks. Rāhu kālaya is one eighth of the
/// daylight span, so any error in sunrise propagates into every inauspicious
/// window — and those are the timings people actually plan around.
///
/// ## Day boundaries
///
/// A panchanga day runs **sunrise to sunrise**, not midnight to midnight. The
/// vāra between midnight and sunrise still belongs to the previous day. This is
/// the most common bug in almanac code and is invisible for most of the day.
abstract final class Panchangam {
  /// Sun and Moon only; tropical is deliberate.
  ///
  /// Tithi, yoga and karana are defined by the *difference* or *sum* of solar
  /// and lunar longitude, and an ayanāṃśa applied to both either cancels out or
  /// shifts the boundary identically. Nakṣatra genuinely needs sidereal and
  /// uses its own flag set below.
  static const SwephFlag _flags = SwephFlag(4 | 256); // MOSEPH | SPEED
  static const SwephFlag _sidereal = SwephFlag(4 | 256 | (64 * 1024));

  // SE_CALC_RISE/SET or'ed with the three SE_BIT_HINDU_RISING bits.
  static const RiseSetTransitFlag _hinduRise = RiseSetTransitFlag(
    1 | 128 | 256 | 512,
  );
  static const RiseSetTransitFlag _hinduSet = RiseSetTransitFlag(
    2 | 128 | 256 | 512,
  );
  static const RiseSetTransitFlag _plainRise = RiseSetTransitFlag(1);
  static const RiseSetTransitFlag _plainSet = RiseSetTransitFlag(2);

  static bool get isReady => Ephemeris.isReady;

  /// Computes the almanac for the calendar date of [date] at a location.
  static Panchanga forDate({
    required DateTime date,
    required String zoneName,
    required double latitude,
    required double longitude,
  }) {
    final location = tz.getLocation(zoneName);
    final geo = GeoPosition(longitude, latitude);

    // Search from local midnight so the first rising found belongs to this
    // calendar date.
    final midnight = tz.TZDateTime(location, date.year, date.month, date.day);
    final jdMidnight = _toJulianDay(midnight.toUtc());

    final sunriseJd = Sweph.swe_rise_trans(
      jdMidnight,
      HeavenlyBody.SE_SUN,
      _flags,
      _hinduRise,
      geo,
      0,
      0,
    )!;
    final sunsetJd = Sweph.swe_rise_trans(
      sunriseJd,
      HeavenlyBody.SE_SUN,
      _flags,
      _hinduSet,
      geo,
      0,
      0,
    )!;
    final moonriseJd = Sweph.swe_rise_trans(
      jdMidnight,
      HeavenlyBody.SE_MOON,
      _flags,
      _plainRise,
      geo,
      0,
      0,
    );
    final moonsetJd = Sweph.swe_rise_trans(
      jdMidnight,
      HeavenlyBody.SE_MOON,
      _flags,
      _plainSet,
      geo,
      0,
      0,
    );

    final sunrise = _fromJulianDay(sunriseJd, location);

    // Every element is evaluated at sunrise, because that is when the
    // panchanga day begins and what an almanac prints.
    final elong = _elongation(sunriseJd);
    final tithiIndex = (elong / 12).floor();

    return Panchanga(
      date: DateTime(date.year, date.month, date.day),
      vara: Vara.values[sunrise.weekday % 7],
      paksha: tithiIndex < 15 ? Paksha.shukla : Paksha.krishna,
      tithi: PanchangaElement(
        value: Tithi.values[tithiIndex % 15],
        endsAt: _nextBoundary(sunriseJd, 12, _elongation, location),
      ),
      karana: PanchangaElement(
        value: _karanaForIndex((elong / 6).floor()),
        endsAt: _nextBoundary(sunriseJd, 6, _elongation, location),
      ),
      yoga: PanchangaElement(
        value: Yoga.values[(_yogaSum(sunriseJd) / (360 / 27)).floor() % 27],
        endsAt: _nextBoundary(sunriseJd, 360 / 27, _yogaSum, location),
      ),
      nakshatra: PanchangaElement(
        value: Nakshatra.fromLongitude(_moonSidereal(sunriseJd)).en,
        endsAt: _nextBoundary(
          sunriseJd,
          Nakshatra.span,
          _moonSidereal,
          location,
        ),
      ),
      sunrise: sunrise,
      sunset: _fromJulianDay(sunsetJd, location),
      moonrise: moonriseJd == null
          ? null
          : _fromJulianDay(moonriseJd, location),
      moonset: moonsetJd == null ? null : _fromJulianDay(moonsetJd, location),
    );
  }

  /// Moon's elongation from the Sun, 0-360. Drives tithi and karana.
  static double _elongation(double jd) {
    final sun = Sweph.swe_calc_ut(jd, HeavenlyBody.SE_SUN, _flags).longitude;
    final moon = Sweph.swe_calc_ut(jd, HeavenlyBody.SE_MOON, _flags).longitude;
    return (moon - sun) % 360;
  }

  /// Combined solar and lunar longitude. Drives yoga.
  static double _yogaSum(double jd) {
    final sun = Sweph.swe_calc_ut(jd, HeavenlyBody.SE_SUN, _flags).longitude;
    final moon = Sweph.swe_calc_ut(jd, HeavenlyBody.SE_MOON, _flags).longitude;
    return (sun + moon) % 360;
  }

  static double _moonSidereal(double jd) =>
      Sweph.swe_calc_ut(jd, HeavenlyBody.SE_MOON, _sidereal).longitude % 360;

  /// The karana name for half-tithi [index] (0-59).
  ///
  /// The seven movable karana repeat eight times from the second half-tithi
  /// onwards, and four fixed karana bookend the month. That irregularity is why
  /// this cannot be a plain modulo.
  static Karana _karanaForIndex(int index) {
    if (index <= 0) return Karana.kimstughna;
    if (index >= 57) {
      return [Karana.shakuni, Karana.chatushpada, Karana.naga][index - 57];
    }
    return Karana.values[(index - 1) % 7];
  }

  /// When [fn] next crosses a multiple of [step], searched by bisection.
  ///
  /// Not a closed form: the Moon's apparent speed varies by roughly 15% over a
  /// month, so extrapolating at a constant rate would be minutes out, and these
  /// end times are printed to the minute.
  static DateTime? _nextBoundary(
    double jd,
    double step,
    double Function(double) fn,
    tz.Location location,
  ) {
    final target = (((fn(jd) / step).floor() + 1) * step) % 360;

    /// Signed distance to the target, unwrapped across the 360 seam.
    double delta(double j) {
      final d = (fn(j) - target) % 360;
      return d > 180 ? d - 360 : d;
    }

    var lo = jd;
    var hi = jd + 2; // nothing here lasts longer than two days

    if (delta(lo) > 0 || delta(hi) < 0) return null;

    for (var i = 0; i < 60; i++) {
      final mid = (lo + hi) / 2;
      if (delta(mid) < 0) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return _fromJulianDay((lo + hi) / 2, location);
  }

  static double _toJulianDay(DateTime utc) => Sweph.swe_julday(
    utc.year,
    utc.month,
    utc.day,
    utc.hour + utc.minute / 60 + utc.second / 3600,
    CalendarType.SE_GREG_CAL,
  );

  static DateTime _fromJulianDay(double jd, tz.Location location) {
    // Julian day 2440587.5 is the Unix epoch.
    final ms = ((jd - 2440587.5) * 86400000).round();
    return tz.TZDateTime.fromMillisecondsSinceEpoch(location, ms);
  }
}
