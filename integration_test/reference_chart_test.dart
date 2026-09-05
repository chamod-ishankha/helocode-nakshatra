import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nakshatra/core/astro/ephemeris.dart';
import 'package:nakshatra/core/astro/models.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// KAN-17 — accuracy validated against Astrodienst (astro.com).
///
/// ## Why the reference values are tropical
///
/// The charts were generated on astro.com in the **tropical** zodiac, which
/// makes this a stronger test than a like-for-like sidereal comparison, not a
/// weaker one. Sidereal longitude is tropical longitude minus the ayanāṃśa, so
/// for a correct chart the difference between every one of astro.com's figures
/// and ours must be the *same* number — and that number must equal the
/// ayanāṃśa we report.
///
/// A single wrong planet shows up as an offset that disagrees with the rest. A
/// wrong ayanāṃśa shows up as every offset agreeing with each other but not
/// with the value we claim. Neither can hide.
///
/// ## What this actually validates
///
/// Astrodienst wrote Swiss Ephemeris, so this does not independently confirm
/// the orbital mechanics — it confirms *our use of the library*: sidereal mode,
/// the Lahiri ayanāṃśa, whole-sign houses, and the local-time to UT conversion.
/// That is where the bugs live.
///
/// Coordinates below are the ones astro.com resolved each town to, not the ones
/// in our bundled place data. They differ by a few hundred metres, which is
/// invisible for planets but moves the ascendant by a couple of arc-minutes.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Ephemeris.initialize();
    tzdata.initializeTimeZones();
  });

  /// Tolerance. The gate in KAN-17 is one arc-minute.
  const toleranceArcMin = 1.0;

  void verify({
    required String label,
    required DateTime local,
    required DateTime expectedUtc,
    required double lat,
    required double lon,
    required double expectedAyanamsa,
    required Map<Graha, double> tropical,
    required double tropicalAscendant,
  }) {
    group(label, () {
      late BirthChart chart;

      setUpAll(() {
        chart = Ephemeris.computeChart(
          localWallClock: local,
          zoneName: 'Asia/Colombo',
          latitude: lat,
          longitude: lon,
        ).valueOrNull!;
      });

      test('local time converts to the UT astro.com used', () {
        // An independent check of the timezone handling: astro.com prints the
        // Universal Time it worked from, and Astrodienst maintains its own
        // historical timezone data.
        final loc = tz.getLocation('Asia/Colombo');
        final tzLocal = tz.TZDateTime(
          loc,
          local.year,
          local.month,
          local.day,
          local.hour,
          local.minute,
        );
        expect(tzLocal.toUtc(), expectedUtc);
      });

      test('ayanamsa matches', () {
        expect(chart.ayanamsa, closeTo(expectedAyanamsa, 0.001));
      });

      for (final entry in tropical.entries) {
        test('${entry.key.en} agrees with astro.com', () {
          final implied = (entry.value - chart[entry.key].longitude) % 360;
          expect(
            (implied - chart.ayanamsa).abs() * 60,
            lessThan(toleranceArcMin),
            reason:
                '${entry.key.en}: astro.com tropical ${entry.value}, ours '
                'sidereal ${chart[entry.key].longitude}, implied ayanamsa '
                '$implied vs reported ${chart.ayanamsa}',
          );
        });
      }

      test('ascendant agrees with astro.com', () {
        final implied = (tropicalAscendant - chart.ascendant) % 360;
        expect(
          (implied - chart.ayanamsa).abs() * 60,
          lessThan(toleranceArcMin),
        );
      });

      test('every body implies the same ayanamsa', () {
        // The core argument. If one planet were computed wrongly its implied
        // offset would drift away from the others, whatever the ayanāṃśa is.
        final implied = [
          for (final e in tropical.entries)
            (e.value - chart[e.key].longitude) % 360,
        ];
        final spread =
            (implied.reduce((a, b) => a > b ? a : b) -
                implied.reduce((a, b) => a < b ? a : b)) *
            60;
        expect(spread, lessThan(toleranceArcMin));
      });
    });
  }

  // ── Case A — inside Sri Lanka's +06:00 window ────────────────────────────
  // The critical case. astro.com independently resolved 14:20 local to 08:20
  // UT, confirming +06:00 rather than +05:30.
  verify(
    label: 'Kandy 1999-03-15 14:20 (+06:00 window)',
    local: DateTime(1999, 3, 15, 14, 20),
    expectedUtc: DateTime.utc(1999, 3, 15, 8, 20),
    lat: 7.30,
    lon: 80.6333,
    expectedAyanamsa: 23.8430,
    tropicalAscendant: 109.5000, // 19 Can 30'
    tropical: {
      Graha.sun: 354.2997, // 24 Pis 17'59"
      Graha.moon: 322.4872, // 22 Aqu 29'14"
      Graha.mercury: 2.3553, // 2 Ari 21'19"
      Graha.venus: 26.2811, // 26 Ari 16'52"
      Graha.mars: 222.1400, // 12 Sco 8'24"
      Graha.jupiter: 6.9944, // 6 Ari 59'40"
      Graha.saturn: 31.4872, // 1 Tau 29'14"
    },
  );

  // ── Case B — modern, +05:30, ascendant near a sign cusp ──────────────────
  verify(
    label: 'Jaffna 2015-11-08 06:45',
    local: DateTime(2015, 11, 8, 6, 45),
    expectedUtc: DateTime.utc(2015, 11, 8, 1, 15),
    lat: 9.6667,
    lon: 80.0,
    expectedAyanamsa: 24.0780,
    tropicalAscendant: 234.6667, // 24 Sco 40'
    tropical: {
      Graha.sun: 225.3042, // 15 Sco 18'15"
      Graha.moon: 184.9114, // 4 Lib 54'41"
      Graha.mercury: 219.4956, // 9 Sco 29'44"
      Graha.venus: 179.3594, // 29 Vir 21'34"
      Graha.mars: 177.0736, // 27 Vir 4'25"
      Graha.jupiter: 167.8861, // 17 Vir 53'10"
      Graha.saturn: 244.8806, // 4 Sag 52'50"
    },
  );

  // ── Case C — pre-1996, +05:30, late evening ──────────────────────────────
  verify(
    label: 'Galle 1985-01-22 23:10',
    local: DateTime(1985, 1, 22, 23, 10),
    expectedUtc: DateTime.utc(1985, 1, 22, 17, 40),
    lat: 6.0333,
    lon: 80.2167,
    expectedAyanamsa: 23.6450,
    tropicalAscendant: 197.8833, // 17 Lib 53'
    tropical: {
      Graha.sun: 302.6600, // 2 Aqu 39'36"
      Graha.moon: 321.9642, // 21 Aqu 57'51"
      Graha.mercury: 285.3378, // 15 Cap 20'16"
      Graha.venus: 349.6953, // 19 Pis 41'43"
      Graha.mars: 351.6944, // 21 Pis 41'40"
      Graha.jupiter: 296.5403, // 26 Cap 32'25"
      Graha.saturn: 236.5386, // 26 Sco 32'19"
    },
  );

  // Rahu and Ketu are deliberately not compared. astro.com's listing gives the
  // *true* node; Vedic practice uses the *mean* node, and the two differ by up
  // to about 1.8 degrees. Both charts checked out as consistent with that
  // difference, but it is not a value a tolerance test can assert.
}
