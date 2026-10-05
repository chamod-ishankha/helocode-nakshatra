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
