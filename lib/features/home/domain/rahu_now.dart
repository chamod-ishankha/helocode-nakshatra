import '../../../core/astro/panchanga_models.dart';

/// Where today's rāhu kālaya stands against the clock.
enum RahuPhase { ahead, running, past }

/// The state the home screen's chip and ring draw (KAN-92).
class RahuNow {
  const RahuNow._(this.phase, this.progress);

  /// [rahu] read at [now].
  ///
  /// [progress] is how much of the window has gone, 0 before it starts and 1
  /// after it ends, so the ring is never asked to draw more than a circle.
  factory RahuNow.of(TimeWindow rahu, DateTime now) {
    if (now.isBefore(rahu.start)) return const RahuNow._(RahuPhase.ahead, 0);
    if (!now.isBefore(rahu.end)) return const RahuNow._(RahuPhase.past, 1);
    final total = rahu.duration.inSeconds;
    final gone = now.difference(rahu.start).inSeconds;
    return RahuNow._(RahuPhase.running, total == 0 ? 1 : gone / total);
  }

  final RahuPhase phase;
  final double progress;
}

/// How far [t] is through the daylight between [sunrise] and [sunset], from 0
/// to 1: the position of a moment on the day arc.
///
/// Clamped, so the sun sits on the horizon before dawn and after dusk rather
/// than being drawn underneath the arc.
double dayFraction(DateTime sunrise, DateTime sunset, DateTime t) {
  final day = sunset.difference(sunrise).inSeconds;
  if (day <= 0) return 0;
  return (t.difference(sunrise).inSeconds / day).clamp(0.0, 1.0);
}

/// How many minutes lie between [start] and [end] as the card prints them.
///
/// Counted between the clock minutes shown, not from the exact seconds: a
/// window from 7:30:50 to 8:59:10 is 88 minutes and 20 seconds, and "88" under
/// "7:30 – 8:59" reads as an arithmetic mistake. The reader checks one against
/// the other, so they have to agree.
int shownMinutes(DateTime start, DateTime end) {
  DateTime floor(DateTime t) =>
      DateTime(t.year, t.month, t.day, t.hour, t.minute);
  return floor(end).difference(floor(start)).inMinutes;
}

/// [minutes] split for display: under an hour stays in minutes, so a short
/// window is not written "0 hr 45 min".
({int hours, int minutes}) splitMinutes(int minutes) =>
    (hours: minutes ~/ 60, minutes: minutes % 60);
