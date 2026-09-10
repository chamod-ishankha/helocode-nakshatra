import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/astro/calendar_models.dart';
import 'package:nakshatra/core/astro/dasha.dart';
import 'package:nakshatra/core/astro/models.dart';
import 'package:nakshatra/core/astro/panchanga_models.dart';
import 'package:nakshatra/core/notifications/notification_planner.dart';
import 'package:nakshatra/core/notifications/notification_prefs.dart';
import 'package:nakshatra/core/notifications/notification_service.dart';

/// What gets scheduled, and when (KAN-33).
///
/// This is the half of notifications with rules in it. The plugin cannot run
/// in a test and the almanac needs a device, so the planner takes a clock, a
/// set of preferences and a way to look up a day, and returns a plain list —
/// which makes the decisions checkable without either.
///
/// The decisions worth being sure about are the quiet ones: not firing a
/// reminder into the past, not reminding about a poya that has gone, and not
/// scheduling anything at all when the user has asked for nothing.
void main() {
  final strings = NotificationStrings(
    dailyTitle: 'Today',
    dailyBody: (start, end) => 'Rāhu kālaya $start to $end',
    dailyBodyNoWindow: 'Open for today',
    poyaTitle: 'Poya tomorrow',
    poyaBody: (poya) => '$poya is tomorrow',
    festivalTitle: 'Festival tomorrow',
    festivalBody: (festival) => '$festival is tomorrow',
    dashaTitle: 'A new daśā',
    dashaMahaBody: (lord) => '$lord mahādaśā',
    dashaAntaraBody: (lord) => '$lord antardaśā',
  );

  final poya = PoyaDay(
    date: DateTime(2026, 9, 26),
    month: PoyaMonth.binara,
    isAdhi: false,
    fullMoon: DateTime(2026, 9, 26, 20, 12),
  );

  TimeWindow rahuOn(DateTime day) => TimeWindow(
    start: DateTime(day.year, day.month, day.day, 15, 9),
    end: DateTime(day.year, day.month, day.day, 16, 40),
    kind: WindowKind.rahu,
  );

  /// A festival the app has something to say about.
  Festival ingress(DateTime date, String name) => Festival(
    date: date,
    name: name,
    kind: FestivalKind.solarIngress,
    exactMoment: DateTime(date.year, date.month, date.day, 8, 30),
  );

  DashaPeriod period(DashaLevel level, Graha lord, DateTime start) =>
      DashaPeriod(
        lord: lord,
        level: level,
        start: start.toUtc(),
        end: start.add(const Duration(days: 400)).toUtc(),
      );

  List<ScheduledNotification> plan({
    required DateTime now,
    required NotificationPrefs prefs,
    TimeWindow? Function(DateTime)? rahuFor,
    List<PoyaDay> poyaDays = const [],
    List<Festival> festivals = const [],
    List<DashaPeriod> dashaPeriods = const [],
    int? horizonDays,
  }) => NotificationPlanner.plan(
    now: now,
    prefs: prefs,
    strings: strings,
    rahuFor: rahuFor ?? rahuOn,
    poyaDays: poyaDays,
    poyaName: (p) => p.name,
    formatTime: (t) => '${t.hour}:${t.minute.toString().padLeft(2, '0')}',
    festivals: festivals,
    festivalName: (f) => f.name,
    dashaPeriods: dashaPeriods,
    grahaName: (g) => g.en,
    horizonDays: horizonDays ?? NotificationService.horizonDays,
  );

  group('the daily reminder', () {
    test('fills the horizon, one a day', () {
      final planned = plan(
        now: DateTime(2026, 9, 9, 5),
        prefs: const NotificationPrefs(daily: true),
      );

      expect(planned, hasLength(NotificationService.horizonDays));
      expect(planned.map((n) => n.at.day), [
        9,
        10,
        11,
        12,
        13,
        14,
        15,
      ], reason: 'one per day, starting today');
    });

    test('is at the configured time, not the default', () {
      final planned = plan(
        now: DateTime(2026, 9, 9, 5),
        prefs: const NotificationPrefs(daily: true, hour: 7, minute: 15),
      );

      expect(planned.first.at, DateTime(2026, 9, 9, 7, 15));
    });

    test("skips today once today's time has passed", () {
      // Scheduling a moment in the past fires it at once, which reads as a bug
      // to whoever just switched the setting on.
      final planned = plan(
        now: DateTime(2026, 9, 9, 9),
        prefs: const NotificationPrefs(daily: true),
      );

      expect(planned, hasLength(NotificationService.horizonDays - 1));
      expect(planned.first.at.day, 10);
    });

    test('carries that day\'s rāhu kālaya, not today\'s', () {
      // The whole reason these are scheduled one at a time rather than as a
      // repeating alarm: the times differ every day.
      final planned = plan(
        now: DateTime(2026, 9, 9, 5),
        prefs: const NotificationPrefs(daily: true),
        rahuFor: (day) => TimeWindow(
          start: DateTime(day.year, day.month, day.day, day.day, 0),
          end: DateTime(day.year, day.month, day.day, day.day, 30),
          kind: WindowKind.rahu,
        ),
      );

      expect(planned[0].body, contains('9:00'));
      expect(planned[1].body, contains('10:00'));
    });

    test('still sends something when the almanac has no answer', () {
      // Better a reminder to open the app than a body that says "null".
      final planned = plan(
        now: DateTime(2026, 9, 9, 5),
        prefs: const NotificationPrefs(daily: true),
        rahuFor: (_) => null,
      );

      expect(planned.first.body, 'Open for today');
    });

    test('ids are stable and distinct', () {
      // Reused ids silently replace each other, which would leave one
      // notification instead of seven.
      final planned = plan(
        now: DateTime(2026, 9, 9, 5),
        prefs: const NotificationPrefs(daily: true),
      );

      expect(planned.map((n) => n.id).toSet(), hasLength(planned.length));
    });
  });

  group('the poya reminder', () {
    test('lands the evening before', () {
      final planned = plan(
        now: DateTime(2026, 9, 20, 9),
        prefs: const NotificationPrefs(poya: true),
        poyaDays: [poya],
      );

      expect(planned, hasLength(1));
      expect(planned.single.at, DateTime(2026, 9, 25, 18));
      expect(planned.single.body, contains('Binara Poya'));
    });

    test('is not scheduled for a poya already past', () {
      final planned = plan(
        now: DateTime(2026, 9, 27, 9),
        prefs: const NotificationPrefs(poya: true),
        poyaDays: [poya],
      );

      expect(planned, isEmpty);
    });

    test('is not scheduled beyond the horizon', () {
      // 9 September is more than a week before the 26th, so nothing yet — it
      // gets picked up when the app is next opened closer to the day.
      final planned = plan(
        now: DateTime(2026, 9, 9, 9),
        prefs: const NotificationPrefs(poya: true),
        poyaDays: [poya],
      );

      expect(planned, isEmpty);
    });

    test('points at the poya, not at the evening it is announced', () {
      final planned = plan(
        now: DateTime(2026, 9, 20, 9),
        prefs: const NotificationPrefs(poya: true),
        poyaDays: [poya],
      );

      expect(
        NotificationPlanner.dateFromPayload(planned.single.payload),
        DateTime(2026, 9, 26),
      );
    });
  });

  group('preferences', () {
    test('nothing is planned when both are off', () {
      final planned = plan(
        now: DateTime(2026, 9, 9, 5),
        prefs: const NotificationPrefs(),
        poyaDays: [poya],
      );

      expect(planned, isEmpty);
    });

    test('the two are independent', () {
      final dailyOnly = plan(
        now: DateTime(2026, 9, 20, 5),
        prefs: const NotificationPrefs(daily: true),
        poyaDays: [poya],
      );
      final poyaOnly = plan(
        now: DateTime(2026, 9, 20, 5),
        prefs: const NotificationPrefs(poya: true),
        poyaDays: [poya],
      );

      expect(dailyOnly.every((n) => n.title == 'Today'), isTrue);
      expect(poyaOnly.every((n) => n.title == 'Poya tomorrow'), isTrue);
    });

    test('daily and poya ids never collide', () {
      final planned = plan(
        now: DateTime(2026, 9, 20, 5),
        prefs: const NotificationPrefs(daily: true, poya: true),
        poyaDays: [poya],
      );

      expect(planned.map((n) => n.id).toSet(), hasLength(planned.length));
    });
  });

  group('the payload', () {
    test('round-trips the day the notification is about', () {
      final planned = plan(
        now: DateTime(2026, 9, 9, 5),
        prefs: const NotificationPrefs(daily: true),
      );

      expect(
        NotificationPlanner.dateFromPayload(planned[2].payload),
        DateTime(2026, 9, 11),
      );
    });

    test('rubbish opens the app normally rather than failing', () {
      expect(NotificationPlanner.dateFromPayload(null), isNull);
      expect(NotificationPlanner.dateFromPayload('not a date'), isNull);
      expect(NotificationPlanner.dateFromPayload(''), isNull);
    });
  });

  group('stored preferences', () {
    test('survive a round trip', () {
      const prefs = NotificationPrefs(
        daily: true,
        poya: true,
        hour: 7,
        minute: 5,
      );

      expect(NotificationPrefs.fromJson(prefs.toJson()), prefs);
    });

    test('a corrupt time is clamped rather than thrown', () {
      // A hand-edited or corrupt value would otherwise blow up inside the
      // scheduler, a long way from the cause.
      final prefs = NotificationPrefs.fromJson({
        'daily': true,
        'hour': 99,
        'minute': -4,
      });

      expect(prefs.hour, 23);
      expect(prefs.minute, 0);
    });

    test('an empty record is everything off', () {
      const prefs = NotificationPrefs();

      expect(prefs.anyEnabled, isFalse);
      expect(NotificationPrefs.fromJson(const {}), prefs);
    });
  });

  group('the festival reminder (KAN-63)', () {
    final newYear = DateTime(2026, 4, 14);

    test('fires the evening before, like the poya one', () {
      final planned = plan(
        now: DateTime(2026, 4, 10, 9),
        prefs: const NotificationPrefs(festival: true),
        festivals: [ingress(newYear, 'Sinhala and Tamil New Year')],
      );

      expect(planned, hasLength(1));
      expect(planned.single.at, DateTime(2026, 4, 13, 18));
      expect(planned.single.body, contains('Sinhala and Tamil New Year'));
    });

    test('says nothing about a public holiday', () {
      // Christmas, Independence Day, May Day and Good Friday are all in the
      // calendar. The phone's own calendar already has them and this app has
      // nothing to add, so a notification would be a second reminder of a date
      // nobody asked us about.
      final planned = plan(
        now: DateTime(2026, 12, 20, 9),
        prefs: const NotificationPrefs(festival: true),
        festivals: [
          Festival(
            date: DateTime(2026, 12, 25),
            name: 'Christmas Day',
            kind: FestivalKind.fixed,
          ),
        ],
      );

      expect(planned, isEmpty);
    });

    test('the gazetted day before the New Year is not its own reminder', () {
      // It shares FestivalKind.solarIngress with the New Year but carries no
      // exact moment, because it is a holiday marker rather than an event.
      // Without that distinction one occasion would arrive as two
      // notifications on consecutive evenings.
      final planned = plan(
        now: DateTime(2026, 4, 10, 9),
        prefs: const NotificationPrefs(festival: true),
        festivals: [
          ingress(newYear, 'Sinhala and Tamil New Year'),
          Festival(
            date: DateTime(2026, 4, 13),
            name: 'Day before Sinhala and Tamil New Year',
            kind: FestivalKind.solarIngress,
          ),
        ],
      );

      expect(planned, hasLength(1));
      expect(planned.single.body, contains('Sinhala and Tamil New Year'));
      expect(planned.single.body, isNot(contains('Day before')));
    });

    test('a festival that has already gone is not scheduled', () {
      final planned = plan(
        now: DateTime(2026, 4, 15, 9),
        prefs: const NotificationPrefs(festival: true),
        festivals: [ingress(newYear, 'Sinhala and Tamil New Year')],
      );

      expect(planned, isEmpty);
    });

    test('nothing is scheduled when the switch is off', () {
      final planned = plan(
        now: DateTime(2026, 4, 10, 9),
        prefs: const NotificationPrefs(daily: true),
        festivals: [ingress(newYear, 'Sinhala and Tamil New Year')],
      );

      expect(planned.every((n) => n.title != 'Festival tomorrow'), isTrue);
    });
  });

  group('the daśā reminder (KAN-63)', () {
    test('fires on the day the period turns over', () {
      // Not the evening before. A daśā change is about the day itself, so it
      // arrives with the morning reminder rather than as a warning.
      final planned = plan(
        now: DateTime(2026, 9, 9, 5),
        prefs: const NotificationPrefs(dasha: true, hour: 6, minute: 30),
        dashaPeriods: [
          period(DashaLevel.maha, Graha.jupiter, DateTime(2026, 9, 12)),
        ],
      );

      expect(planned, hasLength(1));
      expect(planned.single.at, DateTime(2026, 9, 12, 6, 30));
      expect(planned.single.body, 'Jupiter mahādaśā');
    });

    test('a mahādaśā turnover is announced as the mahādaśā', () {
      // Every mahādaśā begins at the same instant as its own first antardaśā,
      // so both match the same day. Only one notification is produced either
      // way — the planner picks at most one period per day — but without the
      // preference it picks whichever came first in the list, and being told
      // an antardaśā started on the day a mahādaśā did buries the bigger
      // event under the smaller one.
      final planned = plan(
        now: DateTime(2026, 9, 9, 5),
        prefs: const NotificationPrefs(dasha: true),
        dashaPeriods: [
          period(DashaLevel.antara, Graha.jupiter, DateTime(2026, 9, 12)),
          period(DashaLevel.maha, Graha.jupiter, DateTime(2026, 9, 12)),
        ],
      );

      expect(planned, hasLength(1));
      expect(planned.single.body, 'Jupiter mahādaśā');
    });

    test('an antardaśā on its own still fires', () {
      final planned = plan(
        now: DateTime(2026, 9, 9, 5),
        prefs: const NotificationPrefs(dasha: true),
        dashaPeriods: [
          period(DashaLevel.antara, Graha.venus, DateTime(2026, 9, 11)),
        ],
      );

      expect(planned.single.body, 'Venus antardaśā');
    });

    test('a change beyond the horizon waits for a later launch', () {
      // The seven-day window is the constraint the ticket flagged. It is fine
      // because the app is opened daily and re-plans every time — but a change
      // three weeks out genuinely is not scheduled yet, and that is worth
      // being explicit about rather than assumed.
      final planned = plan(
        now: DateTime(2026, 9, 9, 5),
        prefs: const NotificationPrefs(dasha: true),
        dashaPeriods: [
          period(DashaLevel.maha, Graha.saturn, DateTime(2026, 10, 1)),
        ],
      );

      expect(planned, isEmpty);
    });

    test('a period that began in the past is not announced', () {
      final planned = plan(
        now: DateTime(2026, 9, 9, 5),
        prefs: const NotificationPrefs(dasha: true),
        dashaPeriods: [
          period(DashaLevel.maha, Graha.mars, DateTime(2024, 3, 3)),
        ],
      );

      expect(planned, isEmpty);
    });

    test('nothing is scheduled when the switch is off', () {
      final planned = plan(
        now: DateTime(2026, 9, 9, 5),
        prefs: const NotificationPrefs(daily: true),
        dashaPeriods: [
          period(DashaLevel.maha, Graha.jupiter, DateTime(2026, 9, 12)),
        ],
      );

      expect(planned.every((n) => n.title != 'A new daśā'), isTrue);
    });
  });

  group('the four kinds together', () {
    test('every kind gets its own id range', () {
      // Ids are what the plugin cancels and replaces by. Two kinds sharing one
      // would mean a festival reminder silently overwriting that day's nekath.
      final planned = plan(
        now: DateTime(2026, 4, 13, 5),
        prefs: const NotificationPrefs(
          daily: true,
          poya: true,
          festival: true,
          dasha: true,
        ),
        poyaDays: [
          PoyaDay(
            date: DateTime(2026, 4, 14),
            month: PoyaMonth.bak,
            isAdhi: false,
            fullMoon: DateTime(2026, 4, 14, 3, 0),
          ),
        ],
        festivals: [ingress(DateTime(2026, 4, 14), 'New Year')],
        dashaPeriods: [
          period(DashaLevel.maha, Graha.jupiter, DateTime(2026, 4, 14)),
        ],
        horizonDays: 2,
      );

      final ids = planned.map((n) => n.id).toList();
      expect(ids.toSet(), hasLength(ids.length), reason: 'ids must be unique');
      expect(planned.map((n) => n.title).toSet(), hasLength(4));
    });
  });
}
