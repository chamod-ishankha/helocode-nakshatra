import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nakshatra/core/astro/calendar_models.dart';
import 'package:nakshatra/core/astro/ephemeris.dart';
import 'package:nakshatra/core/astro/official_poya_days.dart';
import 'package:nakshatra/core/astro/sri_lankan_calendar.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

/// Poya days and festivals (KAN-23).
///
/// Checked against the published Sri Lankan calendar where possible, rather
/// than only against internal consistency.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Ephemeris.initialize();
    tzdata.initializeTimeZones();
  });

  group('poya days', () {
    test('a year has twelve or thirteen', () {
      // Twelve normally; thirteen when an intercalary Adhi poya falls.
      for (final year in [2024, 2025, 2026, 2027]) {
        final poyas = SriLankanCalendar.poyaDaysIn(year);
        expect(
          poyas.length,
          inInclusiveRange(12, 13),
          reason: '$year produced ${poyas.length}',
        );
      }
    });

    test('every one falls in the year requested', () {
      for (final p in SriLankanCalendar.poyaDaysIn(2026)) {
        expect(p.date.year, 2026, reason: p.name);
      }
    });

    test('they are in date order and roughly a month apart', () {
      final poyas = SriLankanCalendar.poyaDaysIn(2026);
      for (var i = 0; i + 1 < poyas.length; i++) {
        final gap = poyas[i + 1].date.difference(poyas[i].date).inDays;
        expect(
          gap,
          inInclusiveRange(28, 31),
          reason: 'gap between ${poyas[i].name} and ${poyas[i + 1].name}',
        );
      }
    });

    test('the poya is the day of the full moon or the day before', () {
      // Kept on the day of pūrṇimā, the tithi that ends at the full moon, so
      // it can be the day before a full moon early in the morning — never
      // later, and never two days off (KAN-96).
      for (final year in [2024, 2025, 2026, 2027, 2028]) {
        for (final p in SriLankanCalendar.poyaDaysIn(year)) {
          final fullDay = DateTime(
            p.fullMoon.year,
            p.fullMoon.month,
            p.fullMoon.day,
          );
          final lag = fullDay.difference(p.date).inDays;
          expect(lag, inInclusiveRange(0, 1), reason: '${p.name} ${p.date}');
        }
      }
    });

    test('Vap 2026 is Sunday 25 October', () {
      // The reported case: the Moon is full at 9:41 on the 26th, and the
      // calendar keeps the poya on the 25th.
      final vap = SriLankanCalendar.poyaDaysIn(
        2026,
      ).singleWhere((p) => p.month == PoyaMonth.vap);
      expect(vap.date, DateTime(2026, 10, 25));
      expect(vap.fullMoon.day, 26);
    });

    test('every published poya day is in the calendar, by name', () {
      for (final MapEntry(key: date, value: official)
          in officialPoyaDays.entries) {
        final day = DateTime.parse(date);
        final match = SriLankanCalendar.poyaDaysIn(
          day.year,
        ).where((p) => p.date == day).toList();
        expect(match, hasLength(1), reason: date);
        expect(match.single.month, official.month, reason: date);
        expect(match.single.isAdhi, official.isAdhi, reason: date);
      }
    });

    test('the rule alone matches all but two published days and names', () {
      // Measured when the rule was chosen: 59 of 61 on both counts, where
      // "the day of the full moon" managed 21. The two days it misses are a
      // tithi beginning a minute after sunset and one the almanac rounds the
      // other way; the two names are 2023's Adhi Esala, which Sri Lanka kept a
      // month earlier than the astronomy puts it. This guards against the
      // rule drifting, not a claim that it is the almanac.
      var days = 0, names = 0;
      for (final MapEntry(key: date, value: official)
          in officialPoyaDays.entries) {
        final day = DateTime.parse(date);
        final computed = SriLankanCalendar.poyaDaysIn(
          day.year,
          useOfficial: false,
        );
        if (computed.any((p) => p.date == day)) days++;
        final near = computed.where(
          (p) => p.date.difference(day).inDays.abs() <= 1,
        );
        if (near.any(
          (p) => p.month == official.month && p.isAdhi == official.isAdhi,
        )) {
          names++;
        }
      }
      expect(days, greaterThanOrEqualTo(officialPoyaDays.length - 2));
      expect(names, greaterThanOrEqualTo(officialPoyaDays.length - 2));
    });

    test('the Moon really is opposite the Sun at that instant', () {
      // The defining property: elongation 180 degrees. If this drifted the
      // "full moon" would be nothing of the sort.
      final poya = SriLankanCalendar.poyaDaysIn(2026).first;
      final chart = Ephemeris.computeChart(
        localWallClock: DateTime(
          poya.fullMoon.year,
          poya.fullMoon.month,
          poya.fullMoon.day,
          poya.fullMoon.hour,
          poya.fullMoon.minute,
        ),
        zoneName: 'Asia/Colombo',
        latitude: 6.9271,
        longitude: 79.8612,
      ).valueOrNull!;

      final sun = chart.positions.values.firstWhere((p) => p.graha.en == 'Sun');
      final moon = chart.positions.values.firstWhere(
        (p) => p.graha.en == 'Moon',
      );
      final elongation = (moon.longitude - sun.longitude + 360) % 360;
      expect(elongation, closeTo(180, 0.05));
    });

    test('2026 has Adhi Poson between Vesak and Poson', () {
      // The Sun enters no sign between the new moons of 16 May and 15 June,
      // so that lunar month is intercalary. It used to be decided by the
      // Gregorian month, which named 1 May "Adhi Vesak" and 31 May "Vesak".
      final poyas = SriLankanCalendar.poyaDaysIn(2026);
      PoyaDay on(int month, int day) =>
          poyas.singleWhere((p) => p.date == DateTime(2026, month, day));

      expect(on(5, 1).month, PoyaMonth.vesak);
      expect(on(5, 1).isAdhi, isFalse);
      expect(on(5, 30).month, PoyaMonth.poson);
      expect(on(5, 30).isAdhi, isTrue);
      expect(on(6, 29).month, PoyaMonth.poson);
      expect(on(6, 29).isAdhi, isFalse);
    });

    test('a normal month yields exactly one poya with no Adhi', () {
      final june = SriLankanCalendar.poyaDaysIn(
        2026,
      ).where((p) => p.date.month == 6).toList();
      expect(june.length, 1);
      expect(june.single.isAdhi, isFalse);
      expect(june.single.name, 'Poson Poya');
    });

    test('each poya carries its traditional name and significance', () {
      for (final p in SriLankanCalendar.poyaDaysIn(2026)) {
        expect(p.name, contains('Poya'));
        expect(p.si, isNotNull);
        expect(p.note, isNotEmpty);
      }
    });

    test('nextPoya never returns a past date', () {
      final from = DateTime(2026, 6, 15);
      final next = SriLankanCalendar.nextPoya(from)!;
      expect(next.date.isBefore(DateTime(2026, 6, 15)), isFalse);
      expect(next.daysFrom(from), greaterThanOrEqualTo(0));
    });

    test('an Adhi poya is followed by the regular one of its name', () {
      for (final year in [2024, 2025, 2026, 2027, 2028]) {
        final poyas = SriLankanCalendar.poyaDaysIn(year);
        for (var i = 0; i + 1 < poyas.length; i++) {
          if (!poyas[i].isAdhi) continue;
          expect(poyas[i + 1].month, poyas[i].month, reason: '$year');
          expect(poyas[i + 1].isAdhi, isFalse, reason: '$year');
        }
      }
    });
  });

  group('solar ingresses', () {
    test('Sinhala and Tamil New Year lands in mid-April', () {
      for (final year in [2024, 2025, 2026, 2027]) {
        final ny = SriLankanCalendar.sinhalaNewYear(year);
        expect(ny.month, 4, reason: '$year');
        expect(ny.day, inInclusiveRange(13, 15), reason: '$year');
      }
    });

    test('Thai Pongal lands in mid-January', () {
      for (final year in [2025, 2026, 2027]) {
        final tp = SriLankanCalendar.thaiPongal(year);
        expect(tp.month, 1, reason: '$year');
        expect(tp.day, inInclusiveRange(13, 16), reason: '$year');
      }
    });

    test('the Sun really is at the sign boundary at that instant', () {
      final ny = SriLankanCalendar.sinhalaNewYear(2026);
      final chart = Ephemeris.computeChart(
        localWallClock: DateTime(ny.year, ny.month, ny.day, ny.hour, ny.minute),
        zoneName: 'Asia/Colombo',
        latitude: 6.9271,
        longitude: 79.8612,
      ).valueOrNull!;

      final sun = chart.positions.values.firstWhere((p) => p.graha.en == 'Sun');
      // Either side of 0 degrees Aries, within a minute of arc.
      final fromBoundary = sun.longitude > 180
          ? 360 - sun.longitude
          : sun.longitude;
      expect(fromBoundary, lessThan(0.02));
    });
  });

  group('festival list', () {
    test('is sorted and covers the whole year', () {
      final all = SriLankanCalendar.festivalsIn(2026);
      expect(all.length, greaterThan(14));
      for (var i = 0; i + 1 < all.length; i++) {
        expect(all[i].date.isAfter(all[i + 1].date), isFalse);
      }
    });

    test('includes the New Year, Pongal and Christmas', () {
      final names = SriLankanCalendar.festivalsIn(2026).map((f) => f.name);
      expect(names, contains('Sinhala and Tamil New Year'));
      expect(names, contains('Thai Pongal'));
      expect(names, contains('Christmas Day'));
    });

    test('festivals we cannot compute are declared, not silently dropped', () {
      // Deepavali follows regional convention and Eid depends on moon
      // sighting. A confidently wrong religious date is worse than none, so
      // the omission is explicit and explained.
      expect(
        SriLankanCalendar.unsupportedFestivals.keys,
        contains('Deepavali'),
      );
      expect(
        SriLankanCalendar.unsupportedFestivals.keys,
        contains('Eid al-Fitr'),
      );
      for (final reason in SriLankanCalendar.unsupportedFestivals.values) {
        expect(reason, isNotEmpty);
      }
    });

    test('nextFestival crosses a year boundary', () {
      final next = SriLankanCalendar.nextFestival(DateTime(2026, 12, 28))!;
      expect(next.date.year, 2027);
    });
  });
}
