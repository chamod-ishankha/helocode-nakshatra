import 'package:flutter/foundation.dart';

import '../astro/calendar_models.dart';
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
  });

  final String dailyTitle;

  /// Given the formatted start and end of rāhu kālaya.
  final String Function(String start, String end) dailyBody;

  /// When the window could not be computed for that day.
  final String dailyBodyNoWindow;

  final String poyaTitle;

  /// Given the poya's name in the reader's language.
  final String Function(String poya) poyaBody;
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
    }

    return planned;
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
