import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/astro/gochara.dart';
import 'package:nakshatra/core/astro/models.dart';

/// Gochara — transits counted from the natal Moon (KAN-31).
///
/// None of this is checkable by looking at the screen: a horoscope that reads
/// fluently while counting houses one off is indistinguishable from a correct
/// one until a reader compares it with their almanac. So the arithmetic and
/// the classical tables are pinned here.
void main() {
  group('counting houses from the janma rasi', () {
    test('a graha in the natal sign is in the first house, not the zeroth', () {
      // Inclusive counting is the convention. Off by one here turns the 12th
      // (loss) into the 1st (the body) - opposite readings.
      expect(Gochara.houseFrom(Rasi.mesha, Rasi.mesha), 1);
      expect(Gochara.houseFrom(Rasi.meena, Rasi.meena), 1);
    });

    test('the next sign along is the second', () {
      expect(Gochara.houseFrom(Rasi.mesha, Rasi.vrishabha), 2);
    });

    test('it wraps around the end of the zodiac', () {
      // Pisces to Aries is one step forward, so the 2nd - not the 11th.
      expect(Gochara.houseFrom(Rasi.meena, Rasi.mesha), 2);
      // Aries to Pisces is the 12th, the sign behind.
      expect(Gochara.houseFrom(Rasi.mesha, Rasi.meena), 12);
    });

    test('it is always between 1 and 12, from every sign to every sign', () {
      for (final from in Rasi.values) {
        for (final to in Rasi.values) {
          final h = Gochara.houseFrom(from, to);
          expect(h, inInclusiveRange(1, 12), reason: '${from.en} -> ${to.en}');
        }
      }
    });

    test('every house from a sign lands on a distinct sign', () {
      // A duplicate would mean two houses collapsing onto one sign.
      for (final from in Rasi.values) {
        final seen = {for (var h = 1; h <= 12; h++) Gochara.rasiAt(from, h)};
        expect(seen.length, 12, reason: from.en);
      }
    });

    test('rasiAt is the inverse of houseFrom', () {
      for (final from in Rasi.values) {
        for (var h = 1; h <= 12; h++) {
          expect(Gochara.houseFrom(from, Gochara.rasiAt(from, h)), h);
        }
      }
    });
  });

  group('the favourability table', () {
    test('every graha has one', () {
      // A missing entry would throw at read time, in the middle of building
      // someone's reading.
      for (final g in Graha.values) {
        expect(Gochara.favourableHouses[g], isNotNull, reason: g.en);
        expect(Gochara.aspects[g], isNotNull, reason: g.en);
      }
    });

    test('the upacaya houses are good for every malefic', () {
      // 3, 6 and 11 - where the tradition says difficulty becomes effort
      // rewarded. True for Sun, Mars, Saturn, Rahu and Ketu.
      for (final g in [
        Graha.sun,
        Graha.mars,
        Graha.saturn,
        Graha.rahu,
        Graha.ketu,
      ]) {
        expect(
          Gochara.favourableHouses[g],
          containsAll([3, 6, 11]),
          reason: g.en,
        );
      }
    });

    test('no house outside 1-12 is listed', () {
      for (final entry in Gochara.favourableHouses.entries) {
        for (final h in entry.value) {
          expect(h, inInclusiveRange(1, 12), reason: entry.key.en);
        }
      }
    });

    test('Jupiter in the 2nd, 5th, 9th and 11th, but not the 1st', () {
      // Jupiter over the natal Moon is the well-known exception: the tradition
      // does not count it as a good transit despite Jupiter being the great
      // benefic.
      expect(Gochara.isFavourable(Graha.jupiter, 2), isTrue);
      expect(Gochara.isFavourable(Graha.jupiter, 5), isTrue);
      expect(Gochara.isFavourable(Graha.jupiter, 9), isTrue);
      expect(Gochara.isFavourable(Graha.jupiter, 11), isTrue);
      expect(Gochara.isFavourable(Graha.jupiter, 1), isFalse);
    });

    test('Saturn gives results only in the 3rd, 6th and 11th', () {
      for (var h = 1; h <= 12; h++) {
        expect(
          Gochara.isFavourable(Graha.saturn, h),
          [3, 6, 11].contains(h),
          reason: 'house $h',
        );
      }
    });
  });

  group('placing the transits', () {
    test('a graha is placed in the house its sign falls in', () {
      // Natal Moon in Cancer, Saturn transiting Virgo: Cancer -> Virgo is 3.
      final placed = Gochara.place(Rasi.karka, {Graha.saturn: Rasi.kanya});

      expect(placed, hasLength(1));
      expect(placed.single.houseFromMoon, 3);
      // The 3rd is one of Saturn's own.
      expect(placed.single.favourable, isTrue);
    });

    test('grahas with no known sign are skipped rather than guessed', () {
      final placed = Gochara.place(Rasi.mesha, {Graha.sun: Rasi.mesha});
      expect(placed.map((p) => p.graha), [Graha.sun]);
    });

    test('placement covers every graha it is given', () {
      final all = {for (final g in Graha.values) g: Rasi.mesha};
      expect(Gochara.place(Rasi.tula, all), hasLength(Graha.values.length));
    });
  });

  group('Saturn phases', () {
    // The transit a Sri Lankan reader knows by name and will check against
    // the almanac.
    test('sade sati is the 12th, 1st and 2nd in order', () {
      const moon = Rasi.karka;

      expect(
        Gochara.saturnPhase(moon, Gochara.rasiAt(moon, 12)),
        SaturnPhase.sadeSatiRising,
      );
      expect(
        Gochara.saturnPhase(moon, Gochara.rasiAt(moon, 1)),
        SaturnPhase.sadeSatiPeak,
      );
      expect(
        Gochara.saturnPhase(moon, Gochara.rasiAt(moon, 2)),
        SaturnPhase.sadeSatiSetting,
      );
    });

    test('all three legs report as sade sati, and nothing else does', () {
      const moon = Rasi.dhanu;
      for (var h = 1; h <= 12; h++) {
        final phase = Gochara.saturnPhase(moon, Gochara.rasiAt(moon, h));
        expect(
          phase.isSadeSati,
          [12, 1, 2].contains(h),
          reason: 'house $h gave $phase',
        );
      }
    });

    test('the 4th is kantaka and the 8th is ashtama', () {
      const moon = Rasi.kumbha;
      expect(
        Gochara.saturnPhase(moon, Gochara.rasiAt(moon, 4)),
        SaturnPhase.kantaka,
      );
      expect(
        Gochara.saturnPhase(moon, Gochara.rasiAt(moon, 8)),
        SaturnPhase.ashtama,
      );
    });

    test('an ordinary house has no name', () {
      const moon = Rasi.simha;
      expect(
        Gochara.saturnPhase(moon, Gochara.rasiAt(moon, 6)),
        SaturnPhase.none,
      );
    });

    test('sade sati is reachable from every natal sign', () {
      // Guards against arithmetic that works from Aries and wraps wrongly
      // elsewhere.
      for (final moon in Rasi.values) {
        final phases = [
          for (var h = 1; h <= 12; h++)
            Gochara.saturnPhase(moon, Gochara.rasiAt(moon, h)),
        ];
        expect(phases.where((p) => p.isSadeSati).length, 3, reason: moon.en);
      }
    });
  });

  group('contacts with the natal chart', () {
    test('same sign is a conjunction', () {
      final c = Gochara.contacts(
        {Graha.jupiter: Rasi.mesha},
        {Graha.moon: Rasi.mesha},
      );

      expect(c, hasLength(1));
      expect(c.single.isConjunction, isTrue);
      expect(c.single.aspect, 1);
    });

    test('every graha aspects the seventh', () {
      for (final g in Graha.values) {
        final c = Gochara.contacts(
          {g: Rasi.mesha},
          {Graha.sun: Rasi.tula}, // Aries -> Libra is the 7th
        );
        expect(c.single.aspect, 7, reason: g.en);
      }
    });

    test('Saturn also aspects the third and the tenth', () {
      final offsets = <int>{};
      for (var h = 1; h <= 12; h++) {
        final c = Gochara.contacts(
          {Graha.saturn: Rasi.mesha},
          {Graha.moon: Gochara.rasiAt(Rasi.mesha, h)},
        );
        if (c.isNotEmpty) offsets.add(c.single.aspect);
      }
      expect(offsets, {1, 3, 7, 10});
    });

    test('Jupiter aspects the fifth, seventh and ninth', () {
      final offsets = <int>{};
      for (var h = 1; h <= 12; h++) {
        final c = Gochara.contacts(
          {Graha.jupiter: Rasi.makara},
          {Graha.venus: Gochara.rasiAt(Rasi.makara, h)},
        );
        if (c.isNotEmpty) offsets.add(c.single.aspect);
      }
      expect(offsets, {1, 5, 7, 9});
    });

    test('Mars aspects the fourth, seventh and eighth', () {
      final offsets = <int>{};
      for (var h = 1; h <= 12; h++) {
        final c = Gochara.contacts(
          {Graha.mars: Rasi.vrischika},
          {Graha.sun: Gochara.rasiAt(Rasi.vrischika, h)},
        );
        if (c.isNotEmpty) offsets.add(c.single.aspect);
      }
      expect(offsets, {1, 4, 7, 8});
    });

    test('a graha that reaches nothing produces no contact', () {
      // Aries to Taurus is the 2nd, which nothing aspects.
      expect(
        Gochara.contacts({Graha.sun: Rasi.mesha}, {Graha.moon: Rasi.vrishabha}),
        isEmpty,
      );
    });

    test('one transiting graha can reach several natal ones', () {
      final c = Gochara.contacts(
        {Graha.jupiter: Rasi.mesha},
        {
          Graha.sun: Rasi.mesha, // conjunct
          Graha.moon: Rasi.simha, // 5th
          Graha.mars: Rasi.tula, // 7th
          Graha.venus: Rasi.vrishabha, // 2nd - nothing
        },
      );

      expect(
        c.map((x) => x.natal),
        containsAll([Graha.sun, Graha.moon, Graha.mars]),
      );
      expect(c.map((x) => x.natal), isNot(contains(Graha.venus)));
    });
  });
}
