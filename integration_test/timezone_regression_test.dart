import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nakshatra/core/astro/ephemeris.dart';
import 'package:nakshatra/core/astro/models.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Sri Lanka's 1996-2006 timezone shift.
///
/// The country left +05:30 in 1996 and did not return until April 2006, sitting
/// at +06:00 for most of that decade. Anyone born in that window gets a chart
/// half an hour out if a tool assumes +05:30 — and half an hour moves the
/// ascendant by roughly 7.5 degrees, which is enough to change the lagna sign
/// outright.
///
/// This is the most likely source of a wrong chart for Sri Lankan users, and it
/// is invisible: every planetary position still looks plausible.
///
/// A synthetic date inside the window is used deliberately. Real birth data
/// belongs to a person, and this repository is public.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const colomboLat = 6.9271;
  const colomboLon = 79.8612;

  setUpAll(() async {
    await Ephemeris.initialize();
    tzdata.initializeTimeZones();
  });

  group('Asia/Colombo historical offsets', () {
    test('is +06:00 inside the 1996-2006 window', () {
      final loc = tz.getLocation('Asia/Colombo');
      expect(
        tz.TZDateTime(loc, 2000, 7, 23, 11, 39).timeZoneOffset,
        const Duration(hours: 6),
      );
    });

    test('is +05:30 before and after the window', () {
      final loc = tz.getLocation('Asia/Colombo');
      expect(
        tz.TZDateTime(loc, 1990, 7, 23, 11, 39).timeZoneOffset,
        const Duration(hours: 5, minutes: 30),
      );
      expect(
        tz.TZDateTime(loc, 2026, 7, 23, 11, 39).timeZoneOffset,
        const Duration(hours: 5, minutes: 30),
      );
    });
  });

  BirthChart chartIn(String zone) => Ephemeris.computeChart(
    localWallClock: DateTime(2001, 5, 10, 9, 15),
    zoneName: zone,
    latitude: colomboLat,
    longitude: colomboLon,
  ).valueOrNull!;

  test('a 30-minute offset error moves the ascendant about 7.5 degrees', () {
    // Asia/Kolkata is permanently +05:30, so it stands in for a tool that
    // assumes Sri Lanka never changed. If these ever agree, the timezone
    // database is being bypassed and every chart from that decade is wrong.
    final correct = chartIn('Asia/Colombo');
    final wrong = chartIn('Asia/Kolkata');

    expect(
      correct.julianDayUt,
      isNot(closeTo(wrong.julianDayUt, 1e-9)),
      reason: 'Colombo in 2001 was not +05:30',
    );

    final delta = (wrong.ascendant - correct.ascendant + 360) % 360;
    expect(delta, inInclusiveRange(6.0, 9.5));
  });

  test('the Moon barely moves in 30 minutes, the ascendant does not', () {
    // Why "the planets look right" is not evidence the chart is right. The Moon
    // is the fastest graha and still shifts only a quarter of a degree in half
    // an hour, so a timezone bug leaves every position looking plausible while
    // the ascendant and every house placement are wrong.
    final correct = chartIn('Asia/Colombo');
    final wrong = chartIn('Asia/Kolkata');

    final moonShift =
        (wrong[Graha.moon].longitude - correct[Graha.moon].longitude).abs();
    expect(moonShift, lessThan(0.5));

    final ascShift = (wrong.ascendant - correct.ascendant).abs();
    expect(
      ascShift,
      greaterThan(moonShift * 10),
      reason: 'the ascendant is the sensitive value, not the grahas',
    );
  });
}
