import '../../features/onboarding/domain/birth_profile.dart';
import 'ephemeris.dart';
import 'models.dart';

/// When on a given day a given rāśi was rising — a birth time from the lagna.
///
/// Many readers who do not know their birth time do know their lagna: it is
/// the first thing written on a family horoscope. Each rāśi rises once a day,
/// for about one and a half to two and a half hours at Sri Lankan latitudes,
/// so the date, the place and the lagna together pin the birth to that
/// window. The middle of it gets the lagna and every house right, which
/// sunrise almost never does. It does not recover the true time: the Moon
/// moves about a degree across the window, which shifts the daśā balance by
/// up to a few months, and the navāṁśa changes every thirteen minutes or so.
/// Times of day, in the birth place's zone. [end] is exclusive.
typedef RisingWindow = ({Duration start, Duration end, Duration middle});

/// [LagnaWindow.forBirth]'s shape, so the choice of time can be tested
/// without the ephemeris.
typedef RisingWindowFinder =
    RisingWindow? Function({
      required DateTime date,
      required Place place,
      required Rasi rasi,
    });

abstract final class LagnaWindow {
  /// Coarse enough to be quick, fine enough that no rāśi — the shortest
  /// rises in well over an hour — can fall between two samples.
  static const _step = 4;

  static const _dayMinutes = 24 * 60;

  /// The window on the birth date in which [rasi] was rising, as times of
  /// day, or null if it never rose that day.
  ///
  /// [ascendantAt] gives the sidereal ascendant at a local time of day; it is
  /// a parameter so the search can be tested without the native ephemeris.
  ///
  /// A window that runs across midnight is cut at the date's edge: the date
  /// is the one thing the reader is sure of. The sidereal day is four minutes
  /// short of a solar one, so a rāśi rising around midnight can rise again
  /// just before the next; then the longer of the two pieces is taken, since
  /// the other is a matter of minutes.
  static RisingWindow? find({
    required Rasi rasi,
    required double Function(Duration timeOfDay) ascendantAt,
  }) {
    bool rising(int minute) =>
        Rasi.fromLongitude(ascendantAt(Duration(minutes: minute))) == rasi;

    final samples = [
      for (var m = 0; m < _dayMinutes; m += _step) m,
      _dayMinutes - 1,
    ];

    // Runs of samples inside the rāśi, each widened to the exact minute at
    // both ends by bisection.
    final runs = <(int, int)>[];
    int? first;
    for (var i = 0; i < samples.length; i++) {
      final inside = rising(samples[i]);
      if (inside && first == null) first = i;
      final closes = first != null && (!inside || i == samples.length - 1);
      if (!closes) continue;
      final from = first, last = inside ? i : i - 1;
      final start = from == 0
          ? 0
          : _edge(samples[from - 1], samples[from], rising);
      final end = last == samples.length - 1
          ? _dayMinutes
          : _edge(samples[last], samples[last + 1], (m) => !rising(m));
      runs.add((start, end));
      first = null;
    }
    if (runs.isEmpty) return null;

    final (start, end) = runs.reduce(
      (a, b) => (b.$2 - b.$1) > (a.$2 - a.$1) ? b : a,
    );
    return (
      start: Duration(minutes: start),
      end: Duration(minutes: end),
      middle: Duration(minutes: (start + end) ~/ 2),
    );
  }

  /// The first minute in (`outside`, `inside`] for which [test] holds, given
  /// that it fails at `outside` and holds at `inside`.
  static int _edge(int outside, int inside, bool Function(int) test) {
    var lo = outside, hi = inside;
    while (hi - lo > 1) {
      final mid = (lo + hi) ~/ 2;
      if (test(mid)) {
        hi = mid;
      } else {
        lo = mid;
      }
    }
    return hi;
  }

  /// [find] for a real place and date, with the ephemeris behind it.
  ///
  /// Null when the ephemeris cannot compute the day, as well as when the
  /// rāśi does not rise — either way the caller falls back to sunrise.
  static RisingWindow? forBirth({
    required DateTime date,
    required Place place,
    required Rasi rasi,
  }) {
    try {
      return find(
        rasi: rasi,
        ascendantAt: (t) => Ephemeris.computeChart(
          localWallClock: DateTime(
            date.year,
            date.month,
            date.day,
            t.inHours,
            t.inMinutes % 60,
          ),
          zoneName: place.timezone,
          latitude: place.latitude,
          longitude: place.longitude,
        ).valueOrNull!.ascendant,
      );
    } on Object {
      return null;
    }
  }

  /// The time to save, and the lagna to remember, for a reader who does not
  /// know their birth time.
  ///
  /// With a lagna, the middle of its window; without one, or if the window
  /// cannot be found, sunrise — and then no lagna is remembered, because
  /// nothing about the saved time would reflect it.
  static ({Duration time, Rasi? lagna}) timeWithout({
    required DateTime date,
    required Place place,
    required Rasi? lagna,
    RisingWindowFinder find = forBirth,
  }) {
    final window = lagna == null
        ? null
        : find(date: date, place: place, rasi: lagna);
    return window == null
        ? (time: BirthProfile.defaultUnknownTime, lagna: null)
        : (time: window.middle, lagna: lagna);
  }
}
