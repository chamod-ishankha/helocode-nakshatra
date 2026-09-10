import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nakshatra/core/astro/ephemeris.dart';
import 'package:nakshatra/core/astro/ingress.dart';
import 'package:nakshatra/core/astro/models.dart';

/// Sign changes against the real ephemeris (KAN-65).
///
/// The unit tests drive [Ingress.between] with a synthetic sky, which proves
/// the search but says nothing about the ephemeris underneath it. These run on
/// a device, where Swiss Ephemeris exists, and check the two things a fake
/// cannot: that a real slow graha is found changing sign at all, and that the
/// date the search reports is the date the sky actually agrees with.
///
/// Deliberately not a table of expected dates. A hardcoded "Śani enters
/// Kumbha on 29 March 2025" would be an assertion about an almanac this
/// project has not checked against a printed one, and a test that is wrong in
/// the same direction as the code is worse than no test.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const colombo = 'Asia/Colombo';
  const colomboLat = 6.9271;
  const colomboLon = 79.8612;

  setUpAll(() async {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    await Ephemeris.initialize();
  });

  /// The signs the slow grahas really occupy on [at].
  Map<Graha, Rasi> signsAt(DateTime at) {
    final chart = Ephemeris.computeChart(
      localWallClock: DateTime(at.year, at.month, at.day, at.hour, at.minute),
      zoneName: colombo,
      latitude: colomboLat,
      longitude: colomboLon,
    ).valueOrNull;
    if (chart == null) return const {};

    return {
      for (final entry in chart.positions.entries) entry.key: entry.value.rasi,
    };
  }

  test('a year of real sky contains at least one slow ingress', () {
    // Jupiter alone changes sign about once a year, and Rāhu and Ketu every
    // eighteen months, so a whole year with nothing in it means the search
    // found nothing rather than that the sky was still.
    final from = DateTime(2026, 1, 1);

    final events = Ingress.between(
      from: from,
      to: from.add(const Duration(days: 365)),
      signsAt: signsAt,
    );

    expect(events, isNotEmpty);
    for (final event in events) {
      expect(Ingress.slow, contains(event.graha));
      expect(event.from, isNot(event.to));
    }
  });

  test('the sky agrees with the date each ingress is reported on', () {
    // The check the fake cannot make, and the one that found the bug: the
    // bisection used to stop at a whole day, so a bracket straddling midnight
    // dated the crossing to the wrong side of it — Jupiter entering Karka
    // late on 2 June 2026 was reported on the 3rd. No unit test driving a
    // synthetic sky would have noticed, because the fake and the search
    // agreed with each other.
    final from = DateTime(2026, 1, 1);

    final events = Ingress.between(
      from: from,
      to: from.add(const Duration(days: 365)),
      signsAt: signsAt,
    );

    for (final event in events) {
      // The reported date is the calendar day the crossing falls in, so the
      // sign at midnight on it may still be the old one — the graha can move
      // at any hour. What must hold is that the day contains the crossing:
      // arrived by the end of it, not yet arrived before it began.
      expect(
        signsAt(event.on.add(const Duration(hours: 23)))[event.graha],
        event.to,
        reason: 'by the end of its own day, $event had not arrived',
      );
      expect(
        signsAt(event.on.subtract(const Duration(hours: 1)))[event.graha],
        event.from,
        reason: 'before its day began, $event had already happened',
      );
    }
  });

  test('Rāhu and Ketu always change sign together, and opposite', () {
    // A real property of the sky rather than of this code, which makes it a
    // good check on both: the nodes are always exactly six signs apart, so
    // they cross a boundary on the same day into opposite signs. Getting one
    // without the other would mean Ketu is being derived wrongly.
    final from = DateTime(2026, 1, 1);

    final nodes = Ingress.between(
      from: from,
      to: from.add(const Duration(days: 730)),
      signsAt: signsAt,
    ).where((e) => e.graha == Graha.rahu || e.graha == Graha.ketu).toList();

    expect(nodes, isNotEmpty, reason: 'two years with no nodal ingress');

    for (final rahu in nodes.where((e) => e.graha == Graha.rahu)) {
      final ketu = nodes.firstWhere(
        (e) => e.graha == Graha.ketu && e.on == rahu.on,
        orElse: () => throw TestFailure('no Ketu ingress on ${rahu.on}'),
      );

      expect((ketu.to.index - rahu.to.index) % 12, 6);
      // Both move backwards through the zodiac, always.
      expect(rahu.isRetrograde, isTrue);
      expect(ketu.isRetrograde, isTrue);
    }
  });

  test('a week of sky is cheap enough to search at every launch', () {
    // What the coordinator actually does. It runs off the first frame, but a
    // slow one would still be felt on a cheap phone.
    final from = DateTime(2026, 9, 10);
    final started = DateTime.now();

    Ingress.between(
      from: from,
      to: from.add(const Duration(days: 7)),
      signsAt: signsAt,
    );

    final took = DateTime.now().difference(started);
    expect(took.inMilliseconds, lessThan(500), reason: 'took $took');
  });
}
