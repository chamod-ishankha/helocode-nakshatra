import 'package:sweph/sweph.dart';
import 'package:timezone/timezone.dart' as tz;

import 'calendar_models.dart';
import 'official_poya_days.dart';
import 'poya_rule.dart';

/// Poya days, the New Year ingress, and the fixed festivals.
///
/// ## What is computed and what is not
///
/// Poya days and the two solar ingresses are derived from the ephemeris and are
/// exact. Christmas is a fixed date.
///
/// **Deepavali and Eid are deliberately absent.** Deepavali's date depends on
/// which regional convention is followed, and Eid depends on local moon
/// sighting rather than calculation — the announced date can differ from any
/// computed one. Publishing a confidently wrong religious date is worse than
/// publishing none, so they are left to a maintained data source instead of
/// being guessed at. See [unsupportedFestivals].
abstract final class SriLankanCalendar {
  static const String _zone = 'Asia/Colombo';
  static const SwephFlag _tropical = SwephFlag(4 | 256); // MOSEPH | SPEED
  static const SwephFlag _sidereal = SwephFlag(4 | 256 | (64 * 1024));

  /// Festivals this engine will not compute, and why.
  ///
  /// Surfaced so the UI can say so honestly rather than silently omitting them.
  static const Map<String, String> unsupportedFestivals = {
    'Deepavali':
        'The date follows regional convention and is announced each year.',
    'Eid al-Fitr': 'Determined by local moon sighting, not by calculation.',
    'Eid al-Adha': 'Determined by local moon sighting, not by calculation.',
    'Milad un-Nabi': 'Determined by local moon sighting, not by calculation.',
  };

  /// Every poya day in [year], in order.
  ///
  /// Each full moon gives one poya. Its day and name come from the published
  /// calendar where Sri Lanka has published one (`officialPoyaDays`), and
  /// otherwise from the rule in `poyaDayFor` and `poyaMonthFor` — see those
  /// for why the day is not simply the day of the full moon (KAN-96).
  ///
  /// [useOfficial] is for the device test that measures the rule on its own
  /// against the published dates; the app always leaves it on.
  static List<PoyaDay> poyaDaysIn(int year, {bool useOfficial = true}) =>
      List.unmodifiable(
        _poyaCache[(year, useOfficial)] ??= _computePoyaDays(
          year,
          useOfficial: useOfficial,
        ),
      );

  /// Each year worked out once. The answer cannot change while the app runs,
  /// and a year is some fifty ephemeris searches — about a third of a second
  /// on a mid-range phone — which Home would otherwise repeat every time the
  /// date arrows are tapped.
  static final Map<(int, bool), List<PoyaDay>> _poyaCache = {};

  static List<PoyaDay> _computePoyaDays(int year, {required bool useOfficial}) {
    final location = tz.getLocation(_zone);
    final result = <PoyaDay>[];

    // A synodic month is about 29.53 days, so stepping on from each full moon
    // cannot skip the next one. The window runs past both ends of the year
    // because a poya can fall on the day before its full moon.
    var cursor = _toJulianDay(tz.TZDateTime(location, year - 1, 12, 1).toUtc());
    final end = _toJulianDay(tz.TZDateTime(location, year + 1, 1, 15).toUtc());

    while (cursor < end) {
      final full = _nextElongation(cursor, 180);
      if (full == null) break;
      cursor = full + 1;

      // Pūrṇimā is the fifteenth tithi: elongation from 168° to 180°.
      final purnima = _nextElongation(full - 1.5, 168)!;
      final fullMoon = _fromJulianDay(full, location);

      var date = poyaDayFor(
        purnimaStart: _fromJulianDay(purnima, location),
        fullMoon: fullMoon,
        sunsetOn: (day) => _sunsetInColombo(day, location),
        noonOn: (day) =>
            tz.TZDateTime(location, day.year, day.month, day.day, 12),
      );

      // The new moons either side bound the lunar month the name comes from.
      final named = poyaMonthFor(
        sunSignAtNewMoonBefore: _sunSign(_nextElongation(full - 20, 0)!),
        sunSignAtNewMoonAfter: _sunSign(_nextElongation(full, 0)!),
      );
      var month = named.month;
      var isAdhi = named.isAdhi;

      if (useOfficial) {
        if (officialPoyaNear(date) case final published?) {
          date = published.date;
          month = published.month;
          isAdhi = published.isAdhi;
        }
      }

      if (date.year != year) continue;
      result.add(
        PoyaDay(date: date, month: month, isAdhi: isAdhi, fullMoon: fullMoon),
      );
    }

    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  /// The next poya day on or after [from].
  static PoyaDay? nextPoya(DateTime from) {
    for (final year in [from.year, from.year + 1]) {
      for (final p in poyaDaysIn(year)) {
        if (!p.date.isBefore(DateTime(from.year, from.month, from.day))) {
          return p;
        }
      }
    }
    return null;
  }

  /// Sinhala and Tamil New Year — the Sun's entry into sidereal Aries.
  ///
  /// This instant is the astronomical basis of the festival and is exact.
  ///
  /// The customary observance times — bathing, lighting the hearth, the first
  /// transaction, leaving for work — are **not** computed. They are published
  /// each year by the astrological committee and vary by convention, so they
  /// have to come from that year's announcement rather than from an ephemeris.
  static DateTime sinhalaNewYear(int year) => _solarIngress(year, 0);

  /// Thai Pongal — the Sun's entry into sidereal Capricorn (Makara Sankranti).
  static DateTime thaiPongal(int year) => _solarIngress(year, 270);

  /// Easter Sunday in the Gregorian calendar.
  ///
  /// The anonymous Gregorian algorithm — pure arithmetic, no ephemeris. That
  /// matters here more than it looks: every other date in this file needs
  /// Swiss Ephemeris and therefore a device, so none of them can be tested off
  /// a phone. This one can be, and is, because Good Friday is a public holiday
  /// and a wrong one is a wrong day off.
  static DateTime easterSunday(int year) {
    final a = year % 19;
    final b = year ~/ 100;
    final c = year % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final month = (h + l - 7 * m + 114) ~/ 31;
    final day = ((h + l - 7 * m + 114) % 31) + 1;
    return DateTime(year, month, day);
  }

  /// Good Friday — the Friday before Easter.
  static DateTime goodFriday(int year) =>
      easterSunday(year).subtract(const Duration(days: 2));

  /// Festivals whose date comes from the civil calendar rather than the sky.
  static List<Festival> fixedFestivals(int year) => [
    Festival(
      date: DateTime(year, 12, 25),
      name: 'Christmas Day',
      si: 'නත්තල්',
      ta: 'கிறிஸ்துமஸ்',
      kind: FestivalKind.fixed,
    ),
    Festival(
      date: DateTime(year, 2, 4),
      name: 'Independence Day',
      si: 'නිදහස් දිනය',
      ta: 'சுதந்திர தினம்',
      kind: FestivalKind.fixed,
    ),
    Festival(
      date: DateTime(year, 5, 1),
      name: 'May Day',
      si: 'මැයි දිනය',
      ta: 'மே தினம்',
      kind: FestivalKind.fixed,
    ),
    Festival(
      date: goodFriday(year),
      name: 'Good Friday',
      si: 'මහ සිකුරාදා',
      ta: 'புனித வெள்ளி',
      kind: FestivalKind.fixed,
    ),
  ];

  /// Everything this engine can state for [year], in date order.
  static List<Festival> festivalsIn(int year) {
    final newYear = sinhalaNewYear(year);
    final pongal = thaiPongal(year);

    return <Festival>[
      ...poyaDaysIn(year),
      Festival(
        date: DateTime(newYear.year, newYear.month, newYear.day),
        name: 'Sinhala and Tamil New Year',
        si: 'සිංහල හා දෙමළ අලුත් අවුරුද්ද',
        ta: 'சித்திரை புத்தாண்டு',
        kind: FestivalKind.solarIngress,
        exactMoment: newYear,
        note:
            'The Sun enters sidereal Aries. Customary observance times are '
            'announced each year and are not derived here.',
      ),
      // Sri Lanka gazettes the day before the ingress as a holiday of its
      // own, so the New Year is two days off work, not one.
      Festival(
        date: DateTime(
          newYear.year,
          newYear.month,
          newYear.day,
        ).subtract(const Duration(days: 1)),
        name: 'Day before Sinhala and Tamil New Year',
        si: 'සිංහල හා දෙමළ අලුත් අවුරුදු දිනට පෙර දින',
        ta: 'சித்திரைப் புத்தாண்டுக்கு முந்தைய நாள்',
        kind: FestivalKind.solarIngress,
      ),
      Festival(
        date: DateTime(pongal.year, pongal.month, pongal.day),
        name: 'Thai Pongal',
        si: 'තෛපොංගල්',
        ta: 'தைப்பொங்கல்',
        kind: FestivalKind.solarIngress,
        exactMoment: pongal,
        note: 'The Sun enters sidereal Capricorn.',
      ),
      ...fixedFestivals(year),
    ]..sort((a, b) => a.date.compareTo(b.date));
  }

  /// The next festival of any kind on or after [from].
  static Festival? nextFestival(DateTime from) {
    final today = DateTime(from.year, from.month, from.day);
    for (final year in [from.year, from.year + 1]) {
      for (final f in festivalsIn(year)) {
        if (!f.date.isBefore(today)) return f;
      }
    }
    return null;
  }

  /// When the Sun's sidereal longitude next reaches [degrees] during [year].
  static DateTime _solarIngress(int year, double degrees) {
    final location = tz.getLocation(_zone);

    // Sidereal Aries falls in mid-April and Capricorn in mid-January, so a
    // window either side of those is enough and keeps the search cheap.
    final startMonth = degrees == 0 ? 3 : 12;
    final startYear = degrees == 0 ? year : year - 1;
    var jd = _toJulianDay(
      tz.TZDateTime(location, startYear, startMonth, 20).toUtc(),
    );

    double sunAt(double j) =>
        Sweph.swe_calc_ut(j, HeavenlyBody.SE_SUN, _sidereal).longitude % 360;

    // Step a day at a time until the target is crossed, then bisect.
    var lo = jd;
    for (var i = 0; i < 60; i++) {
      final hi = lo + 1;
      final a = (sunAt(lo) - degrees) % 360;
      final b = (sunAt(hi) - degrees) % 360;
      final da = a > 180 ? a - 360 : a;
      final db = b > 180 ? b - 360 : b;
      if (da < 0 && db >= 0) {
        return _fromJulianDay(_bisect(lo, hi, degrees, sunAt), location);
      }
      lo = hi;
    }
    throw StateError('Solar ingress at $degrees not found for $year');
  }

  /// When the Moon's elongation from the Sun next reaches [degrees].
  static double? _nextElongation(double jd, double degrees) {
    double elong(double j) {
      final sun = Sweph.swe_calc_ut(
        j,
        HeavenlyBody.SE_SUN,
        _tropical,
      ).longitude;
      final moon = Sweph.swe_calc_ut(
        j,
        HeavenlyBody.SE_MOON,
        _tropical,
      ).longitude;
      return (moon - sun) % 360;
    }

    var lo = jd;
    for (var i = 0; i < 40; i++) {
      final hi = lo + 1;
      final a = (elong(lo) - degrees) % 360;
      final b = (elong(hi) - degrees) % 360;
      final da = a > 180 ? a - 360 : a;
      final db = b > 180 ? b - 360 : b;
      if (da < 0 && db >= 0) return _bisect(lo, hi, degrees, elong);
      lo = hi;
    }
    return null;
  }

  /// Sunset on [day] in Colombo, computed as the almanac computes it: the
  /// centre of the disc on the horizon, without refraction, as in Panchangam.
  /// Poya is national, so it is reckoned for the capital rather than for
  /// wherever the phone is.
  static DateTime _sunsetInColombo(DateTime day, tz.Location location) {
    final colombo = GeoPosition(79.8612, 6.9271);
    final midnight = _toJulianDay(
      tz.TZDateTime(location, day.year, day.month, day.day).toUtc(),
    );
    final rise = Sweph.swe_rise_trans(
      midnight,
      HeavenlyBody.SE_SUN,
      _tropical,
      const RiseSetTransitFlag(1 | 128 | 256 | 512),
      colombo,
      0,
      0,
    )!;
    final set = Sweph.swe_rise_trans(
      rise,
      HeavenlyBody.SE_SUN,
      _tropical,
      const RiseSetTransitFlag(2 | 128 | 256 | 512),
      colombo,
      0,
      0,
    )!;
    return _fromJulianDay(set, location);
  }

  /// The Sun's sidereal sign at [jd], 0 for Mēṣa to 11 for Mīna.
  static int _sunSign(double jd) =>
      (Sweph.swe_calc_ut(jd, HeavenlyBody.SE_SUN, _sidereal).longitude % 360) ~/
      30;

  static double _bisect(
    double lo,
    double hi,
    double target,
    double Function(double) fn,
  ) {
    double delta(double j) {
      final d = (fn(j) - target) % 360;
      return d > 180 ? d - 360 : d;
    }

    var a = lo;
    var b = hi;
    for (var i = 0; i < 60; i++) {
      final mid = (a + b) / 2;
      if (delta(mid) < 0) {
        a = mid;
      } else {
        b = mid;
      }
    }
    return (a + b) / 2;
  }

  static double _toJulianDay(DateTime utc) => Sweph.swe_julday(
    utc.year,
    utc.month,
    utc.day,
    utc.hour + utc.minute / 60 + utc.second / 3600,
    CalendarType.SE_GREG_CAL,
  );

  static DateTime _fromJulianDay(double jd, tz.Location location) {
    final ms = ((jd - 2440587.5) * 86400000).round();
    return tz.TZDateTime.fromMillisecondsSinceEpoch(location, ms);
  }
}
