import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/astro/nekath.dart';
import 'package:nakshatra/core/astro/panchanga_models.dart';

/// Segment arithmetic for the inauspicious periods.
///
/// Pure logic against a synthetic Panchanga, so it runs in CI without the
/// ephemeris. The astronomical side — that sunrise and sunset are themselves
/// correct — is covered on device.
void main() {
  Panchanga dayOf(
    Vara vara, {
    required DateTime sunrise,
    required DateTime sunset,
  }) => Panchanga(
    date: DateTime(2026, 1, 1),
    vara: vara,
    tithi: const PanchangaElement(value: Tithi.pratipada, endsAt: null),
    paksha: Paksha.shukla,
    nakshatra: const PanchangaElement(value: 'Ashwini', endsAt: null),
    yoga: const PanchangaElement(value: Yoga.vishkambha, endsAt: null),
    karana: const PanchangaElement(value: Karana.bava, endsAt: null),
    sunrise: sunrise,
    sunset: sunset,
  );

  // A clean 12-hour day makes each eighth exactly 90 minutes, so expected
  // times can be reasoned about by hand.
  final sunrise = DateTime(2026, 1, 1, 6, 0);
  final sunset = DateTime(2026, 1, 1, 18, 0);

  group('rahu kalaya', () {
    test('is 90 minutes when the day is 12 hours', () {
      final w = Nekath.rahuKalaya(
        dayOf(Vara.soma, sunrise: sunrise, sunset: sunset),
      );
      expect(w.duration, const Duration(minutes: 90));
    });

    test('Monday falls in the second segment: 07:30-09:00', () {
      final w = Nekath.rahuKalaya(
        dayOf(Vara.soma, sunrise: sunrise, sunset: sunset),
      );
      expect(w.start, DateTime(2026, 1, 1, 7, 30));
      expect(w.end, DateTime(2026, 1, 1, 9, 0));
    });

    test('Sunday falls in the last segment, ending at sunset', () {
      final w = Nekath.rahuKalaya(
        dayOf(Vara.ravi, sunrise: sunrise, sunset: sunset),
      );
      expect(w.start, DateTime(2026, 1, 1, 16, 30));
      expect(w.end, sunset);
    });

    test('every weekday maps to a distinct segment', () {
      final starts = {
        for (final v in Vara.values)
          v: Nekath.rahuKalaya(
            dayOf(v, sunrise: sunrise, sunset: sunset),
          ).start,
      };
      expect(starts.values.toSet().length, 7);
    });

    test('never falls outside daylight', () {
      for (final v in Vara.values) {
        final w = Nekath.rahuKalaya(dayOf(v, sunrise: sunrise, sunset: sunset));
        expect(w.start.isBefore(sunrise), isFalse, reason: v.en);
        expect(w.end.isAfter(sunset), isFalse, reason: v.en);
      }
    });
  });

  test('a longer day produces a longer, later rahu kalaya', () {
    // The whole reason these are computed rather than tabulated. A fixed clock
    // table would give the same answer for both of these days.
    final shortDay = dayOf(
      Vara.soma,
      sunrise: DateTime(2026, 1, 1, 6, 30),
      sunset: DateTime(2026, 1, 1, 18, 0),
    );
    final longDay = dayOf(
      Vara.soma,
      sunrise: DateTime(2026, 6, 1, 5, 50),
      sunset: DateTime(2026, 6, 1, 18, 30),
    );

    final a = Nekath.rahuKalaya(shortDay);
    final b = Nekath.rahuKalaya(longDay);

    expect(b.duration, greaterThan(a.duration));
    expect(
      Duration(minutes: a.start.hour * 60 + a.start.minute),
      isNot(Duration(minutes: b.start.hour * 60 + b.start.minute)),
    );
  });

  group('the three periods together', () {
    test('never overlap on any weekday', () {
      for (final v in Vara.values) {
        final windows = Nekath.inauspicious(
          dayOf(v, sunrise: sunrise, sunset: sunset),
        );
        expect(windows.length, 3, reason: v.en);
        for (var i = 0; i + 1 < windows.length; i++) {
          expect(
            windows[i].end.isAfter(windows[i + 1].start),
            isFalse,
            reason: '${v.en}: ${windows[i]} overlaps ${windows[i + 1]}',
          );
        }
      }
    });

    test('are returned in chronological order', () {
      for (final v in Vara.values) {
        final w = Nekath.inauspicious(
          dayOf(v, sunrise: sunrise, sunset: sunset),
        );
        expect(w[0].start.isAfter(w[1].start), isFalse, reason: v.en);
        expect(w[1].start.isAfter(w[2].start), isFalse, reason: v.en);
      }
    });

    test('cover exactly three eighths of the day', () {
      final total = Nekath.inauspicious(
        dayOf(Vara.guru, sunrise: sunrise, sunset: sunset),
      ).fold(Duration.zero, (a, w) => a + w.duration);
      expect(total, const Duration(minutes: 270));
    });
  });

  group('auspicious windows', () {
    test('fill the rest of the daylight exactly', () {
      for (final v in Vara.values) {
        final day = dayOf(v, sunrise: sunrise, sunset: sunset);
        final free = Nekath.auspiciousWindows(
          day,
        ).fold(Duration.zero, (a, w) => a + w.duration);
        final blocked = Nekath.inauspicious(
          day,
        ).fold(Duration.zero, (a, w) => a + w.duration);
        expect(free + blocked, day.dayLength, reason: v.en);
      }
    });

    test('none of them overlaps an inauspicious period', () {
      for (final v in Vara.values) {
        final day = dayOf(v, sunrise: sunrise, sunset: sunset);
        for (final good in Nekath.auspiciousWindows(day)) {
          for (final bad in Nekath.inauspicious(day)) {
            final overlaps =
                good.start.isBefore(bad.end) && bad.start.isBefore(good.end);
            expect(overlaps, isFalse, reason: '${v.en}: $good vs $bad');
          }
        }
      }
    });

    test('stay within sunrise and sunset', () {
      for (final v in Vara.values) {
        for (final w in Nekath.auspiciousWindows(
          dayOf(v, sunrise: sunrise, sunset: sunset),
        )) {
          expect(w.start.isBefore(sunrise), isFalse);
          expect(w.end.isAfter(sunset), isFalse);
        }
      }
    });
  });

  group('isInauspicious', () {
    final monday = dayOf(Vara.soma, sunrise: sunrise, sunset: sunset);

    test('is true inside rahu kalaya', () {
      expect(Nekath.isInauspicious(monday, DateTime(2026, 1, 1, 8, 0)), isTrue);
    });

    test('is false just before it starts', () {
      expect(
        Nekath.isInauspicious(monday, DateTime(2026, 1, 1, 7, 29)),
        isFalse,
      );
    });

    test('the end of a window is exclusive', () {
      // A window ending at 09:00 must not still be blocking at 09:00, or two
      // adjacent segments would both claim the same instant.
      final w = Nekath.rahuKalaya(monday);
      expect(w.contains(w.end), isFalse);
      expect(w.contains(w.start), isTrue);
    });
  });

  group('karana', () {
    test('Vishti is the one flagged inauspicious', () {
      for (final k in Karana.values) {
        expect(k.isInauspicious, k == Karana.vishti, reason: k.en);
      }
    });
  });
}
