import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nakshatra/core/astro/ephemeris.dart';
import 'package:nakshatra/core/astro/nekath.dart';
import 'package:nakshatra/core/astro/panchanga.dart';
import 'package:nakshatra/core/astro/panchanga_models.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

/// Panchanga and nekath against the real ephemeris (KAN-20, KAN-21).
///
/// The segment arithmetic is unit-tested in test/; this covers the parts that
/// need the native library — sunrise and sunset, and the lunar elements.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const colombo = 'Asia/Colombo';
  const lat = 6.9271;
  const lon = 79.8612;

  setUpAll(() async {
    await Ephemeris.initialize();
    tzdata.initializeTimeZones();
  });

  Panchanga on(int y, int m, int d) => Panchangam.forDate(
    date: DateTime(y, m, d),
    zoneName: colombo,
    latitude: lat,
    longitude: lon,
  );

  group('solar times', () {
    test('Colombo sunrise and sunset are plausible', () {
      final p = on(2026, 3, 21);
      // Colombo is near the equator, so sunrise sits around 06:00-06:30 and
      // day length barely moves through the year.
      expect(p.sunrise.hour, inInclusiveRange(5, 7));
      expect(p.sunset.hour, inInclusiveRange(17, 19));
      expect(p.sunrise.isBefore(p.sunset), isTrue);
    });

    test('day length near the equator stays close to 12 hours', () {
      for (final month in [1, 3, 6, 9, 12]) {
        final p = on(2026, month, 15);
        final hours = p.dayLength.inMinutes / 60;
        expect(
          hours,
          inInclusiveRange(11.5, 12.75),
          reason: 'month $month gave $hours hours',
        );
      }
    });

    test('sunrise and sunset land on the requested date', () {
      final p = on(2026, 6, 15);
      expect(p.sunrise.day, 15);
      expect(p.sunset.day, 15);
    });

    test('day length varies measurably across the year', () {
      // Small near the equator, but not zero — this is what makes rahu kalaya
      // drift, and a tabulated version wrong.
      final june = on(2026, 6, 21).dayLength;
      final december = on(2026, 12, 21).dayLength;
      expect((june - december).inMinutes.abs(), greaterThan(20));
    });
  });

  group('vara', () {
    test('matches the calendar weekday for a daytime date', () {
      // 1 Jan 2026 is a Thursday.
      expect(on(2026, 1, 1).vara, Vara.guru);
      // 5 Sep 2026 is a Saturday.
      expect(on(2026, 9, 5).vara, Vara.shani);
    });

    test('advances by one each day across a week', () {
      var previous = on(2026, 4, 6).vara.index;
      for (var d = 7; d <= 12; d++) {
        final current = on(2026, 4, d).vara.index;
        expect(current, (previous + 1) % 7, reason: 'April $d');
        previous = current;
      }
    });
  });

  group('lunar elements', () {
    test('all five limbs resolve with end times', () {
      final p = on(2026, 5, 20);
      expect(p.tithi.endsAt, isNotNull);
      expect(p.nakshatra.endsAt, isNotNull);
      expect(p.yoga.endsAt, isNotNull);
      expect(p.karana.endsAt, isNotNull);

      // An element always ends after the sunrise it was measured at, and never
      // more than about two days later.
      for (final end in [
        p.tithi.endsAt!,
        p.nakshatra.endsAt!,
        p.yoga.endsAt!,
        p.karana.endsAt!,
      ]) {
        expect(end.isAfter(p.sunrise), isTrue);
        expect(end.difference(p.sunrise).inHours, lessThan(48));
      }
    });

    test('karana ends no later than its tithi', () {
      // A karana is half a tithi, so it must always resolve first or together.
      final p = on(2026, 5, 20);
      expect(p.karana.endsAt!.isAfter(p.tithi.endsAt!), isFalse);
    });

    test('a full moon falls on Purnima in the waxing half', () {
      // Vesak poya 2026 falls on 1 May. Poya days are full moons, which are by
      // definition the fifteenth tithi of the waxing fortnight.
      final p = on(2026, 5, 1);
      expect(p.paksha, Paksha.shukla);
      expect(p.tithi.value, Tithi.purnimaAmavasya);
    });

    test('tithi advances over consecutive days', () {
      final a = on(2026, 5, 10).tithi.value.index;
      final b = on(2026, 5, 11).tithi.value.index;
      expect(a, isNot(b));
    });

    test('paksha alternates roughly every fortnight', () {
      final seen = <Paksha>{};
      for (var d = 1; d <= 28; d++) {
        seen.add(on(2026, 5, d).paksha);
      }
      expect(seen.length, 2, reason: 'a month must contain both halves');
    });
  });

  group('nekath periods on real days', () {
    test('rahu kalaya sits inside real daylight', () {
      for (var d = 1; d <= 7; d++) {
        final p = on(2026, 7, d);
        final w = Nekath.rahuKalaya(p);
        expect(w.start.isBefore(p.sunrise), isFalse, reason: 'July $d');
        expect(w.end.isAfter(p.sunset), isFalse, reason: 'July $d');
      }
    });

    test('its clock time shifts between June and December', () {
      // The concrete reason a hardcoded table is wrong. Same weekday, same
      // place, different time of year.
      Panchanga mondayIn(int month) {
        for (var d = 1; d <= 28; d++) {
          final p = on(2026, month, d);
          if (p.vara == Vara.soma) return p;
        }
        throw StateError('no Monday found');
      }

      final june = Nekath.rahuKalaya(mondayIn(6));
      final december = Nekath.rahuKalaya(mondayIn(12));

      final juneMinutes = june.start.hour * 60 + june.start.minute;
      final decMinutes = december.start.hour * 60 + december.start.minute;
      expect(
        (juneMinutes - decMinutes).abs(),
        greaterThan(5),
        reason: 'rahu kalaya must move with the seasons',
      );
    });

    test('auspicious and inauspicious windows tile the whole day', () {
      final p = on(2026, 8, 12);
      final blocked = Nekath.inauspicious(
        p,
      ).fold(Duration.zero, (a, w) => a + w.duration);
      final free = Nekath.auspiciousWindows(
        p,
      ).fold(Duration.zero, (a, w) => a + w.duration);
      expect((blocked + free - p.dayLength).inSeconds.abs(), lessThan(2));
    });
  });
}
