import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/astro/calendar_models.dart';
import '../../../core/astro/muhurta.dart';
import '../../../core/astro/panchanga.dart';
import '../../../core/astro/sri_lankan_calendar.dart';
import '../../onboarding/data/profile_repository.dart';

/// The month the calendar is showing, as its first day.
class VisibleMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void shift(int months) {
    state = DateTime(state.year, state.month + months);
  }

  void today() {
    final now = DateTime.now();
    state = DateTime(now.year, now.month);
  }
}

final visibleMonthProvider =
    NotifierProvider<VisibleMonthNotifier, DateTime>(VisibleMonthNotifier.new);

/// Poya days and festivals falling in the visible month.
///
/// Cheap: both come from year-level tables rather than a per-day computation,
/// so the grid can be built without touching the ephemeris.
final monthMarkersProvider = Provider<Map<int, List<Festival>>>((ref) {
  final month = ref.watch(visibleMonthProvider);

  final events = <Festival>[
    ...SriLankanCalendar.poyaDaysIn(month.year),
    ...SriLankanCalendar.festivalsIn(month.year),
  ];

  final byDay = <int, List<Festival>>{};
  for (final e in events) {
    if (e.date.year == month.year && e.date.month == month.month) {
      byDay.putIfAbsent(e.date.day, () => []).add(e);
    }
  }
  return byDay;
});

/// One day's best window for an activity.
class DayScore {
  const DayScore({
    required this.date,
    required this.best,
  });

  final DateTime date;
  final MuhurtaWindow best;
}

/// What to scan for.
class ScanRequest {
  const ScanRequest(this.month, this.activity);

  final DateTime month;
  final Activity activity;

  @override
  bool operator ==(Object other) =>
      other is ScanRequest &&
      other.month == month &&
      other.activity == activity;

  @override
  int get hashCode => Object.hash(month, activity);
}

/// Scores every day of a month for one activity, best first.
///
/// Deliberately a [FutureProvider] rather than a plain one. A pañcāṅga costs
/// several ephemeris calls and a handful of bisections, so thirty of them in a
/// row on the UI thread would drop frames. Yielding between days keeps the
/// screen responsive and lets the caller show progress — this is a query the
/// user asks for, not something computed on the way in.
final monthScanProvider =
    FutureProvider.family<List<DayScore>, ScanRequest>((ref, request) async {
  final profile = ref.watch(profileProvider);
  if (profile == null) return const [];

  final month = request.month;
  final days = DateTime(month.year, month.month + 1, 0).day;
  final scored = <DayScore>[];

  for (var day = 1; day <= days; day++) {
    // Hand the frame back between days so the spinner keeps turning.
    await Future<void>.delayed(Duration.zero);

    final panchanga = Panchangam.forDate(
      date: DateTime(month.year, month.month, day),
      zoneName: profile.place.timezone,
      latitude: profile.place.latitude,
      longitude: profile.place.longitude,
    );

    final windows = Muhurta.forActivity(panchanga, request.activity);
    if (windows.isEmpty) continue;

    scored.add(
      DayScore(
        date: DateTime(month.year, month.month, day),
        best: windows.first,
      ),
    );
  }

  scored.sort((a, b) {
    final byScore = b.best.score.compareTo(a.best.score);
    // Equal scores go in date order, so the soonest good day reads first.
    return byScore != 0 ? byScore : a.date.compareTo(b.date);
  });
  return scored;
});

/// Guards against scanning before the user has asked.
class ChosenActivityNotifier extends Notifier<Activity?> {
  @override
  Activity? build() => null;

  void set(Activity? a) => state = a;
}

final chosenActivityProvider =
    NotifierProvider<ChosenActivityNotifier, Activity?>(
  ChosenActivityNotifier.new,
);
