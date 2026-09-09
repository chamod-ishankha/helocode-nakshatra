import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../features/onboarding/data/profile_repository.dart';
import '../../features/onboarding/domain/birth_profile.dart';
import '../../l10n/generated/app_localizations.dart';
import '../astro/calendar_models.dart';
import '../astro/nekath.dart';
import '../astro/panchanga.dart';
import '../astro/panchanga_models.dart';
import '../astro/sri_lankan_calendar.dart';
import '../config/app_locale.dart';
import '../logging/app_logger.dart';
import 'notification_planner.dart';
import 'notification_prefs.dart';
import 'notification_service.dart';

/// Joins the three halves: what the user asked for, what the almanac says, and
/// the plugin that schedules it (KAN-33).
///
/// Kept apart from both the planner and the service because it is the only
/// piece that needs all of the ephemeris, the localisations and the saved
/// profile at once — and it is the piece that cannot be unit-tested, since
/// each of those needs a device. The decisions live next door in
/// [NotificationPlanner], where they can be.
/// Rebuilds the schedule. Awaited by the settings screen after a change, so
/// switching a reminder on takes effect before the user leaves the screen.
///
/// It watches the two things a schedule is built from. Without that a
/// FutureProvider hands back its cached result and the second call does
/// nothing — which is what happened: the switch went on, the settings screen
/// awaited a future that had already completed while both reminders were off,
/// and not a single alarm was registered.
final notificationRefreshProvider = FutureProvider<void>((ref) {
  ref.watch(notificationPrefsProvider);
  ref.watch(profileProvider);
  return NotificationCoordinator.refresh(ref);
});

abstract final class NotificationCoordinator {
  /// Rebuilds the whole schedule from current preferences.
  ///
  /// Called at startup and whenever a reminder setting changes. Cheap enough
  /// to do either time: seven pañcāṅga are a few ephemeris calls each, and it
  /// is off the first frame.
  static Future<void> refresh(Ref ref) async {
    try {
      final prefs = ref.read(notificationPrefsProvider);
      if (!prefs.anyEnabled) {
        await NotificationService.cancelAll();
        return;
      }

      final profile = ref.read(profileProvider);
      if (profile == null) return;

      final locale = ref.read(localeProvider);
      final strings = await _strings(locale);
      final now = DateTime.now();

      final planned = NotificationPlanner.plan(
        now: now,
        prefs: prefs,
        strings: strings,
        rahuFor: (day) => _rahuOn(day, profile),
        poyaDays: _poyaWithin(now),
        poyaName: (poya) => poya.label(locale),
        formatTime: DateFormat('h:mm a', locale.code).format,
      );

      await NotificationService.reschedule(
        prefs: prefs,
        notifications: planned,
      );
    } on Object catch (e, s) {
      // A reminder that fails to schedule must not stop the app. It is the
      // same rule as sync and crash reporting: an enhancement, never a
      // dependency.
      AppLogger.warn('Could not refresh notifications', e, s);
    }
  }

  /// Rāhu kālaya for one day, or null if it cannot be computed.
  static TimeWindow? _rahuOn(DateTime day, BirthProfile profile) {
    try {
      final panchanga = Panchangam.forDate(
        date: day,
        zoneName: profile.place.timezone,
        latitude: profile.place.latitude,
        longitude: profile.place.longitude,
      );
      return Nekath.rahuKalaya(panchanga);
    } on Object catch (e) {
      // One bad day should not lose the other six.
      AppLogger.warn('No rāhu kālaya for $day: $e');
      return null;
    }
  }

  static List<PoyaDay> _poyaWithin(DateTime now) {
    try {
      final horizon = now.add(
        const Duration(days: NotificationService.horizonDays + 1),
      );
      return [
        ...SriLankanCalendar.poyaDaysIn(now.year),
        // A poya inside the horizon can belong to next year in late December.
        if (horizon.year != now.year)
          ...SriLankanCalendar.poyaDaysIn(horizon.year),
      ];
    } on Object catch (e) {
      AppLogger.warn('Could not list poya days: $e');
      return const [];
    }
  }

  static Future<NotificationStrings> _strings(AppLocale locale) async {
    final l10n = await L10n.delegate.load(Locale(locale.code));

    return NotificationStrings(
      dailyTitle: l10n.notificationDailyTitle,
      dailyBody: l10n.notificationDailyBody,
      dailyBodyNoWindow: l10n.notificationDailyBodyUnknown,
      poyaTitle: l10n.notificationPoyaTitle,
      poyaBody: l10n.notificationPoyaBody,
    );
  }
}
