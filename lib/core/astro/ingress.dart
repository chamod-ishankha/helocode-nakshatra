import 'models.dart';

/// A graha crossing from one rāśi into the next.
///
/// The event a transit alert is about. Everything else in [Gochara] answers
/// "where is it now"; this answers "when does it move", which is the question
/// a notification has to have an answer to before it can be scheduled.
class SignIngress {
  const SignIngress({
    required this.graha,
    required this.from,
    required this.to,
    required this.on,
  });

  final Graha graha;
  final Rasi from;
  final Rasi to;

  /// The day of the crossing, in the same zone as the window it was found in.
  ///
  /// A date, not an instant: midnight, and UTC only if the search started
  /// from a UTC date. That flavour has to be carried rather than normalised,
  /// because "which day did Śani move" is a local question. Forcing UTC here
  /// would put the answer on the previous day for every user west of
  /// Greenwich — the notification would arrive before the transit.
  final DateTime on;

  /// Whether the graha entered the *previous* sign rather than the next.
  ///
  /// True for every Rāhu and Ketu ingress — the nodes only ever move
  /// backwards — and for the occasional retrograde re-entry by Jupiter or
  /// Saturn, which can leave a sign and come back months later.
  bool get isRetrograde => to.index == (from.index - 1) % 12;

  @override
  String toString() =>
      '${graha.en}: ${from.en} to ${to.en} on '
      '${on.toIso8601String().substring(0, 10)}'
      '${isRetrograde ? ' (retrograde)' : ''}';
}

/// Finding the dates on which the slow grahas change sign (KAN-65).
///
/// ## Why only four grahas
///
/// The Moon changes sign every two and a half days and Mercury every few
/// weeks. Alerting on those would be a notification every other morning,
/// which is how an app gets its notifications turned off. The four here are
/// the ones whose sign change is an event people already talk about: Śani
/// every two and a half years, Guru every year, and the nodes every eighteen
/// months.
///
/// ## Why it samples rather than solves
///
/// There is a closed form for none of this — the ephemeris is the only source
/// of a position, and it answers "where is Saturn at this instant", not "when
/// does Saturn reach 300°". So [between] walks forward in steps small enough
/// that a sign cannot be skipped, and bisects wherever the sign changed.
///
/// [signsAt] is injected rather than called directly, which is what makes any
/// of this testable: the real ephemeris is device-only and cannot run under
/// `flutter test`, but the search itself is ordinary arithmetic and is where
/// the mistakes would be.
abstract final class Ingress {
  /// The grahas slow enough that a sign change is worth telling someone about.
  static const Set<Graha> slow = {
    Graha.jupiter,
    Graha.saturn,
    Graha.rahu,
    Graha.ketu,
  };

  /// Close enough that no graha in [slow] can cross a whole sign unseen.
  ///
  /// Jupiter is the fastest of the four at roughly 14 arc-minutes a day, so a
  /// sign takes it four months at top speed. Three days is far tighter than
  /// that needs to be, and the margin is deliberate: it is there to catch a
  /// retrograde graha leaving a sign and returning, where the two crossings
  /// can be close together and a coarse step would see neither.
  static const Duration defaultStep = Duration(days: 3);

  /// Every sign change in `[from, to)`, in date order.
  ///
  /// [signsAt] must answer for at least the grahas in [slow]; anything else it
  /// returns is ignored. A graha it does not know is skipped rather than
  /// treated as having moved, so a partial ephemeris cannot invent an event.
  static List<SignIngress> between({
    required DateTime from,
    required DateTime to,
    required Map<Graha, Rasi> Function(DateTime) signsAt,
    Duration step = defaultStep,
  }) {
    assert(step > Duration.zero, 'step must move forward');
    if (!to.isAfter(from)) return const [];

    final found = <SignIngress>[];

    var previousAt = from;
    var previous = signsAt(from);

    while (previousAt.isBefore(to)) {
      var currentAt = previousAt.add(step);
      if (currentAt.isAfter(to)) currentAt = to;
      final current = signsAt(currentAt);

      for (final graha in slow) {
        final before = previous[graha];
        final after = current[graha];
        if (before == null || after == null || before == after) continue;

        found.add(
          SignIngress(
            graha: graha,
            from: before,
            to: after,
            on: _crossing(graha, previousAt, currentAt, after, signsAt),
          ),
        );
      }

      previousAt = currentAt;
      previous = current;
    }

    found.sort((a, b) => a.on.compareTo(b.on));
    return found;
  }

  /// How tightly the crossing instant is pinned down before its day is taken.
  ///
  /// The answer is a date, so a minute is far finer than anything reported —
  /// but the date cannot be read off a bracket wider than the ambiguity it
  /// leaves. Stopping at a day, which is what this did first, meant a bracket
  /// could straddle midnight and the crossing be dated to the wrong side of
  /// it: on a real ephemeris, Jupiter entering Karka late on one day was
  /// reported on the next. Twelve extra lookups, and only for a graha that
  /// actually moved.
  static const Duration _precision = Duration(minutes: 1);

  /// The day within `(before, after]` on which [graha] enters [target].
  ///
  /// Bisection rather than a linear walk, because the ephemeris call is the
  /// expensive part and this turns a step's worth of days into a handful of
  /// lookups. It assumes one crossing inside the bracket, which [defaultStep]
  /// is chosen to guarantee.
  ///
  /// Returns the calendar day the crossing falls in, in [before]'s own zone —
  /// the date an almanac would print for a Śani māruva, not the first whole
  /// day on the far side of it.
  static DateTime _crossing(
    Graha graha,
    DateTime before,
    DateTime after,
    Rasi target,
    Map<Graha, Rasi> Function(DateTime) signsAt,
  ) {
    var low = before;
    var high = after;

    while (high.difference(low) > _precision) {
      final mid = low.add(
        Duration(microseconds: high.difference(low).inMicroseconds ~/ 2),
      );

      if (signsAt(mid)[graha] == target) {
        high = mid;
      } else {
        low = mid;
      }
    }

    return high.isUtc
        ? DateTime.utc(high.year, high.month, high.day)
        : DateTime(high.year, high.month, high.day);
  }
}
