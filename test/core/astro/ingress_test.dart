import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/astro/ingress.dart';
import 'package:nakshatra/core/astro/models.dart';

/// Finding the dates the slow grahas change sign (KAN-65).
///
/// The real ephemeris is device-only, so every case here drives the search
/// with a synthetic sky whose answer is known by construction. That is not a
/// weaker test than one using real positions — the search is where a mistake
/// would be, and a fake lets a retrograde re-entry be set up exactly, which
/// waiting for Jupiter to do it would not.
void main() {
  final epoch = DateTime.utc(2026, 1, 1);

  /// A sky where [graha] sits at [degreesPerDay] from [startLongitude].
  ///
  /// Counts sample calls, because the cost of this search is entirely the
  /// number of times it asks the ephemeris.
  ({Map<Graha, Rasi> Function(DateTime) signs, int Function() calls}) mover(
    Graha graha,
    double startLongitude,
    double degreesPerDay,
  ) {
    var calls = 0;

    Map<Graha, Rasi> signs(DateTime at) {
      calls++;
      final days =
          at.difference(epoch).inMicroseconds / Duration.microsecondsPerDay;
      final longitude = (startLongitude + degreesPerDay * days) % 360;
      return {graha: Rasi.fromLongitude(longitude)};
    }

    return (signs: signs, calls: () => calls);
  }

  group('a single crossing', () {
    test('is found on the day it happens', () {
      // Saturn at 29° of Aries, moving a degree every ten days. It needs ten
      // days to reach 30°, so it enters Taurus on 11 January.
      final sky = mover(Graha.saturn, 29, 0.1);

      final events = Ingress.between(
        from: epoch,
        to: epoch.add(const Duration(days: 60)),
        signsAt: sky.signs,
      );

      expect(events, hasLength(1));
      expect(events.single.graha, Graha.saturn);
      expect(events.single.from, Rasi.mesha);
      expect(events.single.to, Rasi.vrishabha);
      expect(events.single.on, DateTime.utc(2026, 1, 11));
      expect(events.single.isRetrograde, isFalse);
    });

    test('is reported at day resolution, with no time of day', () {
      final sky = mover(Graha.jupiter, 29.5, 0.2);

      final on = Ingress.between(
        from: epoch,
        to: epoch.add(const Duration(days: 30)),
        signsAt: sky.signs,
      ).single.on;

      expect(on.hour, 0);
      expect(on.minute, 0);
      expect(on.isUtc, isTrue);
    });

    test('a local window gives a local date, not a UTC one', () {
      // "Which day did Śani move" is a local question, and the coordinator
      // asks it with local dates. Forcing the answer to UTC would land it on
      // the day before for every user west of Greenwich — the alert would
      // arrive before the transit it is about. Sri Lanka is east of it, so
      // this is exactly the bug nobody here would ever see.
      final localEpoch = DateTime(2026, 1, 1);

      Map<Graha, Rasi> signs(DateTime at) {
        final days =
            at.difference(localEpoch).inMicroseconds /
            Duration.microsecondsPerDay;
        return {Graha.saturn: Rasi.fromLongitude(29 + 0.1 * days)};
      }

      final on = Ingress.between(
        from: localEpoch,
        to: localEpoch.add(const Duration(days: 60)),
        signsAt: signs,
      ).single.on;

      expect(on.isUtc, isFalse);
      expect(on, DateTime(2026, 1, 11));
    });

    test('backwards motion is marked retrograde', () {
      // Ketu at 0.5° of Taurus, moving backwards. The nodes always do.
      final sky = mover(Graha.ketu, 30.5, -0.1);

      final event = Ingress.between(
        from: epoch,
        to: epoch.add(const Duration(days: 30)),
        signsAt: sky.signs,
      ).single;

      expect(event.from, Rasi.vrishabha);
      expect(event.to, Rasi.mesha);
      expect(event.isRetrograde, isTrue);
    });

    test('the wrap from Pisces to Aries is not a retrograde', () {
      // (from.index - 1) % 12 is where an off-by-one at the year boundary
      // would show up: Pisces is 11, Aries is 0.
      final sky = mover(Graha.jupiter, 359.5, 0.1);

      final event = Ingress.between(
        from: epoch,
        to: epoch.add(const Duration(days: 30)),
        signsAt: sky.signs,
      ).single;

      expect(event.from, Rasi.meena);
      expect(event.to, Rasi.mesha);
      expect(event.isRetrograde, isFalse);
    });
  });

  group('what is and is not an event', () {
    test('a graha that stays put produces nothing', () {
      final sky = mover(Graha.saturn, 15, 0);

      expect(
        Ingress.between(
          from: epoch,
          to: epoch.add(const Duration(days: 400)),
          signsAt: sky.signs,
        ),
        isEmpty,
      );
    });

    test('the fast grahas are ignored however far they move', () {
      // The Moon changes sign every two and a half days. Alerting on that
      // would be a notification every other morning, which is how an app
      // gets its notifications switched off for good.
      final sky = mover(Graha.moon, 0, 13);

      expect(
        Ingress.between(
          from: epoch,
          to: epoch.add(const Duration(days: 30)),
          signsAt: sky.signs,
        ),
        isEmpty,
      );
    });

    test('a graha the ephemeris does not know is skipped, not invented', () {
      // A partial answer must not read as movement. Rāhu is absent here.
      Map<Graha, Rasi> partial(DateTime at) => {Graha.saturn: Rasi.mesha};

      expect(
        Ingress.between(
          from: epoch,
          to: epoch.add(const Duration(days: 400)),
          signsAt: partial,
        ),
        isEmpty,
      );
    });

    test('an empty or backwards window is not searched at all', () {
      var calls = 0;
      Map<Graha, Rasi> counting(DateTime at) {
        calls++;
        return const {};
      }

      expect(
        Ingress.between(from: epoch, to: epoch, signsAt: counting),
        isEmpty,
      );
      expect(
        Ingress.between(
          from: epoch,
          to: epoch.subtract(const Duration(days: 10)),
          signsAt: counting,
        ),
        isEmpty,
      );
      expect(calls, 0, reason: 'the ephemeris was asked about nothing');
    });
  });

  group('the awkward cases', () {
    test('a retrograde graha leaving and returning gives two events', () {
      // This is why the step is three days rather than a month. Jupiter
      // crosses out of Aries, stations, and comes back — two real ingresses
      // a fortnight apart, and a coarse search would report one or neither.
      Map<Graha, Rasi> wobble(DateTime at) {
        final day =
            at.difference(epoch).inMicroseconds / Duration.microsecondsPerDay;
        // Out past 30° around day 10, back under it around day 24.
        final longitude = day < 10
            ? 29.9
            : day < 24
            ? 30.1
            : 29.9;
        return {Graha.jupiter: Rasi.fromLongitude(longitude)};
      }

      final events = Ingress.between(
        from: epoch,
        to: epoch.add(const Duration(days: 60)),
        signsAt: wobble,
      );

      expect(events, hasLength(2));
      expect(events.first.to, Rasi.vrishabha);
      expect(events.last.to, Rasi.mesha);
      expect(events.last.isRetrograde, isTrue);
      expect(events.first.on.isBefore(events.last.on), isTrue);
    });

    test('two grahas moving at once are both reported, in date order', () {
      // Both cross inside the same step, Saturn first — and Jupiter is found
      // first, because that is the order Ingress.slow iterates. So the result
      // is only in date order if it was actually sorted, which is the point
      // of the case: without the sort this returns Jupiter's later crossing
      // ahead of Saturn's earlier one.
      Map<Graha, Rasi> sky(DateTime at) {
        final day =
            at.difference(epoch).inMicroseconds / Duration.microsecondsPerDay;
        return {
          Graha.saturn: Rasi.fromLongitude(day < 1 ? 29 : 31),
          Graha.jupiter: Rasi.fromLongitude(day < 2 ? 59 : 61),
        };
      }

      final events = Ingress.between(
        from: epoch,
        to: epoch.add(const Duration(days: 60)),
        signsAt: sky,
      );

      expect(events.map((e) => e.graha), [Graha.saturn, Graha.jupiter]);
      expect(events.first.on.isBefore(events.last.on), isTrue);
    });

    test('a crossing on the last day of the window is still inside it', () {
      // The walk clamps its final step to the window end. Losing that clamp
      // would either miss this or report a date past what was asked for.
      final sky = mover(Graha.saturn, 29.5, 0.1);
      final end = epoch.add(const Duration(days: 5));

      final events = Ingress.between(from: epoch, to: end, signsAt: sky.signs);

      expect(events, hasLength(1));
      expect(events.single.on.isAfter(end), isFalse);
    });
  });

  test('a year of sky costs a manageable number of ephemeris calls', () {
    // The whole reason for stepping and bisecting rather than walking day by
    // day. This runs on a cheap phone at app start, and 365 ephemeris calls
    // there would be felt.
    final sky = mover(Graha.saturn, 29, 0.03);

    Ingress.between(
      from: epoch,
      to: epoch.add(const Duration(days: 365)),
      signsAt: sky.signs,
    );

    // Higher than the 122 samples the walk itself needs: pinning the
    // crossing to the minute costs about a dozen more lookups, once, for
    // the one graha that moved.
    expect(sky.calls(), lessThan(160));
  });
}
