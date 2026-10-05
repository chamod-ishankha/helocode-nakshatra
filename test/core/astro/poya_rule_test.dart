import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/astro/calendar_models.dart';
import 'package:nakshatra/core/astro/official_poya_days.dart';
import 'package:nakshatra/core/astro/poya_rule.dart';

/// Which day a poya is kept on, and its name (KAN-96).
///
/// The moments are real ones, measured on a device with the ephemeris; the
/// rule itself needs none.
void main() {
  group('poyaDayFor', () {
    DateTime day(DateTime start, DateTime full, {int sunsetMinute = 0}) =>
        poyaDayFor(
          purnimaStart: start,
          fullMoon: full,
          // Colombo's sunset moves between 18:00 and 18:35 over the year; the
          // cases below are given theirs.
          sunsetOn: (d) => DateTime(d.year, d.month, d.day, 18, sunsetMinute),
          noonOn: (d) => DateTime(d.year, d.month, d.day, 12),
        );

    test('Vap 2026 is the 25th, not the day of the full moon', () {
      // The reported case. The Moon is full at 9:41 on the 26th; pūrṇimā
      // began at 11:56 the day before and was current at that evening's
      // sunset, which is the day the calendar keeps.
      expect(
        day(DateTime(2026, 10, 25, 11, 56), DateTime(2026, 10, 26, 9, 41)),
        DateTime(2026, 10, 25),
      );
    });

    test('is the later day when the tithi spans two sunsets', () {
      // Esala 2026: pūrṇimā from 18:19 on the 28th to 20:05 on the 29th, and
      // sunset at 18:33 falls inside it on both days. Official: the 29th.
      expect(
        day(
          DateTime(2026, 7, 28, 18, 19),
          DateTime(2026, 7, 29, 20, 5),
          sunsetMinute: 33,
        ),
        DateTime(2026, 7, 29),
      );
    });

    test('falls back to noon when the tithi lies between two sunsets', () {
      // Duruthu 2026: pūrṇimā from 18:53 on the 2nd, after that sunset, to
      // 15:32 on the 3rd, before the next. Official: the 3rd.
      expect(
        day(
          DateTime(2026, 1, 2, 18, 53),
          DateTime(2026, 1, 3, 15, 32),
          sunsetMinute: 7,
        ),
        DateTime(2026, 1, 3),
      );
    });

    test('agrees with the full moon when that evening is in the tithi', () {
      // Vesak 2026: full at 22:53 on 1 May, after that day's sunset.
      expect(
        day(
          DateTime(2026, 4, 30, 21, 13),
          DateTime(2026, 5, 1, 22, 53),
          sunsetMinute: 23,
        ),
        DateTime(2026, 5, 1),
      );
    });
  });

  group('poyaMonthFor', () {
    test('names the month for the sign the Sun enters during it', () {
      // From Mēṣa at one new moon to Vṛṣabha at the next: the month of
      // Vṛṣabha's ingress is Vesak.
      expect(
        poyaMonthFor(sunSignAtNewMoonBefore: 0, sunSignAtNewMoonAfter: 1),
        (month: PoyaMonth.vesak, isAdhi: false),
      );
    });

    test('a month with no ingress is the Adhi one of the month after', () {
      // May 2026: the Sun is in Vṛṣabha at both new moons, so the month
      // between Vesak and Poson is Adhi Poson — not "Adhi Vesak", which the
      // old Gregorian-month rule called 1 May.
      expect(
        poyaMonthFor(sunSignAtNewMoonBefore: 1, sunSignAtNewMoonAfter: 1),
        (month: PoyaMonth.poson, isAdhi: true),
      );
    });

    test('wraps from Mīna to Mēṣa', () {
      expect(
        poyaMonthFor(sunSignAtNewMoonBefore: 11, sunSignAtNewMoonAfter: 0),
        (month: PoyaMonth.bak, isAdhi: false),
      );
      expect(
        poyaMonthFor(sunSignAtNewMoonBefore: 11, sunSignAtNewMoonAfter: 11),
        (month: PoyaMonth.bak, isAdhi: true),
      );
    });
  });

  group('the published poya days', () {
    test('are found from a computed date up to two days away', () {
      final hit = officialPoyaNear(DateTime(2026, 10, 26))!;
      expect(hit.date, DateTime(2026, 10, 25));
      expect(hit.month, PoyaMonth.vap);

      expect(officialPoyaNear(DateTime(2026, 10, 10)), isNull);
    });

    test('name Adhi Poson in 2026 and Adhi Esala in 2023', () {
      expect(officialPoyaDays['2026-05-30'], (
        month: PoyaMonth.poson,
        isAdhi: true,
      ));
      expect(officialPoyaDays['2023-07-03'], (
        month: PoyaMonth.esala,
        isAdhi: true,
      ));
    });

    test('run a month apart, in the order of the lunar year', () {
      // A typo in a date or a name shows up as a gap that is not a month, or
      // a month out of sequence. Gaps of two months are 2023's missing Navam.
      final entries = officialPoyaDays.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      for (var i = 0; i + 1 < entries.length; i++) {
        final a = entries[i], b = entries[i + 1];
        final gap = DateTime.parse(b.key).difference(DateTime.parse(a.key));
        expect(
          gap.inDays,
          anyOf(inInclusiveRange(28, 31), inInclusiveRange(58, 60)),
          reason: '${a.key} → ${b.key}',
        );

        // An Adhi month is followed by the regular one of the same name;
        // otherwise each poya is the month after the last.
        final expected = a.value.isAdhi
            ? a.value.month
            : PoyaMonth.values[(a.value.month.index +
                      (gap.inDays > 40 ? 2 : 1)) %
                  12];
        expect(b.value.month, expected, reason: '${a.key} → ${b.key}');
      }
    });
  });
}
