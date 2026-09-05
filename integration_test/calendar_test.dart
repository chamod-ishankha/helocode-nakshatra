import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nakshatra/core/astro/calendar_models.dart';
import 'package:nakshatra/core/astro/ephemeris.dart';
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

    test('the full moon falls on the day it is assigned to', () {
      for (final p in SriLankanCalendar.poyaDaysIn(2026)) {
        expect(p.fullMoon.year, p.date.year, reason: p.name);
        expect(p.fullMoon.month, p.date.month, reason: p.name);
        expect(p.fullMoon.day, p.date.day, reason: p.name);
      }
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

    test('May 2026 is a doubled month, so an Adhi poya is inserted', () {
      // 2026 has full moons on both 1 and 31 May. Which of the pair Sri Lanka
      // names "Vesak" and which "Adhi Vesak" is a calendrical convention, not
      // something astronomy decides — so assert only the structure here. The
      // naming is flagged for litha verification in KAN-24.
      final may = SriLankanCalendar.poyaDaysIn(
        2026,
      ).where((p) => p.date.month == 5).toList();

      expect(may.length, 2, reason: 'May 2026 has two full moons');
      expect(may.first.date.day, 1);
      expect(may.last.date.day, 31);
      expect(may.where((p) => p.isAdhi).length, 1);
      expect(may.first.isAdhi, isTrue, reason: 'the earlier one takes Adhi');
      expect(may.every((p) => p.month == PoyaMonth.vesak), isTrue);
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

    test('an Adhi poya is only ever the first of a doubled month', () {
      for (final year in [2024, 2025, 2026, 2027, 2028]) {
        final poyas = SriLankanCalendar.poyaDaysIn(year);
        final adhi = poyas.where((p) => p.isAdhi);
        for (final a in adhi) {
          final sameMonth = poyas.where((p) => p.date.month == a.date.month);
          expect(sameMonth.length, 2, reason: '${a.name} in $year');
          expect(sameMonth.first.date, a.date);
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
