import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/astro/sri_lankan_calendar.dart';

/// Good Friday, which is a public holiday and therefore a day off.
///
/// Every other date in `SriLankanCalendar` needs Swiss Ephemeris and so cannot
/// be tested off a device — which is why that file has no test file at all,
/// and why the calendar shipped with five festivals in it and nobody noticed.
/// Easter is the exception: pure arithmetic, checkable here, against dates
/// that are a matter of record rather than of astronomy.
void main() {
  /// Western (Gregorian) Easter Sundays.
  const easter = {
    2024: (3, 31),
    2025: (4, 20),
    2026: (4, 5),
    2027: (3, 28),
    2028: (4, 16),
    2029: (4, 1),
    2030: (4, 21),
    // A March 22 Easter is the earliest possible and a good edge case; the
    // next is 2285, so this one is the reachable extreme in the other
    // direction — April 25 is the latest possible.
    2038: (4, 25),
  };

  test('Easter Sunday matches the record', () {
    for (final entry in easter.entries) {
      final (month, day) = entry.value;
      expect(
        SriLankanCalendar.easterSunday(entry.key),
        DateTime(entry.key, month, day),
        reason: 'Easter ${entry.key}',
      );
    }
  });

  test('Easter always falls on a Sunday', () {
    // The algorithm is a chain of integer divisions with no obvious meaning,
    // so a transcription slip produces a plausible-looking wrong date. Every
    // year landing on a Sunday is a property the arithmetic cannot fake.
    for (var year = 1900; year <= 2100; year++) {
      expect(
        SriLankanCalendar.easterSunday(year).weekday,
        DateTime.sunday,
        reason: 'Easter $year is not a Sunday',
      );
    }
  });

  test('Easter stays inside its possible window', () {
    // Never earlier than 22 March, never later than 25 April. Also a property
    // rather than a restated table.
    for (var year = 1900; year <= 2100; year++) {
      final e = SriLankanCalendar.easterSunday(year);
      final earliest = DateTime(year, 3, 22);
      final latest = DateTime(year, 4, 25);

      expect(
        e.isBefore(earliest),
        isFalse,
        reason: 'Easter $year is before 22 March',
      );
      expect(
        e.isAfter(latest),
        isFalse,
        reason: 'Easter $year is after 25 April',
      );
    }
  });

  test('Good Friday is the Friday two days before Easter', () {
    for (var year = 2024; year <= 2030; year++) {
      final friday = SriLankanCalendar.goodFriday(year);

      expect(friday.weekday, DateTime.friday, reason: '$year');
      expect(
        SriLankanCalendar.easterSunday(year).difference(friday).inDays,
        2,
        reason: '$year',
      );
    }
  });

  test('Good Friday 2026 is 3 April', () {
    // The year the app is shipping in, spelled out so a regression names a
    // date a reader can check against a wall calendar.
    expect(SriLankanCalendar.goodFriday(2026), DateTime(2026, 4, 3));
  });
}
