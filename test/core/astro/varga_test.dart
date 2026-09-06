import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/astro/models.dart';
import 'package:nakshatra/core/astro/varga.dart';

/// Navāṃśa (KAN-53).
void main() {
  /// The classical rule, written out the way it is taught, to check the
  /// collapsed formula against.
  ///
  /// Movable signs count their navāṃśas from themselves, fixed signs from the
  /// ninth sign, dual signs from the fifth.
  Rasi classical(Rasi sign, int navamsaNumber) {
    const movable = [0, 3, 6, 9];
    const fixed = [1, 4, 7, 10];

    final start = movable.contains(sign.index)
        ? sign.index
        : fixed.contains(sign.index)
            ? (sign.index + 8) % 12
            : (sign.index + 4) % 12;

    return Rasi.values[(start + navamsaNumber) % 12];
  }

  test('the collapsed formula matches the classical rule everywhere', () {
    // 108 cases: twelve signs by nine navāṃśas. The equivalence is easy to
    // assert and hard to believe, so it is checked exhaustively rather than
    // spot-checked.
    for (final sign in Rasi.values) {
      for (var n = 0; n < 9; n++) {
        final longitude = sign.index * 30 + n * Varga.navamsaSpan + 0.5;
        expect(
          Varga.navamsaSign(longitude),
          classical(sign, n),
          reason: '${sign.en} navāṃśa ${n + 1}',
        );
      }
    }
  });

  test('the three sign types start where tradition says', () {
    // Movable: from itself.
    expect(Varga.navamsaSign(0), Rasi.mesha);
    // Fixed: Taurus starts from Capricorn, the ninth from it.
    expect(Varga.navamsaSign(30), Rasi.makara);
    // Dual: Gemini starts from Libra, the fifth from it.
    expect(Varga.navamsaSign(60), Rasi.tula);
  });

  test('a whole sign spans exactly nine navāṃśas', () {
    final seen = <Rasi>{};
    for (var n = 0; n < 9; n++) {
      seen.add(Varga.navamsaSign(n * Varga.navamsaSpan + 0.01));
    }
    expect(seen.length, 9, reason: 'nine consecutive, distinct signs');
  });

  test('the division stretches to fill its sign', () {
    // Start of a navāṃśa lands at 0° of its sign, the end approaches 30°.
    expect(Varga.navamsaLongitude(0) % 30, closeTo(0, 1e-9));
    expect(
      Varga.navamsaLongitude(Varga.navamsaSpan - 0.0001) % 30,
      closeTo(30, 0.01),
    );
  });

  test('longitudes outside 0-360 are normalised', () {
    expect(Varga.navamsaSign(-30), Varga.navamsaSign(330));
    expect(Varga.navamsaSign(400), Varga.navamsaSign(40));
  });

  group('projecting a whole chart', () {
    BirthChart chartWith(double ascendant, Map<Graha, double> longitudes) =>
        BirthChart(
          julianDayUt: 2451545.0,
          ascendant: ascendant,
          midheaven: 0,
          ayanamsa: 23.85,
          positions: {
            for (final e in longitudes.entries)
              e.key: GrahaPosition(
                graha: e.key,
                longitude: e.value,
                latitude: 0,
                speed: e.key == Graha.rahu ? -0.05 : 1.0,
                house: 1,
              ),
          },
        );

    test('the navāṃśa lagna sits in house 1', () {
      final d9 = Varga.navamsa(
        chartWith(100, {Graha.sun: 100, Graha.moon: 200}),
      );

      final lagnaSign = d9.lagnaRasi;
      for (final p in d9.positions.values) {
        if (p.rasi == lagnaSign) {
          expect(p.house, 1, reason: '${p.graha.en} should be in house 1');
        }
      }
    });

    test('houses stay whole-sign, counted from the new lagna', () {
      final d9 = Varga.navamsa(
        chartWith(0, {for (final g in Graha.values) g: g.index * 37.0}),
      );

      for (final p in d9.positions.values) {
        final expected =
            ((p.rasi.index - d9.lagnaRasi.index) % 12) + 1;
        expect(p.house, expected, reason: p.graha.en);
        expect(p.house, inInclusiveRange(1, 12));
      }
    });

    test('retrograde motion carries over unchanged', () {
      // Retrogression belongs to the body, not to the division.
      final d9 = Varga.navamsa(
        chartWith(0, {Graha.rahu: 200, Graha.sun: 10}),
      );
      expect(d9[Graha.rahu].isRetrograde, isTrue);
      expect(d9[Graha.sun].isRetrograde, isFalse);
    });

    test('every graha survives the projection', () {
      final source = chartWith(
        45,
        {for (final g in Graha.values) g: g.index * 29.0},
      );
      final d9 = Varga.navamsa(source);

      expect(d9.positions.keys.toSet(), source.positions.keys.toSet());
    });

    test('the result is a chart the existing renderers can take', () {
      // The point of returning a BirthChart: a D9 is a chart, not a special
      // case, so the rāśi widgets and the detail sheet work on it unchanged.
      final d9 = Varga.navamsa(
        chartWith(15, {Graha.sun: 15, Graha.moon: 47}),
      );

      expect(d9.lagnaRasi, isA<Rasi>());
      expect(d9.birthNakshatra, isA<Nakshatra>());
      expect(d9.ayanamsa, 23.85);
    });
  });
}
