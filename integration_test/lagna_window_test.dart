import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nakshatra/core/astro/ephemeris.dart';
import 'package:nakshatra/core/astro/lagna_window.dart';
import 'package:nakshatra/core/astro/models.dart';
import 'package:nakshatra/features/onboarding/domain/birth_profile.dart';

/// The lagna window against the real ephemeris: a reader who gives only
/// their lagna gets a chart with that lagna, whatever it is.
///
/// test/core/astro/lagna_window_test.dart covers the search itself with a
/// steady fake sky; this checks the real one, where rāśi rise for very
/// different lengths of time. Synthetic dates — real birth data belongs to a
/// person, and this repository is public.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(Ephemeris.initialize);

  const colombo = Place(
    en: 'Colombo',
    latitude: 6.9271,
    longitude: 79.8612,
    district: 'Colombo',
    timezone: 'Asia/Colombo',
  );

  BirthChart chartAt(DateTime date, Duration time) => Ephemeris.computeChart(
    localWallClock: DateTime(
      date.year,
      date.month,
      date.day,
      time.inHours,
      time.inMinutes % 60,
    ),
    zoneName: colombo.timezone,
    latitude: colombo.latitude,
    longitude: colombo.longitude,
  ).valueOrNull!;

  // One date either side of the 1996–2006 offset change, and one inside it.
  for (final date in [
    DateTime(1985, 7, 9),
    DateTime(1999, 1, 23),
    DateTime(2012, 11, 2),
  ]) {
    group('${date.year}-${date.month}-${date.day}', () {
      for (final rasi in Rasi.values) {
        test('${rasi.en}: the chart at the middle has that lagna', () {
          final w = LagnaWindow.forBirth(
            date: date,
            place: colombo,
            rasi: rasi,
          )!;
          expect(chartAt(date, w.middle).lagnaRasi, rasi);

          // Whole windows only: one cut at midnight is shorter, honestly.
          if (w.start > Duration.zero && w.end < const Duration(hours: 24)) {
            expect(w.end - w.start, greaterThan(const Duration(minutes: 80)));
            expect(w.end - w.start, lessThan(const Duration(minutes: 165)));
            // The minute either side is another rāśi: the edges are real.
            expect(
              chartAt(date, w.start - const Duration(minutes: 1)).lagnaRasi,
              isNot(rasi),
            );
            expect(chartAt(date, w.end).lagnaRasi, isNot(rasi));
          }
        });
      }
    });
  }
}
