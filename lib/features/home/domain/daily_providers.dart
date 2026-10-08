import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/astro/calendar_models.dart';
import '../../../core/astro/nekath.dart';
import '../../../core/astro/panchanga.dart';
import '../../../core/astro/panchanga_models.dart';
import '../../../core/astro/sri_lankan_calendar.dart';
import '../../onboarding/data/profile_repository.dart';
import '../../../core/content/content_service.dart';

/// The day the home screen is showing.
///
/// Normalised to midnight so switching days cannot accidentally carry a time
/// component and produce two cache entries for the same date.
class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Jumps to a specific day. Used by the calendar, which hands a date back
  /// to the home screen rather than rendering its own day view.
  void set(DateTime date) {
    state = DateTime(date.year, date.month, date.day);
  }

  void shift(int days) {
    final next = state.add(Duration(days: days));
    state = DateTime(next.year, next.month, next.day);
  }

  void today() {
    final now = DateTime.now();
    state = DateTime(now.year, now.month, now.day);
  }

  bool get isToday {
    final now = DateTime.now();
    return state.year == now.year &&
        state.month == now.month &&
        state.day == now.day;
  }
}

final selectedDateProvider = NotifierProvider<SelectedDateNotifier, DateTime>(
  SelectedDateNotifier.new,
);

/// The almanac for the selected day at the user's saved birth place.
///
/// Panchanga is location-dependent — sunrise differs across the island — and
/// the birth place is the only location we hold. That is a reasonable default
/// but not always right for someone who has moved; a current-location option
/// belongs in settings (KAN-30).
///
/// Null until onboarding has completed.
final panchangaProvider = Provider<Panchanga?>((ref) {
  final profile = ref.watch(profileProvider);
  if (profile == null) return null;

  final date = ref.watch(selectedDateProvider);
  return Panchangam.forDate(
    date: date,
    zoneName: profile.place.timezone,
    latitude: profile.place.latitude,
    longitude: profile.place.longitude,
  );
});

final inauspiciousProvider = Provider<List<TimeWindow>>((ref) {
  final p = ref.watch(panchangaProvider);
  return p == null ? const [] : Nekath.inauspicious(p);
});

final auspiciousProvider = Provider<List<TimeWindow>>((ref) {
  final p = ref.watch(panchangaProvider);
  return p == null ? const [] : Nekath.auspiciousWindows(p);
});

/// The time, to the minute, as far as the home screen is concerned.
///
/// A provider rather than `DateTime.now()` at each use, so everything that
/// says "now" — the running-now banner, the rāhu chip, the ring and the sun on
/// the day arc — moves together when the minute turns, rather than whenever
/// something else happens to rebuild them. The home screen owns the timer and
/// calls [ClockNotifier.tick]; a timer in here would outlive the screen.
class ClockNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  void tick() => state = DateTime.now();
}

final clockProvider = NotifierProvider<ClockNotifier, DateTime>(
  ClockNotifier.new,
);

/// The inauspicious window currently in progress, if any.
///
/// Only meaningful while viewing today — a "right now" badge on yesterday's
/// almanac would be nonsense.
///
/// Watches the clock, so the banner appears when rāhu kālaya starts and goes
/// when it ends. It used to read the time once, when the day was computed, so
/// an app left open over lunch kept saying "running now" all afternoon.
final currentlyInauspiciousProvider = Provider<TimeWindow?>((ref) {
  final now = ref.watch(clockProvider);
  final date = ref.watch(selectedDateProvider);
  if (!isSameDay(date, now)) return null;
  for (final w in ref.watch(inauspiciousProvider)) {
    if (w.contains(now)) return w;
  }
  return null;
});

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// The next poya on or after the selected day.
///
/// Scanning a year of full moons is not free, so this is computed from the
/// selected date rather than the clock, which keeps it stable while the user
/// pages through days.
///
/// Watches the content bundle because a published calendar can move a poya
/// (KAN-49); the calendar itself is static, so nothing else would tell this
/// to recompute.
final nextPoyaProvider = Provider<PoyaDay?>((ref) {
  ref.watch(contentBundleProvider);
  return SriLankanCalendar.nextPoya(ref.watch(selectedDateProvider));
});

/// The next festival of any kind, poya included.
final nextFestivalProvider = Provider<Festival?>((ref) {
  ref.watch(contentBundleProvider);
  return SriLankanCalendar.nextFestival(ref.watch(selectedDateProvider));
});

/// The religious holidays with no date yet for the selected year — the
/// "still to come" note names them, and goes once they are all published.
final unannouncedFestivalsProvider = Provider<List<String>>((ref) {
  ref.watch(contentBundleProvider);
  return SriLankanCalendar.unannouncedIn(ref.watch(selectedDateProvider).year);
});

/// The poya falling exactly on the selected day, if there is one.
final poyaTodayProvider = Provider<PoyaDay?>((ref) {
  final date = ref.watch(selectedDateProvider);
  final next = ref.watch(nextPoyaProvider);
  if (next == null) return null;
  return next.date == DateTime(date.year, date.month, date.day) ? next : null;
});
