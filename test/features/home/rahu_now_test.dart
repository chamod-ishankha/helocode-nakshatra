import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/astro/panchanga_models.dart';
import 'package:nakshatra/features/home/domain/daily_providers.dart';
import 'package:nakshatra/features/home/domain/rahu_now.dart';

/// The home screen's sense of "now" (KAN-92): the rāhu chip and ring, the sun
/// on the day arc, and the running-now banner.
void main() {
  DateTime at(int h, int m) => DateTime(2026, 9, 8, h, m);

  final rahu = TimeWindow(
    start: at(10, 30),
    end: at(12, 0),
    kind: WindowKind.rahu,
  );

  group('RahuNow', () {
    test('is ahead, with nothing gone, before it starts', () {
      final s = RahuNow.of(rahu, at(10, 29));
      expect(s.phase, RahuPhase.ahead);
      expect(s.progress, 0);
    });

    test('is running from its first minute', () {
      final s = RahuNow.of(rahu, at(10, 30));
      expect(s.phase, RahuPhase.running);
      expect(s.progress, 0);
    });

    test('reports how much of the window has gone', () {
      // 62 of 90 minutes: the mock's 69%.
      expect(RahuNow.of(rahu, at(11, 32)).progress, closeTo(62 / 90, 1e-9));
    });

    test('is past at its end, not running for one more minute', () {
      // TimeWindow.contains excludes the end, and the chip must agree with
      // the banner: both say it is over at 12:00.
      final s = RahuNow.of(rahu, at(12, 0));
      expect(s.phase, RahuPhase.past);
      expect(s.progress, 1);
    });
  });

  group('dayFraction', () {
    final rise = at(6, 0);
    final set = at(18, 0);

    test('runs from sunrise to sunset', () {
      expect(dayFraction(rise, set, rise), 0);
      expect(dayFraction(rise, set, at(12, 0)), 0.5);
      expect(dayFraction(rise, set, set), 1);
    });

    test('keeps the sun on the horizon at night', () {
      expect(dayFraction(rise, set, at(4, 0)), 0);
      expect(dayFraction(rise, set, at(21, 0)), 1);
    });
  });

  group('currentlyInauspiciousProvider', () {
    ProviderContainer containerAt(DateTime now) {
      final c = ProviderContainer(
        overrides: [
          clockProvider.overrideWith(() => _FixedClock(now)),
          inauspiciousProvider.overrideWithValue([rahu]),
        ],
      );
      addTearDown(c.dispose);
      c.read(selectedDateProvider.notifier).set(DateTime(2026, 9, 8));
      return c;
    }

    test('finds the window the clock is in', () {
      expect(containerAt(at(11, 0)).read(currentlyInauspiciousProvider), rahu);
    });

    test('lets go when the clock moves past it', () {
      // It read the time once, when the day was computed, so an app left open
      // over lunch kept saying "running now" all afternoon.
      final c = containerAt(at(11, 59));
      final sub = c.listen(currentlyInauspiciousProvider, (_, _) {});
      expect(sub.read(), rahu);

      (c.read(clockProvider.notifier) as _FixedClock).set(at(12, 0));
      expect(sub.read(), isNull);
    });

    test('is nothing on any day but today', () {
      final c = containerAt(at(11, 0));
      c.read(selectedDateProvider.notifier).set(DateTime(2026, 9, 9));
      expect(c.read(currentlyInauspiciousProvider), isNull);
    });
  });
}

class _FixedClock extends ClockNotifier {
  _FixedClock(this._start);

  final DateTime _start;

  @override
  DateTime build() => _start;

  void set(DateTime t) => state = t;
}
