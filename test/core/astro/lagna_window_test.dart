import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/astro/lagna_window.dart';
import 'package:nakshatra/core/astro/models.dart';
import 'package:nakshatra/features/onboarding/domain/birth_profile.dart';

/// The search behind "I don't know my time, but I know my lagna".
///
/// The real ascendant needs the native ephemeris, which does not load under
/// `flutter test`; integration_test/lagna_window_test.dart checks it against
/// real charts. Here the sky turns at a steady quarter-degree a minute, so
/// every rāśi rises for exactly two hours and the answers are known.
void main() {
  /// Degrees at local midnight, then a steady quarter-degree a minute.
  double Function(Duration) sky(double atMidnight) =>
      (t) => (atMidnight + t.inMinutes * 0.25) % 360;

  test('finds the two hours the lagna was rising, and the middle', () {
    final w = LagnaWindow.find(rasi: Rasi.simha, ascendantAt: sky(0))!;
    // Simha is 120°–150°: 8:00 to 10:00.
    expect(w.start, const Duration(hours: 8));
    expect(w.end, const Duration(hours: 10));
    expect(w.middle, const Duration(hours: 9));
  });

  test('the edges are to the minute, not to the sampling step', () {
    // 7 minutes in at midnight: Mesha ends at 113 minutes, between samples.
    final w = LagnaWindow.find(
      rasi: Rasi.vrishabha,
      ascendantAt: (t) => (t.inMinutes + 7) * 0.25,
    )!;
    expect(w.start, const Duration(minutes: 113));
    expect(w.end, const Duration(minutes: 233));
  });

  test('a window across midnight is cut at the date', () {
    // 10° at midnight: Mesha until 1:20 AM, and again from 11:20 PM.
    final w = LagnaWindow.find(rasi: Rasi.mesha, ascendantAt: sky(10))!;
    // The longer piece, from midnight.
    expect(w.start, Duration.zero);
    expect(w.end, const Duration(minutes: 80));
    expect(w.middle, const Duration(minutes: 40));
  });

  test('the piece before midnight wins when it is the longer', () {
    // 25° at midnight: Mesha until 0:20, and from 22:20 to midnight.
    final w = LagnaWindow.find(rasi: Rasi.mesha, ascendantAt: sky(25))!;
    expect(w.start, const Duration(hours: 22, minutes: 20));
    expect(w.end, const Duration(hours: 24));
  });

  test('a rāśi that never rises that day is no answer', () {
    // Half a turn in the day: Tula to Meena never come up.
    expect(
      LagnaWindow.find(
        rasi: Rasi.makara,
        ascendantAt: (t) => t.inMinutes * 0.125,
      ),
      isNull,
    );
  });

  group('the time saved for a reader without one', () {
    const kandy = Place(
      en: 'Kandy',
      latitude: 7.2906,
      longitude: 80.6337,
      district: 'Kandy',
      timezone: 'Asia/Colombo',
    );
    final date = DateTime(1988, 2, 14);
    RisingWindow? simhaAtNine({
      required DateTime date,
      required Place place,
      required Rasi rasi,
    }) => rasi == Rasi.simha
        ? (
            start: const Duration(hours: 8),
            end: const Duration(hours: 10),
            middle: const Duration(hours: 9),
          )
        : null;

    test('with a lagna, the middle of its window, and the lagna kept', () {
      final got = LagnaWindow.timeWithout(
        date: date,
        place: kandy,
        lagna: Rasi.simha,
        find: simhaAtNine,
      );
      expect(got.time, const Duration(hours: 9));
      expect(got.lagna, Rasi.simha);
    });

    test('without one, sunrise', () {
      final got = LagnaWindow.timeWithout(
        date: date,
        place: kandy,
        lagna: null,
        find: simhaAtNine,
      );
      expect(got.time, BirthProfile.defaultUnknownTime);
      expect(got.lagna, isNull);
    });

    test('a lagna with no window falls back to sunrise and is not kept', () {
      // Kept, it would claim a lagna the saved time does not produce.
      final got = LagnaWindow.timeWithout(
        date: date,
        place: kandy,
        lagna: Rasi.kumbha,
        find: simhaAtNine,
      );
      expect(got.time, BirthProfile.defaultUnknownTime);
      expect(got.lagna, isNull);
    });
  });
}
