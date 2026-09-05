import 'package:sweph/sweph.dart';
import 'package:timezone/timezone.dart' as tz;

import 'calendar_models.dart';

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
  };

  /// Every poya day in [year], in order.
  ///
  /// A poya is a full moon: the moment the Moon's elongation from the Sun
  /// reaches exactly 180°. The poya *day* is the Sri Lankan calendar day
  /// containing that instant.
  ///
  /// A Gregorian month occasionally holds two full moons. Sri Lankan practice
  /// inserts an intercalary "Adhi" poya, and the earlier of the pair takes that
  /// name.
  static List<PoyaDay> poyaDaysIn(int year) {
    final location = tz.getLocation(_zone);
    final moments = <DateTime>[];

    // A synodic month is about 29.53 days, so stepping 25 days at a time cannot
    // skip a full moon while keeping the number of searches low.
    DateTime cursor = tz.TZDateTime(location, year - 1, 12, 1).toUtc();
    final DateTime end = tz.TZDateTime(location, year + 1, 1, 15).toUtc();

    while (cursor.isBefore(end)) {
      final jd = _toJulianDay(cursor);
      final found = _nextElongation(jd, 180);
      if (found == null) break;

      final moment = _fromJulianDay(found, location);
      if (moment.year == year && (moments.isEmpty || moment != moments.last)) {
        moments.add(moment);
      }
      cursor = _fromJulianDay(found + 1, location).toUtc();
    }

    // Group by Gregorian month so a doubled month can be detected.
    final byMonth = <int, List<DateTime>>{};
    for (final m in moments) {
      byMonth.putIfAbsent(m.month, () => []).add(m);
    }

    final result = <PoyaDay>[];
    for (final entry in byMonth.entries) {
      final list = entry.value..sort();
      for (var i = 0; i < list.length; i++) {
        final moment = list[i];
        result.add(
          PoyaDay(
            date: DateTime(moment.year, moment.month, moment.day),
            month: PoyaMonth.forGregorianMonth(entry.key),
            // With two in one month the first is the intercalary one.
            isAdhi: list.length > 1 && i == 0,
            fullMoon: moment,
          ),
        );
      }
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

  /// Fixed-date festivals.
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
