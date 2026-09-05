import 'panchanga_models.dart';

/// Inauspicious periods of the day — rāhu kālaya, yamaganda and gulika.
///
/// ## Why these are computed, never tabulated
///
/// Each is one eighth of the **daylight span**, sunrise to sunset, with the
/// segment chosen by weekday. Daylight length changes through the year, so the
/// clock times move: in Colombo rāhu kālaya drifts by around twenty minutes
/// between June and December.
///
/// Hardcoding "Monday 07:30-09:00" — which many apps and websites do — is
/// therefore wrong for most of the year. This is the single most-checked
/// feature in the app, so it is derived from real sunrise and sunset every time.
///
/// ## Segment mappings
///
/// Segments are numbered 1-8 from sunrise. The weekday assignments below are
/// the standard ones used across Sri Lanka and India.
abstract final class Nekath {
  /// Rāhu kālaya: the segment to avoid, by weekday.
  ///
  /// The traditional mnemonic runs Mother(2) Saw(3) Father(4) Wearing(5)
  /// The(6) Turban(7) Suddenly(8) — Monday through Sunday.
  static const Map<Vara, int> _rahuSegment = {
    Vara.ravi: 8,
    Vara.soma: 2,
    Vara.mangala: 7,
    Vara.budha: 5,
    Vara.guru: 6,
    Vara.shukra: 4,
    Vara.shani: 3,
  };

  static const Map<Vara, int> _yamagandaSegment = {
    Vara.ravi: 5,
    Vara.soma: 4,
    Vara.mangala: 3,
    Vara.budha: 2,
    Vara.guru: 1,
    Vara.shukra: 7,
    Vara.shani: 6,
  };

  static const Map<Vara, int> _gulikaSegment = {
    Vara.ravi: 7,
    Vara.soma: 6,
    Vara.mangala: 5,
    Vara.budha: 4,
    Vara.guru: 3,
    Vara.shukra: 2,
    Vara.shani: 1,
  };

  /// The nth eighth of the daylight span, 1-based.
  static TimeWindow _segment({
    required DateTime sunrise,
    required DateTime sunset,
    required int n,
    required String name,
  }) {
    assert(n >= 1 && n <= 8, 'segment must be 1-8, got $n');
    final eighth = sunset.difference(sunrise) ~/ 8;
    return TimeWindow(
      start: sunrise.add(eighth * (n - 1)),
      end: sunrise.add(eighth * n),
      name: name,
    );
  }

  static TimeWindow rahuKalaya(Panchanga p) => _segment(
    sunrise: p.sunrise,
    sunset: p.sunset,
    n: _rahuSegment[p.vara]!,
    name: 'Rāhu kālaya',
  );

  static TimeWindow yamaganda(Panchanga p) => _segment(
    sunrise: p.sunrise,
    sunset: p.sunset,
    n: _yamagandaSegment[p.vara]!,
    name: 'Yamaganda',
  );

  static TimeWindow gulika(Panchanga p) => _segment(
    sunrise: p.sunrise,
    sunset: p.sunset,
    n: _gulikaSegment[p.vara]!,
    name: 'Gulika kālaya',
  );

  /// All inauspicious windows for the day, earliest first.
  static List<TimeWindow> inauspicious(Panchanga p) =>
      [rahuKalaya(p), yamaganda(p), gulika(p)]
        ..sort((a, b) => a.start.compareTo(b.start));

  /// Whether [moment] falls inside any inauspicious window.
  static bool isInauspicious(Panchanga p, DateTime moment) =>
      inauspicious(p).any((w) => w.contains(moment));

  /// The auspicious remainder of daylight — the windows not claimed by any of
  /// the three, merged and in order.
  ///
  /// This is the practical question a user is really asking: not "when is rāhu
  /// kālaya" but "when can I actually start".
  static List<TimeWindow> auspiciousWindows(Panchanga p) {
    final blocked = inauspicious(p);
    final free = <TimeWindow>[];
    var cursor = p.sunrise;

    for (final w in blocked) {
      if (w.start.isAfter(cursor)) {
        free.add(
          TimeWindow(
            start: cursor,
            end: w.start,
            name: 'Auspicious',
            auspicious: true,
          ),
        );
      }
      if (w.end.isAfter(cursor)) cursor = w.end;
    }
    if (p.sunset.isAfter(cursor)) {
      free.add(
        TimeWindow(
          start: cursor,
          end: p.sunset,
          name: 'Auspicious',
          auspicious: true,
        ),
      );
    }
    return free;
  }
}
