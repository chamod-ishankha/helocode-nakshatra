import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nakshatra/core/astro/ephemeris.dart';
import 'package:nakshatra/core/astro/models.dart';
import 'package:nakshatra/core/error/result.dart';

/// Integration checks for the Swiss Ephemeris binding (KAN-15).
///
/// These assert that the engine is wired up and internally coherent, and check
/// a handful of astronomical facts that are independently verifiable.
///
/// They are deliberately *not* the accuracy gate. Validating full charts
/// against a trusted reference (Jagannatha Hora, a published chart, a printed
/// litha) is KAN-17 and needs reference data a human has checked.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const colombo = 'Asia/Colombo';
  const colomboLat = 6.9271;
  const colomboLon = 79.8612;

  setUpAll(() async {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    await Ephemeris.initialize();
  });

  test('native library loads', () {
    expect(Ephemeris.isReady, isTrue);
  });

  group('ayanamsa', () {
    test('Lahiri is about 23°51\' at J2000', () {
      // Widely published value: the Lahiri ayanāṃśa was 23°51' (23.85°) on
      // 1 January 2000. A wrong ayanāṃśa — or accidentally staying tropical —
      // would show up here immediately as ~0 or a wildly different figure.
      final result = Ephemeris.computeChart(
        localWallClock: DateTime(2000, 1, 1, 12),
        zoneName: 'UTC',
        latitude: colomboLat,
        longitude: colomboLon,
      );

      final chart = result.valueOrNull;
      expect(chart, isNotNull, reason: result.failureOrNull?.message);
      expect(chart!.ayanamsa, closeTo(23.85, 0.05));
    });

    test('increases with time (precession)', () {
      double ayanamsaFor(int year) => Ephemeris.computeChart(
        localWallClock: DateTime(year, 1, 1, 12),
        zoneName: 'UTC',
        latitude: colomboLat,
        longitude: colomboLon,
      ).valueOrNull!.ayanamsa;

      // Precession advances the ayanāṃśa by roughly 50 arc-seconds a year.
      expect(ayanamsaFor(2026), greaterThan(ayanamsaFor(2000)));
      expect(ayanamsaFor(2026) - ayanamsaFor(2000), closeTo(0.36, 0.05));
    });
  });

  group('sidereal zodiac', () {
    test('Sun sits at the very start of Mesha in mid-April', () {
      // This is the astronomical basis of the Sinhala and Tamil New Year: the
      // Sun's transit into sidereal Aries, which falls around 14 April. If the
      // ayanāṃśa or sidereal flag were wrong, the Sun would land in a
      // different rāśi entirely.
      final chart = Ephemeris.computeChart(
        localWallClock: DateTime(2026, 4, 14, 12),
        zoneName: colombo,
        latitude: colomboLat,
        longitude: colomboLon,
      ).valueOrNull!;

      final sun = chart[Graha.sun];
      expect(sun.rasi, Rasi.mesha);
      expect(
        sun.degreeInRasi,
        lessThan(2.0),
        reason: 'Sun should be barely inside Mesha on 14 April',
      );
    });

    test('Sun is in Meena the day before the transit', () {
      final chart = Ephemeris.computeChart(
        localWallClock: DateTime(2026, 4, 10, 12),
        zoneName: colombo,
        latitude: colomboLat,
        longitude: colomboLon,
      ).valueOrNull!;

      expect(chart[Graha.sun].rasi, Rasi.meena);
    });
  });

  group('chart structure', () {
    late BirthChart chart;

    setUpAll(() {
      chart = Ephemeris.computeChart(
        localWallClock: DateTime(1990, 6, 15, 14, 30),
        zoneName: colombo,
        latitude: colomboLat,
        longitude: colomboLon,
      ).valueOrNull!;
    });

    test('all nine grahas are present', () {
      expect(chart.positions.length, Graha.values.length);
      for (final g in Graha.values) {
        expect(chart.positions[g], isNotNull, reason: '${g.en} missing');
      }
    });

    test('Ketu is exactly opposite Rahu', () {
      final rahu = chart[Graha.rahu].longitude;
      final ketu = chart[Graha.ketu].longitude;
      expect((ketu - rahu + 360) % 360, closeTo(180, 1e-9));
    });

    test('every longitude is normalised to 0-360', () {
      for (final p in chart.positions.values) {
        expect(p.longitude, inInclusiveRange(0, 360), reason: p.graha.en);
      }
      expect(chart.ascendant, inInclusiveRange(0, 360));
    });

    test('whole-sign houses run 1-12 and the lagna sign is house 1', () {
      for (final p in chart.positions.values) {
        expect(p.house, inInclusiveRange(1, 12), reason: p.graha.en);
      }
      // Anything in the same rāśi as the lagna must be in house 1.
      for (final p in chart.positions.values) {
        if (p.rasi == chart.lagnaRasi) {
          expect(p.house, 1, reason: '${p.graha.en} shares the lagna rasi');
        }
      }
    });

    test('nakshatra and pada are in range', () {
      for (final p in chart.positions.values) {
        expect(p.pada, inInclusiveRange(1, 4), reason: p.graha.en);
      }
      expect(chart.birthNakshatra, isA<Nakshatra>());
    });

    test('Rahu moves retrograde', () {
      // The mean lunar node always regresses.
      expect(chart[Graha.rahu].isRetrograde, isTrue);
    });
  });

  group('timezone handling', () {
    test('Sri Lanka 1996 offset change is applied', () {
      // Sri Lanka shifted off +05:30 during 1996-2006. A chart computed for a
      // birth inside that window must NOT match one computed as if the offset
      // had stayed +05:30 — if it does, the timezone database is being
      // bypassed and every chart from that decade is wrong.
      final inWindow = Ephemeris.computeChart(
        localWallClock: DateTime(1997, 3, 10, 9),
        zoneName: colombo,
        latitude: colomboLat,
        longitude: colomboLon,
      ).valueOrNull!;

      // Same wall clock, expressed against a fixed +05:30 zone.
      final naive = Ephemeris.computeChart(
        localWallClock: DateTime(1997, 3, 10, 9),
        zoneName: 'Asia/Kolkata', // permanently +05:30
        latitude: colomboLat,
        longitude: colomboLon,
      ).valueOrNull!;

      expect(
        inWindow.julianDayUt,
        isNot(closeTo(naive.julianDayUt, 1e-6)),
        reason: 'Colombo in 1997 was not +05:30',
      );
    });

    test('modern Sri Lankan times match +05:30', () {
      final colomboChart = Ephemeris.computeChart(
        localWallClock: DateTime(2026, 3, 10, 9),
        zoneName: colombo,
        latitude: colomboLat,
        longitude: colomboLon,
      ).valueOrNull!;

      final kolkata = Ephemeris.computeChart(
        localWallClock: DateTime(2026, 3, 10, 9),
        zoneName: 'Asia/Kolkata',
        latitude: colomboLat,
        longitude: colomboLon,
      ).valueOrNull!;

      expect(colomboChart.julianDayUt, closeTo(kolkata.julianDayUt, 1e-9));
    });
  });

  group('input validation', () {
    test('rejects an out-of-range year', () {
      final r = Ephemeris.computeChart(
        localWallClock: DateTime(1500, 1, 1),
        zoneName: colombo,
        latitude: colomboLat,
        longitude: colomboLon,
      );
      expect(r.failureOrNull, isA<InvalidBirthDataFailure>());
    });

    test('rejects impossible coordinates', () {
      final r = Ephemeris.computeChart(
        localWallClock: DateTime(1990, 1, 1),
        zoneName: colombo,
        latitude: 95,
        longitude: colomboLon,
      );
      expect(r.failureOrNull, isA<InvalidBirthDataFailure>());
    });
  });
}
