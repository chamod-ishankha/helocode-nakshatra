import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/features/onboarding/domain/birth_wheels.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

/// The date and time wheels' arithmetic (KAN-82).
///
/// Every case here is one where the wrong answer looks right: a wheel that
/// reads "31 February" and saves the 3rd of March, a "12:30 PM" saved as half
/// past midnight, a Sri Lankan birth in 1998 read at +5:30.
void main() {
  setUpAll(tzdata.initializeTimeZones);

  final today = DateTime(2026, 10, 5);

  group('days in a month', () {
    test('follows the month', () {
      expect(BirthWheels.daysInMonth(1995, 1), 31);
      expect(BirthWheels.daysInMonth(1995, 4), 30);
      expect(BirthWheels.daysInMonth(1995, 12), 31);
    });

    test('follows the leap-year rule, including the century exceptions', () {
      expect(BirthWheels.daysInMonth(1996, 2), 29, reason: 'divisible by 4');
      expect(BirthWheels.daysInMonth(1995, 2), 28);
      expect(BirthWheels.daysInMonth(1900, 2), 28, reason: 'century, not 400');
      expect(BirthWheels.daysInMonth(2000, 2), 29, reason: 'divisible by 400');
    });
  });

  group('settling three wheels into a date', () {
    test('holds the day to the month instead of rolling over', () {
      // DateTime(1995, 2, 31) is 3 March. The wheels must never save that.
      expect(
        BirthWheels.settle(year: 1995, month: 2, day: 31, today: today),
        DateTime(1995, 2, 28),
      );
      expect(
        BirthWheels.settle(year: 1996, month: 2, day: 31, today: today),
        DateTime(1996, 2, 29),
      );
      expect(
        BirthWheels.settle(year: 1995, month: 4, day: 31, today: today),
        DateTime(1995, 4, 30),
      );
    });

    test('a date that exists is left alone', () {
      expect(
        BirthWheels.settle(year: 1995, month: 9, day: 8, today: today),
        DateTime(1995, 9, 8),
      );
    });

    test('never lands in the future', () {
      expect(
        BirthWheels.settle(year: 2026, month: 12, day: 25, today: today),
        DateTime(2026, 10, 5),
      );
      expect(
        BirthWheels.settle(year: 2026, month: 10, day: 30, today: today),
        DateTime(2026, 10, 5),
      );
      expect(
        BirthWheels.settle(
          year: 2031,
          month: 1,
          day: 1,
          today: today,
        ).isAfter(today),
        isFalse,
      );
    });

    test('never lands before the ephemeris floor', () {
      expect(
        BirthWheels.settle(year: 1850, month: 6, day: 1, today: today),
        DateTime(1900, 6, 1),
      );
    });
  });

  group('what the wheels offer', () {
    test('years run from the floor to this year, oldest first', () {
      final years = BirthWheels.years(today);
      expect(years.first, 1900);
      expect(years.last, 2026);
      expect(years.length, 2026 - 1900 + 1);
    });

    test('this year offers no month or day after today', () {
      expect(BirthWheels.monthCount(2026, today), 10);
      expect(BirthWheels.monthCount(2025, today), 12);
      expect(BirthWheels.dayCount(2026, 10, today), 5);
      expect(BirthWheels.dayCount(2026, 9, today), 30);
    });
  });

  group('the 12-hour wheels', () {
    test('12 AM is midnight and 12 PM is noon', () {
      expect(
        BirthWheels.timeOf(hour12: 12, minute: 0, pm: false),
        Duration.zero,
      );
      expect(
        BirthWheels.timeOf(hour12: 12, minute: 30, pm: true),
        const Duration(hours: 12, minutes: 30),
      );
    });

    test('every time of day survives a round trip', () {
      // The edit flow puts the saved time back on the wheels; any minute that
      // came back different would be silently re-saved wrong.
      for (var minutes = 0; minutes < 24 * 60; minutes++) {
        final time = Duration(minutes: minutes);
        final w = BirthWheels.wheelsFor(time);
        expect(w.hour12, inInclusiveRange(1, 12));
        expect(
          BirthWheels.timeOf(hour12: w.hour12, minute: w.minute, pm: w.pm),
          time,
        );
      }
    });
  });

  group('the offset a place had on the birth date', () {
    Duration? colombo(int y, int m, int d) => BirthWheels.offsetAt(
      'Asia/Colombo',
      DateTime(y, m, d),
      const Duration(hours: 12),
    );

    test('Sri Lanka outside 1996-2006 is +5:30', () {
      expect(colombo(1995, 9, 8), const Duration(hours: 5, minutes: 30));
      expect(colombo(2010, 1, 1), const Duration(hours: 5, minutes: 30));
    });

    test('Sri Lanka inside 1996-2006 is not', () {
      // The reason the app never uses a fixed offset.
      expect(colombo(1996, 7, 1), const Duration(hours: 6, minutes: 30));
      expect(colombo(1999, 1, 1), const Duration(hours: 6));
    });

    test('an unknown zone gives nothing rather than a guess', () {
      expect(
        BirthWheels.offsetAt('Not/AZone', DateTime(1995), Duration.zero),
        isNull,
      );
    });
  });

  test('offset labels', () {
    expect(
      BirthWheels.offsetLabel(const Duration(hours: 5, minutes: 30)),
      'UTC+5:30',
    );
    expect(BirthWheels.offsetLabel(const Duration(hours: 6)), 'UTC+6');
    expect(BirthWheels.offsetLabel(const Duration(hours: -3)), 'UTC−3');
    expect(
      BirthWheels.offsetLabel(const Duration(hours: -9, minutes: -30)),
      'UTC−9:30',
    );
    expect(BirthWheels.offsetLabel(Duration.zero), 'UTC');
  });
}
