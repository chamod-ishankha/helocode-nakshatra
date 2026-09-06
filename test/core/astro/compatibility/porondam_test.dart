import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/astro/compatibility/nakshatra_traits.dart';
import 'package:nakshatra/core/astro/compatibility/porondam.dart';
import 'package:nakshatra/core/astro/models.dart';

/// Porondam (KAN-29).
void main() {
  PorondamResult match(Nakshatra bn, Rasi br, Nakshatra gn, Rasi gr) =>
      Porondams.match(
        brideNakshatra: bn,
        brideRasi: br,
        groomNakshatra: gn,
        groomRasi: gr,
      );

  group('counting', () {
    test('a nakṣatra counted to itself is one, not zero', () {
      // Inclusive counting is the tradition's convention. Off by one here
      // shifts dina, mahendra and strī dīrgha all at once.
      for (final n in Nakshatra.values) {
        expect(Porondams.countTo(n, n), 1, reason: n.en);
      }
    });

    test('counting wraps forward around the twenty-seven', () {
      expect(Porondams.countTo(Nakshatra.ashwini, Nakshatra.bharani), 2);
      expect(Porondams.countTo(Nakshatra.revati, Nakshatra.ashwini), 2);
      expect(Porondams.countTo(Nakshatra.ashwini, Nakshatra.revati), 27);
    });

    test('every count lands in 1..27', () {
      for (final a in Nakshatra.values) {
        for (final b in Nakshatra.values) {
          expect(Porondams.countTo(a, b), inInclusiveRange(1, 27));
        }
      }
    });
  });

  group('vedha pairs', () {
    test('thirteen pairs cover twenty-six of the twenty-seven', () {
      final covered = <Nakshatra>{};
      for (final (a, b) in Porondams.vedhaPairs) {
        covered.addAll([a, b]);
      }
      expect(Porondams.vedhaPairs.length, 13);
      expect(covered.length, 26, reason: 'a nakṣatra is listed twice');
    });

    test('Mṛgaśira is the one left without a counterpart', () {
      final covered = <Nakshatra>{};
      for (final (a, b) in Porondams.vedhaPairs) {
        covered.addAll([a, b]);
      }
      final unpaired = Nakshatra.values
          .where((n) => !covered.contains(n))
          .toList();
      // Twenty-seven is odd, so exactly one must be unpaired. Which one is a
      // fact about the table, and worth pinning.
      expect(unpaired, [Nakshatra.mrigashira]);
    });

    test('piercing is mutual', () {
      for (final (a, b) in Porondams.vedhaPairs) {
        expect(
          match(a, Rasi.mesha, b, Rasi.mesha)[Porondam.vedha].verdict,
          PorondamVerdict.poor,
        );
        expect(
          match(b, Rasi.mesha, a, Rasi.mesha)[Porondam.vedha].verdict,
          PorondamVerdict.poor,
        );
      }
    });

    test('an unpierced pairing passes', () {
      expect(
        match(
          Nakshatra.mrigashira,
          Rasi.mesha,
          Nakshatra.ashwini,
          Rasi.mesha,
        )[Porondam.vedha].verdict,
        PorondamVerdict.good,
      );
    });
  });

  group('rajju', () {
    test('the same limb fails, a different limb passes', () {
      // The only porondam failed by sameness rather than difference.
      for (final a in Nakshatra.values) {
        for (final b in Nakshatra.values) {
          final same = NakshatraTraits.rajju(a) == NakshatraTraits.rajju(b);
          final verdict = match(
            a,
            Rasi.mesha,
            b,
            Rasi.mesha,
          )[Porondam.rajju].verdict;
          expect(
            verdict,
            same ? PorondamVerdict.poor : PorondamVerdict.good,
            reason: '${a.en} / ${b.en}',
          );
        }
      }
    });

    test('a self-match always fails rajju, and is surfaced', () {
      final r = match(
        Nakshatra.ashwini,
        Rasi.mesha,
        Nakshatra.ashwini,
        Rasi.mesha,
      );
      expect(r.hasRajjuDosha, isTrue);
    });
  });

  group('direction matters', () {
    test('strī dīrgha reverses when the pair is swapped', () {
      // The groom's nakṣatra should lie well ahead of the bride's, so a
      // pairing that passes one way should not pass the other.
      final forward = match(
        Nakshatra.ashwini,
        Rasi.mesha,
        Nakshatra.uttaraAshadha, // 21 ahead
        Rasi.mesha,
      )[Porondam.streeDeergha].verdict;

      final reversed = match(
        Nakshatra.uttaraAshadha,
        Rasi.mesha,
        Nakshatra.ashwini, // 7 ahead
        Rasi.mesha,
      )[Porondam.streeDeergha].verdict;

      expect(forward, PorondamVerdict.good);
      expect(reversed, PorondamVerdict.poor);
    });

    test('a near-behind groom is the case strī dīrgha exists to catch', () {
      expect(
        match(
          Nakshatra.rohini,
          Rasi.mesha,
          Nakshatra.mrigashira, // one ahead
          Rasi.mesha,
        )[Porondam.streeDeergha].verdict,
        PorondamVerdict.poor,
      );
    });

    test('rāśi asks the groom to be seventh or beyond', () {
      for (var offset = 0; offset < 12; offset++) {
        final verdict = match(
          Nakshatra.ashwini,
          Rasi.mesha,
          Nakshatra.bharani,
          Rasi.values[offset],
        )[Porondam.rasi].verdict;

        final count = offset + 1;
        expect(
          verdict,
          count >= 7
              ? PorondamVerdict.good
              : count == 1
              ? PorondamVerdict.partial
              : PorondamVerdict.poor,
          reason: 'count $count',
        );
      }
    });
  });

  group('the result as a whole', () {
    test('twelve are judged, and the gap to twenty is explicit', () {
      final r = match(
        Nakshatra.rohini,
        Rasi.vrishabha,
        Nakshatra.hasta,
        Rasi.kanya,
      );
      expect(r.judged, Porondam.values.length);
      expect(r.judged, 12);
      // The eight that vary between almanacs are named as absent rather than
      // guessed at, so the number here is honest.
      expect(
        r.judged + Porondam.remainingAreSourceDependent,
        Porondam.traditionalTotal,
      );
    });

    test('matched never exceeds judged', () {
      for (final a in Nakshatra.values) {
        final r = match(a, Rasi.mesha, Nakshatra.pushya, Rasi.karka);
        expect(r.matched, inInclusiveRange(0, r.judged));
      }
    });

    test('every porondam returns a verdict, none silently missing', () {
      for (final a in Nakshatra.values) {
        final r = match(
          a,
          Rasi.values[a.index % 12],
          Nakshatra.values[(a.index + 7) % 27],
          Rasi.values[(a.index + 3) % 12],
        );
        expect(
          r.scores.map((s) => s.porondam).toSet(),
          Porondam.values.toSet(),
          reason: a.en,
        );
      }
    });

    test('a self-match fails nāḍī and rajju but passes vedha', () {
      // Same nakṣatra means same nāḍī and same rajju; a nakṣatra never
      // pierces itself.
      final r = match(Nakshatra.hasta, Rasi.kanya, Nakshatra.hasta, Rasi.kanya);
      expect(r[Porondam.nadi].verdict, PorondamVerdict.poor);
      expect(r[Porondam.rajju].verdict, PorondamVerdict.poor);
      expect(r[Porondam.vedha].verdict, PorondamVerdict.good);
      expect(r[Porondam.yoni].verdict, PorondamVerdict.good);
    });
  });
}
