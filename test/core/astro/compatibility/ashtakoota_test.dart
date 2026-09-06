import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/astro/compatibility/ashtakoota.dart';
import 'package:nakshatra/core/astro/compatibility/nakshatra_traits.dart';
import 'package:nakshatra/core/astro/models.dart';

/// Aṣṭakūṭa (KAN-29).
///
/// These tables are memorised lists in the tradition, so a typo in one is
/// invisible by inspection and would produce a plausible-looking wrong number.
/// Where a table has an internal pattern the pattern is asserted rather than
/// the list restated — that is what actually catches a mistyped entry.
void main() {
  group('the tables themselves', () {
    test('the eight factors sum to 36', () {
      final total = Koota.values.fold<int>(0, (s, k) => s + k.maximum);
      expect(total, AshtakootaResult.maximum);
    });

    test('every nakṣatra has a gaṇa, and there are nine of each', () {
      final counts = <Gana, int>{};
      for (final n in Nakshatra.values) {
        counts.update(NakshatraTraits.gana(n), (v) => v + 1, ifAbsent: () => 1);
      }
      expect(counts.values, everyElement(9), reason: '$counts');
      expect(counts.length, 3);
    });

    test('nāḍī splits the twenty-seven into three nines', () {
      final counts = <Nadi, int>{};
      for (final n in Nakshatra.values) {
        counts.update(NakshatraTraits.nadi(n), (v) => v + 1, ifAbsent: () => 1);
      }
      expect(counts.values, everyElement(9), reason: '$counts');
    });

    test('nāḍī runs in the classical 1-2-3-3-2-1 cycle', () {
      // The pattern, not the list: a mistyped index shows up here.
      const expected = [
        Nadi.adi, Nadi.madhya, Nadi.antya, //
        Nadi.antya, Nadi.madhya, Nadi.adi,
      ];
      for (var i = 0; i < Nakshatra.values.length; i++) {
        expect(
          NakshatraTraits.nadi(Nakshatra.values[i]),
          expected[i % 6],
          reason: '${Nakshatra.values[i].en} at index $i',
        );
      }
    });

    test('rajju climbs to the head and back down again', () {
      // 5, 14 and 23 are the head; everything else mirrors around them.
      for (final i in [4, 13, 22]) {
        expect(NakshatraTraits.rajju(Nakshatra.values[i]), Rajju.shiro);
      }
      // Symmetry: one before and one after the head must match.
      for (final head in [4, 13, 22]) {
        expect(
          NakshatraTraits.rajju(Nakshatra.values[head - 1]),
          NakshatraTraits.rajju(Nakshatra.values[head + 1]),
          reason: 'rajju is not symmetric around index $head',
        );
      }
    });

    test('fourteen yoni animals cover twenty-seven nakṣatras', () {
      final animals = <YoniAnimal, int>{};
      for (final n in Nakshatra.values) {
        final (animal, _) = NakshatraTraits.yoni(n);
        animals.update(animal, (v) => v + 1, ifAbsent: () => 1);
      }
      expect(animals.length, 14);
      // Thirteen animals appear twice and one appears once — 27 is odd.
      expect(animals.values.where((c) => c == 1).length, 1);
      expect(animals.values.where((c) => c == 2).length, 13);
    });

    test('enmity between animals is mutual', () {
      for (final a in YoniAnimal.values) {
        for (final b in YoniAnimal.values) {
          expect(
            NakshatraTraits.areEnemies(a, b),
            NakshatraTraits.areEnemies(b, a),
            reason: '$a / $b',
          );
        }
      }
    });

    test('every rāśi has exactly one lord and the seven cover all twelve', () {
      final lords = <Graha, int>{};
      for (final r in Rasi.values) {
        lords.update(RasiTraits.lord(r), (v) => v + 1, ifAbsent: () => 1);
      }
      expect(lords.length, 7, reason: 'the nodes rule no sign');
      expect(lords[Graha.sun], 1);
      expect(lords[Graha.moon], 1);
      expect(lords.values.fold<int>(0, (a, b) => a + b), 12);
    });

    test('varṇa follows the elements, three signs each', () {
      final counts = <Varna, int>{};
      for (final r in Rasi.values) {
        counts.update(RasiTraits.varna(r), (v) => v + 1, ifAbsent: () => 1);
      }
      expect(counts.values, everyElement(3), reason: '$counts');
    });

    test('a graha counts itself a friend', () {
      for (final g in Graha.values) {
        expect(GrahaFriendship.regard(g, g), 1);
      }
    });

    test('friendship is allowed to be one-sided', () {
      // Sun counts Mercury a friend; Mercury counts Sun a friend too, but
      // Moon/Mercury is the classic asymmetry — Moon likes Mercury, Mercury
      // does not reciprocate. Flattening this would change graha maitrī.
      expect(GrahaFriendship.regard(Graha.moon, Graha.mercury), 1);
      expect(GrahaFriendship.regard(Graha.mercury, Graha.moon), -1);
    });
  });

  group('scoring', () {
    AshtakootaResult match(Nakshatra bn, Rasi br, Nakshatra gn, Rasi gr) =>
        Ashtakoota.match(
          brideNakshatra: bn,
          brideRasi: br,
          groomNakshatra: gn,
          groomRasi: gr,
        );

    test('a person matched with themselves scores nāḍī zero', () {
      // The same nakṣatra means the same nāḍī, which is the heaviest penalty
      // in the system. A self-match is the clearest demonstration that the
      // rule bites.
      final r = match(
        Nakshatra.ashwini,
        Rasi.mesha,
        Nakshatra.ashwini,
        Rasi.mesha,
      );
      expect(r[Koota.nadi].points, 0);
      expect(r.hasNadiDosha, isTrue);
      // Everything else about a self-match is perfect.
      expect(r[Koota.yoni].points, 4);
      expect(r[Koota.gana].points, 6);
      expect(r[Koota.varna].points, 1);
    });

    test('the total never exceeds 36 or falls below 0', () {
      for (final bn in Nakshatra.values) {
        for (final gn in Nakshatra.values) {
          final r = match(
            bn,
            Rasi.values[bn.index % 12],
            gn,
            Rasi.values[gn.index % 12],
          );
          expect(r.total, inInclusiveRange(0, 36), reason: '${bn.en}/${gn.en}');
        }
      }
    });

    test('no single factor can exceed its maximum', () {
      for (final bn in Nakshatra.values) {
        for (final gn in Nakshatra.values) {
          final r = match(bn, Rasi.mesha, gn, Rasi.tula);
          for (final s in r.scores) {
            expect(
              s.points,
              inInclusiveRange(0, s.maximum.toDouble()),
              reason: '${s.koota.name} for ${bn.en}/${gn.en}',
            );
          }
        }
      }
    });

    test('bhakūṭa is nil at the afflicted separations and full elsewhere', () {
      // 2/12, 5/9 and 6/8 are the afflicted counts.
      for (var offset = 0; offset < 12; offset++) {
        final groom = Rasi.values[offset];
        final r = match(
          Nakshatra.ashwini,
          Rasi.mesha,
          Nakshatra.bharani,
          groom,
        );
        final forward = offset + 1;
        final expectedAfflicted =
            {2, 12}.contains(forward) ||
            {5, 9}.contains(forward) ||
            {6, 8}.contains(forward);

        expect(
          r[Koota.bhakoot].points,
          expectedAfflicted ? 0 : 7,
          reason: 'Aries to ${groom.en} counts $forward',
        );
      }
    });

    test('tāra treats a remainder of zero as the ninth, not the nought', () {
      // Nine positions apart gives remainder 0, which is auspicious. Reading
      // it as "not 3, 5 or 7" by accident works; reading 0 as inauspicious is
      // the common off-by-one and would silently change many matches.
      final r = match(
        Nakshatra.ashwini,
        Rasi.mesha,
        Nakshatra.values[8], // nine along, count 9
        Rasi.mesha,
      );
      expect(r[Koota.tara].points, greaterThan(0));
    });

    test('varṇa is asymmetric, and deliberately so', () {
      // Brahmin bride with a Shudra groom scores nil; swapped, it scores.
      final low = match(
        Nakshatra.ashwini,
        Rasi.karka, // brahmin
        Nakshatra.bharani,
        Rasi.mithuna, // shudra
      );
      final high = match(
        Nakshatra.ashwini,
        Rasi.mithuna,
        Nakshatra.bharani,
        Rasi.karka,
      );
      expect(low[Koota.varna].points, 0);
      expect(high[Koota.varna].points, 1);
    });

    test('a different nāḍī is worth the full eight', () {
      final r = match(
        Nakshatra.ashwini, // adi
        Rasi.mesha,
        Nakshatra.bharani, // madhya
        Rasi.vrishabha,
      );
      expect(r[Koota.nadi].points, 8);
      expect(r.hasNadiDosha, isFalse);
    });

    test('gaṇa grades the three pairings distinctly', () {
      double ganaFor(Nakshatra a, Nakshatra b) =>
          match(a, Rasi.mesha, b, Rasi.mesha)[Koota.gana].points;

      // deva/deva, deva/manushya, deva/rakshasa, manushya/rakshasa
      expect(ganaFor(Nakshatra.ashwini, Nakshatra.mrigashira), 6);
      expect(ganaFor(Nakshatra.ashwini, Nakshatra.bharani), 5);
      expect(ganaFor(Nakshatra.ashwini, Nakshatra.krittika), 1);
      expect(ganaFor(Nakshatra.bharani, Nakshatra.krittika), 0);
    });

    test('every factor reports a reason, never a bare number', () {
      // The UI writes the sentence; this layer must always hand it something
      // to write, or a row appears with a score and no explanation.
      final r = match(
        Nakshatra.rohini,
        Rasi.vrishabha,
        Nakshatra.hasta,
        Rasi.kanya,
      );
      expect(r.scores.length, Koota.values.length);
      for (final s in r.scores) {
        expect(s.detail, isA<KootaDetail>());
      }
    });

    test('scores land on halves at worst, never stranger fractions', () {
      // Half points are real in this system; thirds are not, and would mean
      // a table had been divided when it should have been looked up.
      for (final bn in Nakshatra.values) {
        final r = match(bn, Rasi.mesha, Nakshatra.pushya, Rasi.karka);
        for (final s in r.scores) {
          expect(
            (s.points * 2) % 1,
            0,
            reason: '${s.koota.name} scored ${s.points}',
          );
        }
      }
    });
  });
}
