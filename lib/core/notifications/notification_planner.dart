import 'package:flutter/foundation.dart';

import '../astro/calendar_models.dart';
import '../astro/dasha.dart';
import '../astro/gochara.dart';
import '../astro/ingress.dart';
import '../astro/models.dart';
import '../astro/panchanga_models.dart';
import 'notification_prefs.dart';
import 'notification_service.dart';

/// The words a notification needs, already localised.
///
/// Passed in rather than looked up, so the planner has no `BuildContext` and
/// no opinion about language — it runs at startup, where there is no context
/// to hand, and it is the part worth testing.
@immutable
class NotificationStrings {
  const NotificationStrings({
    required this.dailyTitle,
    required this.dailyBody,
    required this.dailyBodyNoWindow,
    required this.poyaTitle,
    required this.poyaBody,
    required this.festivalTitle,
    required this.festivalBody,
    required this.dashaTitle,
    required this.dashaMahaBody,
    required this.dashaAntaraBody,
    required this.transitTitle,
    required this.transitBody,
    required this.transitSadeSatiBody,
  });

  final String dailyTitle;

  /// Given the formatted start and end of rāhu kālaya.
  final String Function(String start, String end) dailyBody;

  /// When the window could not be computed for that day.
  final String dailyBodyNoWindow;

  final String poyaTitle;

  /// Given the poya's name in the reader's language.
  final String Function(String poya) poyaBody;

  final String festivalTitle;

  /// Given the festival's name in the reader's language.
  final String Function(String festival) festivalBody;

  final String dashaTitle;

  /// Given the incoming lord's name. Two bodies rather than one with the
  /// level as a second placeholder: "your {lord} {level} begins" reads as
  /// machine translation in Sinhala and Tamil, where the two words join.
  final String Function(String lord) dashaMahaBody;
  final String Function(String lord) dashaAntaraBody;

  /// Given the moving graha's name.
  final String Function(String graha) transitTitle;

  /// Given the graha, the sign it is entering, and which house that is from
  /// the reader's natal Moon.
  ///
  /// The house is the whole point. "Saturn enters Aquarius" is an almanac
  /// fact anybody can read anywhere; "Saturn enters your eighth house" is the
  /// one the reader opened this app for.
  final String Function(String graha, String rasi, int house) transitBody;

  /// Śani entering the twelfth from the Moon, which begins sade sati.
  ///
  /// Its own line because it is the transit people here ask about by name,
  /// and burying the start of seven and a half years inside a generic "house
  /// 12" sentence would be the app failing to say the one thing it knew.
  final String Function(String rasi) transitSadeSatiBody;
}

/// Decides what to schedule, and when.
///
/// Separate from [NotificationService] because this is the half with rules in
/// it — which days, at what moment, skipping what — and the service is the
/// half that talks to a plugin that cannot run in a test. Everything here is
/// pure: give it a clock, preferences and an almanac, and it returns a list.
abstract final class NotificationPlanner {
  /// The evening before a poya, in local time. Late enough to read after work,
  /// early enough not to wake anyone.
  @visibleForTesting
  static const int poyaReminderHour = 18;

  static List<ScheduledNotification> plan({
    required DateTime now,
    required NotificationPrefs prefs,
    required NotificationStrings strings,
    required TimeWindow? Function(DateTime day) rahuFor,
    required List<PoyaDay> poyaDays,
    required String Function(PoyaDay poya) poyaName,
    required String Function(DateTime time) formatTime,
    required List<Festival> festivals,
    required String Function(Festival festival) festivalName,
    required List<DashaPeriod> dashaPeriods,
    required String Function(Graha lord) grahaName,
    required List<SignIngress> ingresses,
    required String Function(Rasi rasi) rasiName,
    required Rasi? natalMoon,
    int horizonDays = NotificationService.horizonDays,
  }) {
    final planned = <ScheduledNotification>[];
    final today = DateTime(now.year, now.month, now.day);

    for (var offset = 0; offset < horizonDays; offset++) {
      final day = today.add(Duration(days: offset));

      if (prefs.daily) {
        final at = DateTime(
          day.year,
          day.month,
          day.day,
          prefs.hour,
          prefs.minute,
        );

        // Today's reminder is skipped once its time has passed. Scheduling a
        // moment in the past fires it immediately, which reads as a bug to
        // whoever just switched the setting on.
        if (at.isAfter(now)) {
          final rahu = rahuFor(day);
          planned.add(
            ScheduledNotification(
              id: NotificationService.dailyId(offset),
              at: at,
              title: strings.dailyTitle,
              body: rahu == null
                  ? strings.dailyBodyNoWindow
                  : strings.dailyBody(
                      formatTime(rahu.start),
                      formatTime(rahu.end),
                    ),
              payload: _payload(day),
            ),
          );
        }
      }

      if (prefs.poya) {
        // The reminder is the evening *before*, so it is scheduled against the
        // poya that falls on the following day.
        final poya = _poyaOn(poyaDays, day.add(const Duration(days: 1)));
        final at = DateTime(day.year, day.month, day.day, poyaReminderHour);

        if (poya != null && at.isAfter(now)) {
          planned.add(
            ScheduledNotification(
              id: NotificationService.poyaId(offset),
              at: at,
              title: strings.poyaTitle,
              body: strings.poyaBody(poyaName(poya)),
              payload: _payload(poya.date),
            ),
          );
        }
      }

      if (prefs.festival) {
        // Same shape as the poya reminder: the evening before, so there is
        // still an evening to prepare in.
        final festival = _festivalOn(
          festivals,
          day.add(const Duration(days: 1)),
        );
        final at = DateTime(day.year, day.month, day.day, poyaReminderHour);

        if (festival != null && at.isAfter(now)) {
          planned.add(
            ScheduledNotification(
              id: NotificationService.festivalId(offset),
              at: at,
              title: strings.festivalTitle,
              body: strings.festivalBody(festivalName(festival)),
              payload: _payload(festival.date),
            ),
          );
        }
      }

      if (prefs.dasha) {
        final change = _dashaStartingOn(dashaPeriods, day);
        final at = DateTime(
          day.year,
          day.month,
          day.day,
          prefs.hour,
          prefs.minute,
        );

        if (change != null && at.isAfter(now)) {
          planned.add(
            ScheduledNotification(
              id: NotificationService.dashaId(offset),
              at: at,
              title: strings.dashaTitle,
              body: change.level == DashaLevel.maha
                  ? strings.dashaMahaBody(grahaName(change.lord))
                  : strings.dashaAntaraBody(grahaName(change.lord)),
              payload: _payload(day),
            ),
          );
        }
      }

      // Transit alerts (KAN-65). Plural, unlike every other kind: Rāhu and
      // Ketu sit opposite each other and always change sign on the same day,
      // so this is the one block that can legitimately schedule two.
      if (prefs.transit && natalMoon != null) {
        final at = DateTime(
          day.year,
          day.month,
          day.day,
          prefs.hour,
          prefs.minute,
        );

        if (at.isAfter(now)) {
          for (final ingress in _ingressesOn(ingresses, day)) {
            final house = Gochara.houseFrom(natalMoon, ingress.to);
            final sign = rasiName(ingress.to);

            planned.add(
              ScheduledNotification(
                id: NotificationService.transitId(offset, ingress.graha),
                at: at,
                title: strings.transitTitle(grahaName(ingress.graha)),
                // Saturn arriving in the twelfth is the start of sade sati,
                // and saying "house 12" instead would be the app knowing the
                // thing the reader came for and not saying it.
                body:
                    ingress.graha == Graha.saturn &&
                        Gochara.saturnPhase(natalMoon, ingress.to) ==
                            SaturnPhase.sadeSatiRising
                    ? strings.transitSadeSatiBody(sign)
                    : strings.transitBody(
                        grahaName(ingress.graha),
                        sign,
                        house,
                      ),
                payload: _payload(day),
              ),
            );
          }
        }
      }
    }

    return planned;
  }

  /// Every sign change falling on [day].
  ///
  /// A list rather than the single value the other helpers return, and not
  /// deduplicated by graha: a graha that leaves a sign and returns does so
  /// months apart, so two entries for one graha on one day would mean the
  /// search was wrong rather than that the day was busy.
  static List<SignIngress> _ingressesOn(
    List<SignIngress> ingresses,
    DateTime day,
  ) {
    final out = <SignIngress>[];
    for (final i in ingresses) {
      // Stored UTC at midnight, compared as the local day it lands on —
      // the same convention as _dashaStartingOn, and for the same reason.
      final on = i.on.toLocal();
      if (on.year == day.year && on.month == day.month && on.day == day.day) {
        out.add(i);
      }
    }
    return out;
  }

  /// The festival on [day] that is worth interrupting somebody for.
  ///
  /// ## Why only the solar ingresses
  ///
  /// The calendar knows Christmas, Independence Day, May Day and Good Friday
  /// too. Those are public holidays: the phone's own calendar already has
  /// them, and this app has nothing to add about them — a notification would
  /// be a second reminder of a date the user was not asking us about.
  ///
  /// A solar ingress is different. The Sinhala and Tamil New Year and Thai
  /// Pongal are the days this app's own subject matter is about, and the ones
  /// people actually consult an almanac for. That is two a year.
  ///
  /// Read off [FestivalKind] rather than a list of names, so a festival added
  /// to the calendar later lands on the right side of this by construction.
  /// The requirement for an [Festival.exactMoment] is what excludes the
  /// gazetted day *before* the New Year — it shares the kind but is a holiday
  /// marker rather than an event, and notifying for both would mean two
  /// notifications on consecutive evenings for one occasion.
  static Festival? _festivalOn(List<Festival> festivals, DateTime day) {
    for (final f in festivals) {
      if (f.kind != FestivalKind.solarIngress || f.exactMoment == null) {
        continue;
      }
      if (f.date.year == day.year &&
          f.date.month == day.month &&
          f.date.day == day.day) {
        return f;
      }
    }
    return null;
  }

  /// The daśā period beginning on [day], preferring the outer one.
  ///
  /// A mahādaśā always starts on the same instant as its first antardaśā, so
  /// without this preference every mahādaśā change would arrive as two
  /// notifications a minute apart saying almost the same thing. The outer
  /// period is the one that matters.
  static DashaPeriod? _dashaStartingOn(
    List<DashaPeriod> periods,
    DateTime day,
  ) {
    DashaPeriod? found;
    for (final p in periods) {
      final start = p.start.toLocal();
      if (start.year != day.year ||
          start.month != day.month ||
          start.day != day.day) {
        continue;
      }
      if (p.level == DashaLevel.maha) return p;
      found ??= p;
    }
    return found;
  }

  static PoyaDay? _poyaOn(List<PoyaDay> poyaDays, DateTime day) {
    for (final p in poyaDays) {
      if (p.date.year == day.year &&
          p.date.month == day.month &&
          p.date.day == day.day) {
        return p;
      }
    }
    return null;
  }

  /// The day the notification is about, so tapping it can open the home screen
  /// already showing that day rather than today.
  static String _payload(DateTime day) =>
      DateTime(day.year, day.month, day.day).toIso8601String();

  /// Reads a payload back. Null for anything unparseable, so a malformed one
  /// opens the app normally instead of failing.
  static DateTime? dateFromPayload(String? payload) {
    if (payload == null) return null;
    final parsed = DateTime.tryParse(payload);
    return parsed == null
        ? null
        : DateTime(parsed.year, parsed.month, parsed.day);
  }
}
