import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/astro/nekath.dart';
import '../../../core/astro/panchanga.dart';
import '../../../core/astro/panchanga_models.dart';
import '../../onboarding/data/profile_repository.dart';

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

/// The inauspicious window currently in progress, if any.
///
/// Only meaningful while viewing today — a "right now" badge on yesterday's
/// almanac would be nonsense.
final currentlyInauspiciousProvider = Provider<TimeWindow?>((ref) {
  final p = ref.watch(panchangaProvider);
  if (p == null || !ref.watch(selectedDateProvider.notifier).isToday) {
    return null;
  }
  final now = DateTime.now();
  for (final w in Nekath.inauspicious(p)) {
    if (w.contains(now)) return w;
  }
  return null;
});
