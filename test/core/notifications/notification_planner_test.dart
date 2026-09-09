import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/astro/calendar_models.dart';
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

  List<ScheduledNotification> plan({
    required DateTime now,
    required NotificationPrefs prefs,
    TimeWindow? Function(DateTime)? rahuFor,
    List<PoyaDay> poyaDays = const [],
    int? horizonDays,
  }) => NotificationPlanner.plan(
    now: now,
    prefs: prefs,
    strings: strings,
    rahuFor: rahuFor ?? rahuOn,
    poyaDays: poyaDays,
    poyaName: (p) => p.name,
    formatTime: (t) => '${t.hour}:${t.minute.toString().padLeft(2, '0')}',
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
}
