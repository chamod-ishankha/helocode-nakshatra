import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nakshatra/core/astro/dasha.dart';
import 'package:nakshatra/core/astro/ephemeris.dart';
import 'package:nakshatra/core/astro/models.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

/// Vimśottarī daśā against real charts (KAN-18).
///
/// The unit tests in test/core/astro/dasha_test.dart fabricate a Moon
/// longitude, which proves the arithmetic but not that it survives contact
/// with the ephemeris. These use the same three charts KAN-17 validated
/// against astro.com, so the Moon positions are known-good.
///
/// The birth instants are also known-good, which makes them an independent
/// check on `utcFromJulianDay`: KAN-17 asserts each chart's Julian day matches
/// a stated UTC, so converting back must land on that same UTC. A sign error
/// or a wrong epoch constant would shift every daśā boundary by years and is
/// otherwise invisible.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Ephemeris.initialize();
    tzdata.initializeTimeZones();
  });

  final charts = <String, ({DateTime local, DateTime utc, double lat, double lon})>{
    'Kandy 1999-03-15 14:20': (
      local: DateTime(1999, 3, 15, 14, 20),
      utc: DateTime.utc(1999, 3, 15, 8, 20),
      lat: 7.30,
      lon: 80.6333,
    ),
    'Jaffna 2015-11-08 06:45': (
      local: DateTime(2015, 11, 8, 6, 45),
      utc: DateTime.utc(2015, 11, 8, 1, 15),
      lat: 9.6667,
      lon: 80.0,
    ),
    'Galle 1985-01-22 23:10': (
      local: DateTime(1985, 1, 22, 23, 10),
      utc: DateTime.utc(1985, 1, 22, 17, 40),
      lat: 6.0333,
      lon: 80.2167,
    ),
  };

  charts.forEach((label, ref) {
    group(label, () {
      late BirthChart chart;
      late List<DashaPeriod> timeline;

      setUpAll(() {
        chart = Ephemeris.computeChart(
          localWallClock: ref.local,
          zoneName: 'Asia/Colombo',
          latitude: ref.lat,
          longitude: ref.lon,
        ).valueOrNull!;
        timeline = Vimshottari.forChart(chart);
      });

      test('the birth instant round-trips through the Julian day', () {
        // KAN-17 established this UTC independently. Getting back to it from
        // the chart's own Julian day is what ties the daśā timeline to the
        // chart rather than to a re-derived wall clock.
        final birth = utcFromJulianDay(chart.julianDayUt);
        expect(
          birth.difference(ref.utc).abs(),
          lessThan(const Duration(seconds: 1)),
          reason: 'got $birth, expected ${ref.utc}',
        );
      });

      test('the first lord is the lord of the Moon\'s nakṣatra', () {
        final moonNakshatra = chart.birthNakshatra;
        expect(timeline.first.lord, Vimshottari.lordOf(moonNakshatra));
      });

      test('the sequence covers 120 years from the true cycle start', () {
        // The first period is clipped to birth, so the visible span is 120
        // years minus whatever was already spent.
        final span = timeline.last.end.difference(timeline.first.start);
        final full = Duration(
          milliseconds:
              (120 * Vimshottari.daysPerYear * Duration.millisecondsPerDay)
                  .round(),
        );
        expect(span, lessThanOrEqualTo(full));
        expect(span.inDays, greaterThan(110 * 365));
      });

      test('periods tile at every level', () {
        for (var i = 1; i < timeline.length; i++) {
          expect(timeline[i].start, timeline[i - 1].end);
        }
        for (final maha in timeline) {
          expect(maha.children.first.start, maha.start);
          expect(maha.children.last.end, maha.end);
          for (final antara in maha.children) {
            expect(antara.children.first.start, antara.start);
            expect(antara.children.last.end, antara.end);
          }
        }
      });

      test('there is exactly one period running at any instant', () {
        // Probed across the timeline's own span rather than a fixed 120 years
        // from birth: the cycle starts before birth, so it also ends before
        // birth plus 120.
        final from = timeline.first.start;
        final span = timeline.last.end.difference(from);

        for (final fraction in [0.0, 0.01, 0.13, 0.37, 0.5, 0.72, 0.99]) {
          final when = from.add(
            Duration(microseconds: (span.inMicroseconds * fraction).round()),
          );
          final matching = timeline.where((p) => p.contains(when)).length;
          expect(matching, 1, reason: 'at $fraction of the span, $matching');
        }
      });

      test('the cycle ends within a human lifetime of birth, and stops', () {
        // One cycle only. After 120 years the sequence repeats, but nobody
        // reaches it, and silently running a second cycle would hide an
        // off-by-one in the first.
        final birth = utcFromJulianDay(chart.julianDayUt);
        final age = timeline.last.end.difference(birth).inDays / 365.25;

        expect(age, lessThanOrEqualTo(120.0));
        expect(age, greaterThan(100.0));
        expect(
          Vimshottari.at(timeline, timeline.last.end),
          isNull,
          reason: 'the instant the cycle ends belongs to no period',
        );
      });

      test('the balance agrees with the first period\'s length', () {
        expect(
          Vimshottari.balanceAtBirth(chart).inMinutes,
          closeTo(timeline.first.duration.inMinutes, 1),
        );
      });

      test('prints the mahādaśā table for external cross-check', () {
        // Not an assertion. astro.com publishes a Vimśottarī table for these
        // same charts, and so does any printed litha — this is what a human
        // compares against, since nothing in this repo is an authority on
        // what the answer should be.
        final birth = utcFromJulianDay(chart.julianDayUt);
        debugPrint('=== $label (birth $birth UTC) ===');
        debugPrint('Moon ${chart[Graha.moon].longitude.toStringAsFixed(4)}° '
            'in ${chart.birthNakshatra.en}');
        debugPrint('balance ${Vimshottari.balanceAtBirth(chart).inDays} days');
        for (final maha in timeline) {
          debugPrint('${maha.lord.en.padRight(8)} '
              '${maha.start.toIso8601String().substring(0, 10)} → '
              '${maha.end.toIso8601String().substring(0, 10)}');
        }
      });
    });
  });
}
