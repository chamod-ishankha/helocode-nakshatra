import 'models.dart';

/// How deep a period sits in the daśā tree.
enum DashaLevel {
  /// The 120-year cycle of nine major periods.
  maha,

  /// Sub-periods within a mahādaśā, in the same cyclic order.
  antara,

  /// Sub-sub-periods. Gated to Pro by the paywall, not by this engine.
  pratyantara;

  DashaLevel? get next => switch (this) {
    DashaLevel.maha => DashaLevel.antara,
    DashaLevel.antara => DashaLevel.pratyantara,
    DashaLevel.pratyantara => null,
  };
}

/// One planetary period.
///
/// [start] is inclusive and [end] exclusive, so consecutive periods tile the
/// timeline with no gap and no instant belonging to two periods.
class DashaPeriod {
  const DashaPeriod({
    required this.lord,
    required this.level,
    required this.start,
    required this.end,
    this.children = const [],
  });

  final Graha lord;
  final DashaLevel level;

  /// UTC. Daśā boundaries are instants, and rendering them in a local zone is
  /// the presentation layer's job.
  final DateTime start;
  final DateTime end;

  final List<DashaPeriod> children;

  Duration get duration => end.difference(start);

  bool contains(DateTime instant) {
    final utc = instant.toUtc();
    return !utc.isBefore(start) && utc.isBefore(end);
  }

  /// The child running at [instant], or null.
  DashaPeriod? childAt(DateTime instant) {
    for (final child in children) {
      if (child.contains(instant)) return child;
    }
    return null;
  }

  @override
  String toString() =>
      '${lord.en} ${level.name} ${start.toIso8601String()} → '
      '${end.toIso8601String()}';
}

/// The daśās running at one instant, outermost first.
class DashaSnapshot {
  const DashaSnapshot({required this.maha, this.antara, this.pratyantara});

  final DashaPeriod maha;
  final DashaPeriod? antara;
  final DashaPeriod? pratyantara;

  /// "Venus / Saturn / Mercury" — the conventional way a period is named.
  String get label => [
    maha.lord.en,
    if (antara != null) antara!.lord.en,
    if (pratyantara != null) pratyantara!.lord.en,
  ].join(' / ');
}

/// Vimśottarī daśā — the 120-year planetary period cycle (KAN-18).
///
/// ## How it is seeded
///
/// The Moon's position at birth decides everything. Its nakṣatra fixes which
/// graha's period is running, and how far the Moon has travelled through that
/// nakṣatra fixes how much of the period is already spent. A Moon halfway
/// through Bharaṇī is halfway through a Venus mahādaśā, so ten of Venus's
/// twenty years remain.
///
/// That makes the whole timeline extremely sensitive to birth time: the Moon
/// moves about 13° a day, so a nakṣatra lasts roughly a day and an hour's
/// error shifts every boundary by months. This is why an unknown birth time
/// is flagged so prominently elsewhere in the app.
///
/// ## The year
///
/// A "year" here is [daysPerYear] = 365.25 days. This is a genuine fork in
/// practice: some traditions use a 360-day sāvana year, others the Gregorian
/// 365.2425. The Julian 365.25 is what the widely used software agrees on
/// (Jagannātha Horā, Parāśara's Light), and matching printed Sri Lankan
/// almanacs matters more here than picking a favourite. Changing it moves
/// every boundary, so it is a deliberate constant rather than an option.
abstract final class Vimshottari {
  /// The nine lords in cycle order, with their share of the 120 years.
  ///
  /// Order matters as much as the durations: sub-periods run in this same
  /// sequence, starting from their parent's lord.
  static const List<(Graha, int)> cycle = [
    (Graha.ketu, 7),
    (Graha.venus, 20),
    (Graha.sun, 6),
    (Graha.moon, 10),
    (Graha.mars, 7),
    (Graha.rahu, 18),
    (Graha.jupiter, 16),
    (Graha.saturn, 19),
    (Graha.mercury, 17),
  ];

  static const int totalYears = 120;

  static const double daysPerYear = 365.25;

  static List<Graha> get lords => [for (final (g, _) in cycle) g];

  /// Years allotted to [lord] in a full cycle.
  static int yearsOf(Graha lord) =>
      cycle.firstWhere((e) => e.$1 == lord).$2;

  /// The graha ruling [nakshatra].
  ///
  /// The 27 nakṣatras cycle through the nine lords three times, starting with
  /// Ketu at Aśvinī — so the lord is simply the index modulo nine.
  static Graha lordOf(Nakshatra nakshatra) =>
      lords[nakshatra.index % lords.length];

  /// The fraction of the birth nakṣatra already elapsed, 0 to 1.
  static double elapsedFraction(double moonLongitude) {
    final within = moonLongitude % Nakshatra.span;
    return within / Nakshatra.span;
  }

  /// Builds the daśā tree for a chart.
  ///
  /// [depth] is how many levels to generate: 1 mahādaśā only, 2 with
  /// antardaśā, 3 with pratyantardaśā.
  ///
  /// The first mahādaśā began before birth. Its antardaśās are generated over
  /// its *full* span and only then clipped, because computing them over the
  /// remaining balance instead is a real and easy mistake — it would put every
  /// sub-period boundary in the wrong place for the whole first period.
  static List<DashaPeriod> forChart(
    BirthChart chart, {
    int depth = 3,
  }) {
    assert(depth >= 1 && depth <= 3, 'depth must be 1..3');

    final birth = utcFromJulianDay(chart.julianDayUt);
    final moon = chart[Graha.moon].longitude;
    final firstLord = lordOf(Nakshatra.fromLongitude(moon));
    final elapsed = elapsedFraction(moon);

    // Wind back to where the running mahādaśā actually started.
    final cycleStart = _shift(birth, -yearsOf(firstLord) * elapsed);

    final periods = _build(
      from: cycleStart,
      startingWith: firstLord,
      spanYears: totalYears.toDouble(),
      level: DashaLevel.maha,
      depth: depth,
    );

    return _clip(periods, birth);
  }

  /// How much of the first mahādaśā is left at birth.
  static Duration balanceAtBirth(BirthChart chart) {
    final moon = chart[Graha.moon].longitude;
    final lord = lordOf(Nakshatra.fromLongitude(moon));
    final remaining = yearsOf(lord) * (1 - elapsedFraction(moon));
    return Duration(
      microseconds:
          (remaining * daysPerYear * Duration.microsecondsPerDay).round(),
    );
  }

  /// The periods running at [instant], or null if it falls outside the cycle.
  static DashaSnapshot? at(List<DashaPeriod> timeline, DateTime instant) {
    for (final maha in timeline) {
      if (!maha.contains(instant)) continue;
      final antara = maha.childAt(instant);
      return DashaSnapshot(
        maha: maha,
        antara: antara,
        pratyantara: antara?.childAt(instant),
      );
    }
    return null;
  }

  /// One level of the tree, recursing while [depth] allows.
  static List<DashaPeriod> _build({
    required DateTime from,
    required Graha startingWith,
    required double spanYears,
    required DashaLevel level,
    required int depth,
  }) {
    final all = lords;
    final offset = all.indexOf(startingWith);
    final out = <DashaPeriod>[];

    // Boundaries are measured from `from` rather than accumulated period by
    // period, so rounding cannot drift across a 120-year span.
    var elapsedYears = 0.0;

    for (var i = 0; i < all.length; i++) {
      final lord = all[(offset + i) % all.length];
      // A sub-period takes the same share of its parent that its lord takes
      // of the whole cycle.
      final lengthYears = spanYears * yearsOf(lord) / totalYears;

      final start = _shift(from, elapsedYears);
      final end = _shift(from, elapsedYears + lengthYears);

      final nextLevel = level.next;
      out.add(
        DashaPeriod(
          lord: lord,
          level: level,
          start: start,
          end: end,
          children: (depth > 1 && nextLevel != null)
              ? _build(
                  from: start,
                  startingWith: lord,
                  spanYears: lengthYears,
                  level: nextLevel,
                  depth: depth - 1,
                )
              : const [],
        ),
      );

      elapsedYears += lengthYears;
    }

    return out;
  }

  /// Drops periods finished before [from] and truncates the one containing it.
  ///
  /// A period that ended before the chart's owner was born is not something
  /// they lived through, and showing it would be nonsense.
  static List<DashaPeriod> _clip(List<DashaPeriod> periods, DateTime from) {
    final out = <DashaPeriod>[];
    for (final p in periods) {
      if (!p.end.isAfter(from)) continue;
      out.add(
        DashaPeriod(
          lord: p.lord,
          level: p.level,
          start: p.start.isBefore(from) ? from : p.start,
          end: p.end,
          children: _clip(p.children, from),
        ),
      );
    }
    return out;
  }

  static DateTime _shift(DateTime from, double years) => from.add(
    Duration(
      microseconds:
          (years * daysPerYear * Duration.microsecondsPerDay).round(),
    ),
  );
}

/// The instant a Julian day (UT) refers to.
///
/// Inverse of `Ephemeris.julianDayFromLocal`. Daśā boundaries are derived from
/// the chart's own Julian day rather than from the profile's wall clock, so
/// the timeline cannot disagree with the chart it came from.
DateTime utcFromJulianDay(double julianDayUt) {
  // 2440587.5 is the Julian day of the Unix epoch.
  const unixEpochJd = 2440587.5;
  final ms = (julianDayUt - unixEpochJd) * Duration.millisecondsPerDay;
  return DateTime.fromMillisecondsSinceEpoch(ms.round(), isUtc: true);
}
