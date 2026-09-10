import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../features/onboarding/data/profile_repository.dart';
import '../../features/onboarding/domain/birth_profile.dart';
import '../../l10n/generated/app_localizations.dart';
import '../astro/calendar_models.dart';
import '../astro/dasha.dart';
import '../astro/ephemeris.dart';
import '../astro/ingress.dart';
import '../astro/models.dart';
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

      // One chart, used for both the daśā tree and the natal Moon a transit
      // is measured from. Computing it twice would be a second full
      // ephemeris pass at every launch for no new information.
      final natal = (prefs.dasha || prefs.transit) ? _chartFor(profile) : null;

      final planned = NotificationPlanner.plan(
        now: now,
        prefs: prefs,
        strings: strings,
        rahuFor: (day) => _rahuOn(day, profile),
        poyaDays: _poyaWithin(now),
        poyaName: (poya) => poya.label(locale),
        formatTime: DateFormat('h:mm a', locale.code).format,
        festivals: _festivalsWithin(now),
        festivalName: (festival) => festival.label(locale),
        dashaPeriods: prefs.dasha && natal != null
            ? _dashaPeriods(natal)
            : const [],
        grahaName: (lord) => lord.label(locale),
        ingresses: prefs.transit ? _ingressesWithin(now, profile) : const [],
        rasiName: (rasi) => rasi.label(locale),
        natalMoon: natal?[Graha.moon].rasi,
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

  /// Every festival that could fall inside the horizon.
  ///
  /// The same year-boundary problem as the poya list: Thai Pongal is in
  /// January, so a horizon starting in late December has to look at next year
  /// too or it would silently never fire.
  static List<Festival> _festivalsWithin(DateTime now) {
    try {
      final horizon = now.add(
        const Duration(days: NotificationService.horizonDays + 1),
      );
      return [
        ...SriLankanCalendar.festivalsIn(now.year),
        if (horizon.year != now.year)
          ...SriLankanCalendar.festivalsIn(horizon.year),
      ];
    } on Object catch (e) {
      AppLogger.warn('Could not list festivals: $e');
      return const [];
    }
  }

  /// The user's mahādaśā and antardaśā, flattened.
  ///
  /// Depth two on purpose. Pratyantara periods turn over every few days, so a
  /// third level would put a notification in this list most weeks and turn the
  /// rarest reminder in the app into the noisiest.
  ///
  /// Computed only when the switch is on: this is a chart calculation, and
  /// running it at every launch for a user who never asked for it is work
  /// nobody benefits from.
  static List<DashaPeriod> _dashaPeriods(BirthChart chart) {
    try {
      final maha = Vimshottari.forChart(chart, depth: 2);
      return [...maha, for (final m in maha) ...m.children];
    } on Object catch (e) {
      AppLogger.warn('Could not compute daśā periods: $e');
      return const [];
    }
  }

  /// The user's own chart, or null if it cannot be computed.
  static BirthChart? _chartFor(BirthProfile profile) {
    try {
      return Ephemeris.computeChart(
        localWallClock: profile.localWallClock,
        zoneName: profile.place.timezone,
        latitude: profile.place.latitude,
        longitude: profile.place.longitude,
      ).valueOrNull;
    } on Object catch (e) {
      AppLogger.warn('Could not compute the natal chart: $e');
      return null;
    }
  }

  /// Slow-graha sign changes inside the scheduling horizon (KAN-65).
  ///
  /// Only the horizon, not the year. There is no background job — the
  /// schedule is topped up when the app is opened — so an ingress further out
  /// than [NotificationService.horizonDays] would be found, discarded by the
  /// planner's day loop, and found again next launch. Searching a week costs
  /// three or four ephemeris calls; searching a year would cost a hundred and
  /// twenty, at every launch, to schedule nothing.
  ///
  /// The place is the user's own rather than a fixed meridian. A sign change
  /// is a moment in absolute time, so where it is observed from does not move
  /// it — but the date it lands on is a local date, and Colombo is five and a
  /// half hours from UTC.
  static List<SignIngress> _ingressesWithin(
    DateTime now,
    BirthProfile profile,
  ) {
    try {
      final from = DateTime(now.year, now.month, now.day);

      return Ingress.between(
        from: from,
        to: from.add(const Duration(days: NotificationService.horizonDays)),
        signsAt: (at) {
          final chart = Ephemeris.computeChart(
            localWallClock: DateTime(
              at.year,
              at.month,
              at.day,
              at.hour,
              at.minute,
            ),
            zoneName: profile.place.timezone,
            latitude: profile.place.latitude,
            longitude: profile.place.longitude,
          ).valueOrNull;
          if (chart == null) return const {};

          return {
            for (final entry in chart.positions.entries)
              entry.key: entry.value.rasi,
          };
        },
      );
    } on Object catch (e) {
      AppLogger.warn('Could not find sign changes: $e');
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
      festivalTitle: l10n.notificationFestivalTitle,
      festivalBody: l10n.notificationFestivalBody,
      dashaTitle: l10n.notificationDashaTitle,
      dashaMahaBody: l10n.notificationDashaMahaBody,
      dashaAntaraBody: l10n.notificationDashaAntaraBody,
      transitTitle: l10n.notificationTransitTitle,
      transitBody: l10n.notificationTransitBody,
      transitSadeSatiBody: l10n.notificationTransitSadeSati,
    );
  }
}
