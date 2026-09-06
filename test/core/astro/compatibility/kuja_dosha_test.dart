import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/astro/compatibility/kuja_dosha.dart';
import 'package:nakshatra/core/astro/models.dart';

/// Kuja doṣa (KAN-29).
void main() {
  /// A chart with everything placed where the test wants it.
  ///
  /// Longitudes are given as sign indices so a case reads as "Mars in the 7th
  /// from the lagna" rather than as a number of degrees.
  BirthChart chartWith({
    required int lagnaSign,
    required int marsSign,
    int? moonSign,
    int? venusSign,
  }) {
    GrahaPosition at(Graha g, int sign) => GrahaPosition(
      graha: g,
      longitude: sign * 30.0 + 15,
      latitude: 0,
      speed: 1,
      house: 1,
    );

    return BirthChart(
      julianDayUt: 2451545.0,
      ascendant: lagnaSign * 30.0 + 15,
      midheaven: 0,
      ayanamsa: 23.85,
      positions: {
        for (final g in Graha.values) g: at(g, 0),
        Graha.mars: at(Graha.mars, marsSign),
        Graha.moon: at(Graha.moon, moonSign ?? lagnaSign),
        Graha.venus: at(Graha.venus, venusSign ?? lagnaSign),
      },
    );
  }

  test('the afflicting houses are the classical six', () {
    expect(KujaDosha.afflictingHouses, {1, 2, 4, 7, 8, 12});
  });

  test('Mars in each afflicting house is caught, counted from the lagna', () {
    for (final house in KujaDosha.afflictingHouses) {
      // Put the Moon and Venus somewhere harmless so only the lagna can fire.
      final chart = chartWith(
        lagnaSign: 0,
        marsSign: house - 1,
        moonSign: 4, // Mars lands in the 9th from here for most cases
        venusSign: 4,
      );
      final result = KujaDosha.check(chart);
      expect(
        result.afflictedFrom,
        contains(DoshaReference.lagna),
        reason: 'house $house should afflict',
      );
      expect(result.marsHouse, house);
    }
  });

  test('the safe houses are not flagged from the lagna', () {
    for (var house = 1; house <= 12; house++) {
      if (KujaDosha.afflictingHouses.contains(house)) continue;

      final chart = chartWith(
        lagnaSign: 0,
        marsSign: house - 1,
        moonSign: house - 1, // Mars in the 1st from the Moon would fire,
        venusSign: house - 1, // so place them on Mars deliberately below.
      );
      // Moon and Venus sitting with Mars puts it in their 1st, which does
      // afflict — so judge from the lagna alone here.
      expect(
        KujaDosha.check(chart).afflictedFrom.contains(DoshaReference.lagna),
        isFalse,
        reason: 'house $house should be safe from the lagna',
      );
    }
  });

  test('affliction from the Moon is found independently of the lagna', () {
    // Mars in the 9th from the lagna — safe — but in the 7th from the Moon.
    final chart = chartWith(
      lagnaSign: 0,
      marsSign: 8,
      moonSign: 2,
      venusSign: 8,
    );
    final result = KujaDosha.check(chart, fromVenus: false);

    expect(result.afflictedFrom, contains(DoshaReference.moon));
    expect(result.afflictedFrom, isNot(contains(DoshaReference.lagna)));
    expect(result.hasDosha, isTrue);
  });

  test('Venus can be excluded, since it is the least universal', () {
    // Mars sits on Venus, so the Venus check fires and nothing else does.
    final chart = chartWith(
      lagnaSign: 0,
      marsSign: 8,
      moonSign: 2 + 4,
      venusSign: 8,
    );

    expect(
      KujaDosha.check(chart, fromVenus: true).afflictedFrom,
      contains(DoshaReference.venus),
    );
    expect(
      KujaDosha.check(chart, fromVenus: false).afflictedFrom,
      isNot(contains(DoshaReference.venus)),
    );
  });

  test('more than one reference point reads as severe', () {
    // Mars in the 1st from lagna, Moon and Venus all at once.
    final chart = chartWith(
      lagnaSign: 3,
      marsSign: 3,
      moonSign: 3,
      venusSign: 3,
    );
    final result = KujaDosha.check(chart);

    expect(result.afflictedFrom.length, 3);
    expect(result.isSevere, isTrue);
  });

  test('a single hit is not severe', () {
    final chart = chartWith(
      lagnaSign: 0,
      marsSign: 6, // 7th from lagna
      moonSign: 4, // 3rd from the Moon — safe
      venusSign: 4,
    );
    final result = KujaDosha.check(chart);

    expect(result.hasDosha, isTrue);
    expect(result.isSevere, isFalse);
  });

  group('comparing two charts', () {
    BirthChart afflicted() =>
        chartWith(lagnaSign: 0, marsSign: 6, moonSign: 4, venusSign: 4);
    // Mars in the 3rd from the lagna, and from the Moon and Venus too — a
    // chart that is clean from every reference point, not just the lagna.
    BirthChart clean() =>
        chartWith(lagnaSign: 0, marsSign: 2, moonSign: 0, venusSign: 0);

    test('both afflicted is held to cancel', () {
      final m = KujaDosha.compare(afflicted(), afflicted());
      expect(m.cancelsOut, isTrue);
      expect(m.isUnmatched, isFalse);
    });

    test('one afflicted and one not is the case that matters', () {
      final m = KujaDosha.compare(afflicted(), clean());
      expect(m.isUnmatched, isTrue);
      expect(m.cancelsOut, isFalse);
    });

    test('neither afflicted is neither cancelled nor unmatched', () {
      final m = KujaDosha.compare(clean(), clean());
      expect(m.bride.hasDosha, isFalse);
      expect(m.groom.hasDosha, isFalse);
      expect(m.cancelsOut, isFalse);
      expect(m.isUnmatched, isFalse);
    });
  });

  test('the house count wraps correctly across the zodiac', () {
    // Lagna late in the zodiac with Mars early: the count has to wrap rather
    // than go negative, which is the classic modulo bug here.
    final chart = chartWith(lagnaSign: 10, marsSign: 4, moonSign: 10);
    expect(KujaDosha.check(chart).marsHouse, 7);
  });
}
