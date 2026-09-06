import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/astro/models.dart';
import 'package:nakshatra/core/astro/muhurta.dart';
import 'package:nakshatra/core/astro/nekath.dart';
import 'package:nakshatra/core/astro/panchanga_models.dart';

/// Nekath / śubha muhūrta (KAN-22).
///
/// The tables here are classical lists, so a wrong entry yields a plausible
/// recommendation rather than an error — someone would be told Tuesday
/// afternoon is a fine time to move house and nothing would look broken. The
/// tests therefore assert the structure of each table, not just a few spot
/// values.
void main() {
  final sunrise = DateTime(2026, 3, 10, 6, 0);
  final sunset = DateTime(2026, 3, 10, 18, 0);

  Panchanga day({
    Vara vara = Vara.budha,
    Nakshatra nakshatra = Nakshatra.rohini,
    Tithi tithi = Tithi.panchami,
    Yoga yoga = Yoga.siddhi,
    Karana karana = Karana.bava,
    DateTime? nakshatraEnds,
  }) => Panchanga(
    date: DateTime(2026, 3, 10),
    vara: vara,
    tithi: PanchangaElement(value: tithi, endsAt: null),
    paksha: Paksha.shukla,
    nakshatra: PanchangaElement(value: nakshatra, endsAt: nakshatraEnds),
    yoga: PanchangaElement(value: yoga, endsAt: null),
    karana: PanchangaElement(value: karana, endsAt: null),
    sunrise: sunrise,
    sunset: sunset,
  );

  group('the nakṣatra classes', () {
    test('all twenty-seven are classified', () {
      for (final n in Nakshatra.values) {
        expect(Muhurta.classOf(n), isA<NakshatraClass>(), reason: n.en);
      }
    });

    test('the classical counts are 4-5-5-2-3-4-4', () {
      final counts = <NakshatraClass, int>{};
      for (final n in Nakshatra.values) {
        counts.update(Muhurta.classOf(n), (v) => v + 1, ifAbsent: () => 1);
      }
      expect(counts[NakshatraClass.dhruva], 4);
      expect(counts[NakshatraClass.chara], 5);
      expect(counts[NakshatraClass.ugra], 5);
      expect(counts[NakshatraClass.mishra], 2);
      expect(counts[NakshatraClass.kshipra], 3);
      expect(counts[NakshatraClass.mridu], 4);
      expect(counts[NakshatraClass.tikshna], 4);
      expect(counts.values.fold<int>(0, (a, b) => a + b), 27);
    });

    test('the four Uttara-type stars are the fixed ones', () {
      // Dhruva means fixed; the "later" halves of the paired stars plus
      // Rohiṇī are the classical members.
      expect(Muhurta.classOf(Nakshatra.rohini), NakshatraClass.dhruva);
      expect(Muhurta.classOf(Nakshatra.uttaraPhalguni), NakshatraClass.dhruva);
      expect(Muhurta.classOf(Nakshatra.uttaraAshadha), NakshatraClass.dhruva);
      expect(
        Muhurta.classOf(Nakshatra.uttaraBhadrapada),
        NakshatraClass.dhruva,
      );
    });

    test('the Purva-type stars are the fierce ones', () {
      for (final n in [
        Nakshatra.bharani,
        Nakshatra.magha,
        Nakshatra.purvaPhalguni,
        Nakshatra.purvaAshadha,
        Nakshatra.purvaBhadrapada,
      ]) {
        expect(Muhurta.classOf(n), NakshatraClass.ugra, reason: n.en);
      }
    });
  });

  group('tithi groups', () {
    test('rikta falls on the 4th, 9th and 14th', () {
      // The tithis avoided for beginnings. Off by one here would move the
      // penalty onto three innocent days.
      const rikta = [Tithi.chaturthi, Tithi.navami, Tithi.chaturdashi];
      for (final t in Tithi.values) {
        expect(
          Muhurta.groupOf(t) == TithiGroup.rikta,
          rikta.contains(t),
          reason: '${t.en} at index ${t.index}',
        );
      }
    });

    test('the fifteenth is purna, not a wrapped nanda', () {
      // Pūrṇimā and amāvāsyā close the fortnight; landing them on nanda is
      // the classic modulo slip.
      expect(Muhurta.groupOf(Tithi.purnimaAmavasya), TithiGroup.purna);
      expect(Muhurta.groupOf(Tithi.panchami), TithiGroup.purna);
      expect(Muhurta.groupOf(Tithi.dashami), TithiGroup.purna);
    });

    test('each group takes three of the fifteen', () {
      final counts = <TithiGroup, int>{};
      for (final t in Tithi.values) {
        counts.update(Muhurta.groupOf(t), (v) => v + 1, ifAbsent: () => 1);
      }
      expect(counts.values, everyElement(3), reason: '$counts');
    });
  });

  group('activity tables', () {
    test('every activity states what it favours and what it warns against', () {
      for (final a in Activity.values) {
        expect(Muhurta.favours[a], isNotEmpty, reason: a.name);
        expect(Muhurta.warnsAgainst[a], isNotEmpty, reason: a.name);
      }
    });

    test('no class is both favoured and warned against', () {
      // A contradiction here would make the score depend on which branch was
      // checked first.
      for (final a in Activity.values) {
        expect(
          Muhurta.favours[a]!.intersection(Muhurta.warnsAgainst[a]!),
          isEmpty,
          reason: a.name,
        );
      }
    });

    test('the fierce and sharp stars are never favoured by anything', () {
      // They suit demolition and surgery. Any activity favouring them would
      // be a table error.
      for (final a in Activity.values) {
        expect(Muhurta.favours[a], isNot(contains(NakshatraClass.ugra)));
        expect(Muhurta.favours[a], isNot(contains(NakshatraClass.tikshna)));
        expect(Muhurta.warnsAgainst[a], contains(NakshatraClass.ugra));
        expect(Muhurta.warnsAgainst[a], contains(NakshatraClass.tikshna));
      }
    });

    test('the things meant to last avoid the movable stars', () {
      // A marriage and a house are not meant to be temporary.
      expect(
        Muhurta.warnsAgainst[Activity.marriage],
        contains(NakshatraClass.chara),
      );
      expect(
        Muhurta.warnsAgainst[Activity.houseEntry],
        contains(NakshatraClass.chara),
      );
      // Travel and vehicles want exactly the opposite.
      expect(Muhurta.favours[Activity.travel], contains(NakshatraClass.chara));
      expect(Muhurta.favours[Activity.vehicle], contains(NakshatraClass.chara));
    });

    test('nine yogas are held to spoil a beginning', () {
      expect(Muhurta.inauspiciousYogas.length, 9);
      // All must be real members of the twenty-seven.
      for (final y in Muhurta.inauspiciousYogas) {
        expect(Yoga.values, contains(y));
      }
    });
  });

  group('scoring', () {
    int scoreOf(Panchanga p, Activity a) =>
        Muhurta.forActivity(p, a).first.score;

    test('a favourable star lifts the score above a neutral one', () {
      // Rohiṇī is fixed — house entry wants exactly that.
      final good = scoreOf(
        day(nakshatra: Nakshatra.rohini),
        Activity.houseEntry,
      );
      // Kṛttikā is mixed: neither favoured nor warned against.
      final neutral = scoreOf(
        day(nakshatra: Nakshatra.krittika),
        Activity.houseEntry,
      );
      expect(good, greaterThan(neutral));
    });

    test('a warned-against star drops it below neutral', () {
      final bad = scoreOf(
        day(nakshatra: Nakshatra.magha), // ugra
        Activity.marriage,
      );
      final neutral = scoreOf(
        day(nakshatra: Nakshatra.krittika),
        Activity.marriage,
      );
      expect(bad, lessThan(neutral));
    });

    test('the same day scores differently for different activities', () {
      // A movable star helps a journey and hurts a house move. If these came
      // out equal the activity tables would not be reaching the score.
      final p = day(nakshatra: Nakshatra.swati); // chara
      expect(
        scoreOf(p, Activity.travel),
        greaterThan(scoreOf(p, Activity.houseEntry)),
      );
    });

    test('a rikta tithi costs points', () {
      expect(
        scoreOf(day(tithi: Tithi.chaturthi), Activity.business),
        lessThan(scoreOf(day(tithi: Tithi.panchami), Activity.business)),
      );
    });

    test('vishti karana costs points', () {
      expect(
        scoreOf(day(karana: Karana.vishti), Activity.business),
        lessThan(scoreOf(day(karana: Karana.bava), Activity.business)),
      );
    });

    test('an inauspicious yoga costs points', () {
      expect(
        scoreOf(day(yoga: Yoga.vyatipata), Activity.business),
        lessThan(scoreOf(day(yoga: Yoga.siddhi), Activity.business)),
      );
    });

    test('Tuesday and Saturday cost a little', () {
      final wed = scoreOf(day(vara: Vara.budha), Activity.business);
      expect(
        scoreOf(day(vara: Vara.mangala), Activity.business),
        lessThan(wed),
      );
      expect(scoreOf(day(vara: Vara.shani), Activity.business), lessThan(wed));
    });

    test('the score never leaves 0..100, however bad the day', () {
      // Everything wrong at once must not underflow into a negative.
      final worst = day(
        vara: Vara.shani,
        nakshatra: Nakshatra.mula, // tikshna
        tithi: Tithi.chaturdashi, // rikta
        yoga: Yoga.vyatipata,
        karana: Karana.vishti,
      );
      for (final a in Activity.values) {
        for (final w in Muhurta.forActivity(worst, a)) {
          expect(w.score, inInclusiveRange(0, 100), reason: a.name);
        }
      }

      final best = day(
        vara: Vara.guru,
        nakshatra: Nakshatra.rohini,
        tithi: Tithi.panchami,
        yoga: Yoga.siddhi,
        karana: Karana.bava,
      );
      for (final w in Muhurta.forActivity(best, Activity.houseEntry)) {
        expect(w.score, inInclusiveRange(0, 100));
      }
    });

    test('every window carries a reason', () {
      for (final a in Activity.values) {
        for (final w in Muhurta.forActivity(day(), a)) {
          expect(w.reasons, isNotEmpty, reason: a.name);
        }
      }
    });
  });

  group('windows', () {
    test('none overlaps an inauspicious period', () {
      // The whole point of starting from the clear windows.
      final p = day();
      final bad = Nekath.inauspicious(p);

      for (final w in Muhurta.forActivity(p, Activity.business)) {
        for (final b in bad) {
          final overlaps = w.start.isBefore(b.end) && b.start.isBefore(w.end);
          expect(
            overlaps,
            isFalse,
            reason: '${w.start} clashes with ${b.name}',
          );
        }
      }
    });

    test('all windows fall inside daylight', () {
      for (final w in Muhurta.forActivity(day(), Activity.travel)) {
        expect(w.start.isBefore(sunrise), isFalse);
        expect(w.end.isAfter(sunset), isFalse);
        expect(w.end.isAfter(w.start), isTrue);
      }
    });

    test('best first, and ties broken by length', () {
      final windows = Muhurta.forActivity(day(), Activity.business);
      for (var i = 1; i < windows.length; i++) {
        final prev = windows[i - 1];
        final cur = windows[i];
        expect(prev.score, greaterThanOrEqualTo(cur.score));
        if (prev.score == cur.score) {
          expect(prev.duration, greaterThanOrEqualTo(cur.duration));
        }
      }
    });

    test('a window is cut short when an element changes, and says so', () {
      // The day is scored on its sunrise pañcāṅga. Once the nakṣatra ends
      // that score no longer describes the sky, so the recommendation must
      // not run past it.
      final changeAt = DateTime(2026, 3, 10, 9, 30);
      final windows = Muhurta.forActivity(
        day(nakshatraEnds: changeAt),
        Activity.business,
      );

      expect(windows, isNotEmpty);
      for (final w in windows) {
        expect(
          w.end.isAfter(changeAt),
          isFalse,
          reason: '${w.end} runs past the nakṣatra change',
        );
      }
      expect(
        windows.any((w) => w.reasons.contains(MuhurtaReason.shortenedByChange)),
        isTrue,
        reason: 'truncation must be disclosed, not silent',
      );
    });

    test('with no boundaries known, windows run to the end of daylight', () {
      final windows = Muhurta.forActivity(day(), Activity.business);
      expect(
        windows.any(
          (w) => !w.reasons.contains(MuhurtaReason.shortenedByChange),
        ),
        isTrue,
      );
    });
  });
}
