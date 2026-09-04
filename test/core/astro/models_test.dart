import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/astro/models.dart';

/// Pure zodiac arithmetic — no native library, so this runs in CI.
///
/// The ephemeris binding itself is exercised in integration_test/, which needs
/// a real device.
void main() {
  group('Rasi.fromLongitude', () {
    test('maps sign boundaries exactly', () {
      expect(Rasi.fromLongitude(0), Rasi.mesha);
      expect(Rasi.fromLongitude(29.999), Rasi.mesha);
      expect(Rasi.fromLongitude(30), Rasi.vrishabha);
      expect(Rasi.fromLongitude(180), Rasi.tula);
      expect(Rasi.fromLongitude(359.999), Rasi.meena);
    });

    test('wraps past 360 and below 0', () {
      expect(Rasi.fromLongitude(360), Rasi.mesha);
      expect(Rasi.fromLongitude(390), Rasi.vrishabha);
      // Ketu is derived as Rahu + 180, which can go negative before
      // normalisation, so this path is real rather than theoretical.
      expect(Rasi.fromLongitude(-1), Rasi.meena); // 359°
      expect(Rasi.fromLongitude(-30), Rasi.meena); // 330°, start of Meena
      expect(Rasi.fromLongitude(-31), Rasi.kumbha); // 329°, still Kumbha
    });

    test('covers all twelve signs across the circle', () {
      final seen = <Rasi>{};
      for (var d = 0.0; d < 360; d += 1) {
        seen.add(Rasi.fromLongitude(d));
      }
      expect(seen.length, 12);
    });
  });

  group('Nakshatra.fromLongitude', () {
    test('spans 13°20\' each', () {
      expect(Nakshatra.span, closeTo(13.3333, 0.0001));
      expect(Nakshatra.fromLongitude(0), Nakshatra.ashwini);
      expect(Nakshatra.fromLongitude(13.32), Nakshatra.ashwini);
      expect(Nakshatra.fromLongitude(13.34), Nakshatra.bharani);
    });

    test('Revati is the last nakshatra before the wrap', () {
      expect(Nakshatra.fromLongitude(359.99), Nakshatra.revati);
      expect(Nakshatra.fromLongitude(360), Nakshatra.ashwini);
    });

    test('covers all twenty-seven across the circle', () {
      final seen = <Nakshatra>{};
      for (var d = 0.0; d < 360; d += 0.5) {
        seen.add(Nakshatra.fromLongitude(d));
      }
      expect(seen.length, 27);
    });
  });

  group('pada', () {
    test('divides each nakshatra into four quarters', () {
      const quarter = Nakshatra.span / 4; // 3°20'
      expect(Nakshatra.padaFromLongitude(0), 1);
      expect(Nakshatra.padaFromLongitude(quarter * 0.99), 1);
      expect(Nakshatra.padaFromLongitude(quarter * 1.01), 2);
      expect(Nakshatra.padaFromLongitude(quarter * 2.01), 3);
      expect(Nakshatra.padaFromLongitude(quarter * 3.01), 4);
    });

    test('is always 1-4 anywhere on the circle', () {
      for (var d = 0.0; d < 360; d += 0.37) {
        expect(
          Nakshatra.padaFromLongitude(d),
          inInclusiveRange(1, 4),
          reason: 'at $d degrees',
        );
      }
    });
  });

  group('Graha', () {
    test('every graha except Ketu maps to a Swiss Ephemeris body', () {
      for (final g in Graha.values) {
        if (g == Graha.ketu) {
          expect(g.body, isNull, reason: 'Ketu is derived from Rahu');
        } else {
          expect(g.body, isNotNull, reason: g.en);
        }
      }
    });

    test('has Sinhala and Tamil names for every graha', () {
      for (final g in Graha.values) {
        expect(g.si, isNotEmpty, reason: '${g.en} has no Sinhala name');
        expect(g.ta, isNotEmpty, reason: '${g.en} has no Tamil name');
      }
    });
  });

  group('GrahaPosition', () {
    GrahaPosition at(double longitude, {double speed = 1}) => GrahaPosition(
      graha: Graha.sun,
      longitude: longitude,
      latitude: 0,
      speed: speed,
      house: 1,
    );

    test('degreeInRasi is the offset within the sign', () {
      expect(at(0).degreeInRasi, closeTo(0, 1e-9));
      expect(at(45).degreeInRasi, closeTo(15, 1e-9));
      expect(at(359).degreeInRasi, closeTo(29, 1e-9));
    });

    test('negative speed reads as retrograde', () {
      expect(at(100, speed: -0.05).isRetrograde, isTrue);
      expect(at(100, speed: 0.05).isRetrograde, isFalse);
    });
  });
}
