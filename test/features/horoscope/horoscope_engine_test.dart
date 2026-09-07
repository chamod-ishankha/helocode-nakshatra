import 'package:flutter_test/flutter_test.dart';

import 'package:nakshatra/core/astro/models.dart';
import 'package:nakshatra/features/horoscope/domain/fragment.dart';
import 'package:nakshatra/features/horoscope/domain/horoscope_engine.dart';
import 'package:nakshatra/features/horoscope/domain/horoscope_signals.dart';

/// The horoscope engine (KAN-31).
///
/// Two properties matter and neither is visible on screen. The reading must be
/// identical on every device for a given sign and day — two friends comparing
/// phones, or one reader reopening a screenshot in the evening. And it must
/// not repeat itself within a month, which is the difference between an app
/// people open daily and one they stop trusting in a fortnight.
void main() {
  _axisTests();
  _strideTests();

  /// A sky. Defaults put nothing remarkable anywhere.
  Map<Graha, Rasi> sky({
    Rasi moon = Rasi.mesha,
    Rasi saturn = Rasi.simha,
    Rasi jupiter = Rasi.mithuna,
  }) => {
    Graha.sun: Rasi.mesha,
    Graha.moon: moon,
    Graha.mars: Rasi.vrishabha,
    Graha.mercury: Rasi.mesha,
    Graha.jupiter: jupiter,
    Graha.venus: Rasi.meena,
    Graha.saturn: saturn,
    Graha.rahu: Rasi.tula,
    Graha.ketu: Rasi.mesha,
  };

  HoroscopeSignals signalsFor(
    DateTime date, {
    Rasi rasi = Rasi.karka,
    Map<Graha, Rasi>? transiting,
  }) => HoroscopeSignals.from(
    rasi: rasi,
    date: date,
    transiting: transiting ?? sky(),
  );

  /// A pool of [n] always-eligible fragments in one category.
  List<Fragment> pool(HoroscopeCategory category, int n) => [
    for (var i = 0; i < n; i++)
      Fragment(
        id: '${category.name}-$i',
        category: category,
        text: 'Sentence $i.',
      ),
  ];

  List<Fragment> fullSet({int perCategory = 40}) => [
    for (final c in HoroscopeCategory.values) ...pool(c, perCategory),
  ];

  group('determinism', () {
    test('the same sign and day give the same reading every time', () {
      final date = DateTime(2026, 9, 7);
      final fragments = fullSet();

      final a = HoroscopeEngine.build(
        signals: signalsFor(date),
        fragments: fragments,
      );
      final b = HoroscopeEngine.build(
        signals: signalsFor(date),
        fragments: fragments,
      );

      expect(a.fragmentIds, b.fragmentIds);
      expect(a.luckyNumber, b.luckyNumber);
      expect(a.luckyColour, b.luckyColour);
    });

    test('the time of day does not change it', () {
      // Someone opening the app at breakfast and again at midnight must see
      // one reading, not two.
      final fragments = fullSet();
      final morning = HoroscopeEngine.build(
        signals: signalsFor(DateTime(2026, 9, 7, 6, 30)),
        fragments: fragments,
      );
      final night = HoroscopeEngine.build(
        signals: signalsFor(DateTime(2026, 9, 7, 23, 45)),
        fragments: fragments,
      );

      expect(morning.fragmentIds, night.fragmentIds);
    });

    test('reordering the fragment file does not change the reading', () {
      // Selection sorts by id rather than trusting file order, so an author
      // moving a line in KAN-32 cannot silently change what everyone reads.
      final date = DateTime(2026, 9, 7);
      final forwards = fullSet();
      final backwards = forwards.reversed.toList();

      expect(
        HoroscopeEngine.build(
          signals: signalsFor(date),
          fragments: forwards,
        ).fragmentIds,
        HoroscopeEngine.build(
          signals: signalsFor(date),
          fragments: backwards,
        ).fragmentIds,
      );
    });

    test('different signs read differently on the same day', () {
      // Twelve identical horoscopes would be noticed immediately.
      final date = DateTime(2026, 9, 7);
      final fragments = fullSet();

      final readings = {
        for (final r in Rasi.values)
          r: HoroscopeEngine.build(
            signals: signalsFor(date, rasi: r),
            fragments: fragments,
          ).fragmentIds.join('|'),
      };

      expect(readings.values.toSet().length, greaterThan(6));
    });
  });

  group('not repeating', () {
    test('a pool of 40 does not repeat a line in 31 days', () {
      // The property the daily habit depends on.
      final fragments = pool(HoroscopeCategory.career, 40);
      final seen = <String>[];

      for (var d = 1; d <= 31; d++) {
        final h = HoroscopeEngine.build(
          signals: signalsFor(DateTime(2026, 3, d)),
          fragments: fragments,
        );
        seen.add(h[HoroscopeCategory.career]!);
      }

      expect(seen.toSet().length, 31, reason: 'a line repeated within a month');
    });

    test('consecutive days differ even with a pool of two', () {
      // The smallest pool that can alternate. A hash-only pick would collide
      // about half the time here; stepping cannot.
      final fragments = pool(HoroscopeCategory.money, 2);

      String on(int day) => HoroscopeEngine.build(
        signals: signalsFor(DateTime(2026, 3, day)),
        fragments: fragments,
      )[HoroscopeCategory.money]!;

      for (var d = 1; d < 10; d++) {
        expect(on(d), isNot(on(d + 1)), reason: 'days $d and ${d + 1}');
      }
    });

    test('the general section does not repeat itself within a day', () {
      // It draws several sentences from one pool; the same line twice in one
      // paragraph is the most visible failure there is.
      final fragments = pool(HoroscopeCategory.general, 10);
      final h = HoroscopeEngine.build(
        signals: signalsFor(DateTime(2026, 9, 7)),
        fragments: fragments,
      );

      expect(h.fragmentIds.toSet().length, h.fragmentIds.length);
      expect(h.fragmentIds.length, greaterThan(1));
    });

    test('a year of readings stays varied', () {
      final fragments = pool(HoroscopeCategory.health, 40);
      final seen = <String>{};
      for (var d = 0; d < 365; d++) {
        final h = HoroscopeEngine.build(
          signals: signalsFor(DateTime(2026, 1, 1).add(Duration(days: d))),
          fragments: fragments,
        );
        seen.add(h[HoroscopeCategory.health]!);
      }
      // Every line in the pool should get used across a year.
      expect(seen.length, 40);
    });
  });

  group('matching', () {
    test('a fragment only appears when its condition holds', () {
      final sadeSatiOnly = Fragment(
        id: 'x',
        category: HoroscopeCategory.advice,
        text: 'Saturn is heavy on you.',
        requires: const {'saturn.sadeSati'},
      );
      final always = Fragment(
        id: 'y',
        category: HoroscopeCategory.advice,
        text: 'An ordinary day.',
      );

      // Natal Moon in Cancer, Saturn in Cancer: sade sati peak.
      final during = signalsFor(
        DateTime(2026, 9, 7),
        transiting: sky(saturn: Rasi.karka),
      );
      // Saturn in Leo is the 2nd from Cancer, which is still sade sati, so
      // move it well away.
      final outside = signalsFor(
        DateTime(2026, 9, 7),
        transiting: sky(saturn: Rasi.dhanu),
      );

      expect(during.tags, contains('saturn.sadeSati'));
      expect(outside.tags, isNot(contains('saturn.sadeSati')));

      // During sade sati either line may be chosen - the engine rotates
      // rather than always preferring the more specific one, because
      // preferring it would show the same sade sati sentence every day for
      // seven and a half years.
      expect(
        HoroscopeEngine.build(
          signals: during,
          fragments: [sadeSatiOnly, always],
        ).fragmentIds.single,
        anyOf('x', 'y'),
      );
      expect(
        HoroscopeEngine.build(
          signals: outside,
          fragments: [sadeSatiOnly, always],
        ).fragmentIds,
        ['y'],
      );
    });

    test('an excluded tag disqualifies a fragment', () {
      // Cheerful money copy must stay away during sade sati even though
      // nothing in the money tags rules it out.
      final cheerful = Fragment(
        id: 'cheer',
        category: HoroscopeCategory.money,
        text: 'Spend freely.',
        excludes: const {'saturn.sadeSati'},
      );

      final during = signalsFor(
        DateTime(2026, 9, 7),
        transiting: sky(saturn: Rasi.karka),
      );

      expect(
        HoroscopeEngine.build(signals: during, fragments: [cheerful]).sections,
        isEmpty,
      );
    });

    test('specific copy is preferred over generic', () {
      final specific = Fragment(
        id: 'specific',
        category: HoroscopeCategory.love,
        text: 'Written for today.',
        requires: const {'saturn.sadeSati', 'mood.hard'},
      );
      final generic = Fragment(
        id: 'generic',
        category: HoroscopeCategory.love,
        text: 'Written for any day.',
      );

      final signals = signalsFor(
        DateTime(2026, 9, 7),
        transiting: sky(saturn: Rasi.karka),
      );

      if (signals.tags.containsAll(specific.requires)) {
        expect(
          HoroscopeEngine.build(
            signals: signals,
            fragments: [generic, specific],
          ).fragmentIds,
          ['specific'],
        );
      }
    });

    test('a category with nothing eligible is left out, not left blank', () {
      // An empty heading looks broken. Better to show fewer sections.
      final h = HoroscopeEngine.build(
        signals: signalsFor(DateTime(2026, 9, 7)),
        fragments: pool(HoroscopeCategory.career, 3),
      );

      expect(h.sections.keys, [HoroscopeCategory.career]);
      expect(h[HoroscopeCategory.love], isNull);
    });

    test('a reading can be produced with no chart at all', () {
      // Before onboarding finishes, and for anyone whose birth time is
      // unknown, there is still a rasi-wide reading to show.
      final s = signalsFor(DateTime(2026, 9, 7));
      expect(s.dashaLord, isNull);
      expect(s.contacts, isEmpty);
      expect(
        HoroscopeEngine.build(signals: s, fragments: fullSet()).sections,
        isNotEmpty,
      );
    });
  });

  group('lucky number and colour', () {
    test('the number is always 1 to 9', () {
      for (var d = 0; d < 200; d++) {
        for (final r in [Rasi.mesha, Rasi.karka, Rasi.meena]) {
          final h = HoroscopeEngine.build(
            signals: signalsFor(
              DateTime(2026, 1, 1).add(Duration(days: d)),
              rasi: r,
            ),
            fragments: fullSet(),
          );
          expect(h.luckyNumber, inInclusiveRange(1, 9));
        }
      }
    });

    test('both change from day to day', () {
      // A number that never moves reads as broken.
      final numbers = <int>{};
      final colours = <String>{};
      for (var d = 0; d < 30; d++) {
        final h = HoroscopeEngine.build(
          signals: signalsFor(DateTime(2026, 5, 1).add(Duration(days: d))),
          fragments: fullSet(),
        );
        numbers.add(h.luckyNumber);
        colours.add(h.luckyColour);
      }
      expect(numbers.length, greaterThan(4));
      expect(colours.length, greaterThan(4));
    });
  });

  group('mood', () {
    test('sade sati pushes the day darker', () {
      final calm = signalsFor(
        DateTime(2026, 9, 7),
        transiting: sky(saturn: Rasi.dhanu),
      );
      final heavy = signalsFor(
        DateTime(2026, 9, 7),
        transiting: sky(saturn: Rasi.karka),
      );

      expect(heavy.mood, lessThan(calm.mood));
    });

    test('mood stays within its stated range', () {
      for (final r in Rasi.values) {
        for (final sat in Rasi.values) {
          final s = signalsFor(
            DateTime(2026, 9, 7),
            rasi: r,
            transiting: sky(saturn: sat),
          );
          expect(s.mood, inInclusiveRange(-3, 3));
          expect(s.tags, contains(anyOf(startsWith('mood.'))));
        }
      }
    });

    test('a hard day still produces a full-length general section', () {
      // The temptation is to say less on a bad day; the opposite is right,
      // because that is the day the reader wants guidance.
      expect(HoroscopeEngine.generalSentences(-3), 3);
      expect(HoroscopeEngine.generalSentences(3), 3);
      expect(HoroscopeEngine.generalSentences(0), 2);
    });
  });

  group('signals', () {
    test('every placed graha contributes a house tag', () {
      final s = signalsFor(DateTime(2026, 9, 7));
      for (final t in s.transits) {
        expect(s.tags, contains('${t.graha.name}.house.${t.houseFromMoon}'));
      }
    });

    test('a graha is tagged favourable or difficult, never both', () {
      final s = signalsFor(DateTime(2026, 9, 7));
      for (final t in s.transits) {
        final fav = s.tags.contains('${t.graha.name}.favourable');
        final diff = s.tags.contains('${t.graha.name}.difficult');
        expect(fav != diff, isTrue, reason: t.graha.en);
      }
    });

    test('the date is reduced to a calendar day', () {
      final s = signalsFor(DateTime(2026, 9, 7, 18, 42, 11));
      expect(s.date, DateTime(2026, 9, 7));
    });
  });
}

/// Reading from the lagna as well as the Moon sign.
///
/// Sri Lanka reads both: people identify by their lagna, while the classical
/// gochara tables are stated from the janma rasi. Offering both is only
/// honest if the two actually differ - a toggle between identical readings
/// would be worse than picking one.
void _axisTests() {
  Map<Graha, Rasi> sky() => {
    Graha.sun: Rasi.simha,
    Graha.moon: Rasi.tula,
    Graha.mars: Rasi.kanya,
    Graha.mercury: Rasi.simha,
    Graha.jupiter: Rasi.karka,
    Graha.venus: Rasi.kanya,
    Graha.saturn: Rasi.meena,
    Graha.rahu: Rasi.kumbha,
    Graha.ketu: Rasi.simha,
  };

  List<Fragment> pool(HoroscopeCategory c, int n) => [
    for (var i = 0; i < n; i++)
      Fragment(id: '${c.name}-$i', category: c, text: 'Sentence $i.'),
  ];

  List<Fragment> fullSet() => [
    for (final c in HoroscopeCategory.values) ...pool(c, 40),
  ];

  Horoscope reading(Rasi from) => HoroscopeEngine.build(
    signals: HoroscopeSignals.from(
      rasi: from,
      date: DateTime(2026, 9, 7),
      transiting: sky(),
    ),
    fragments: fullSet(),
  );

  group('lagna and rasi', () {
    test('two different signs give two different readings', () {
      // The reported case: lagna Virgo, Moon in Pisces. Opposite signs, so
      // every transit sits in the opposite house and the readings must not
      // come out the same.
      final byLagna = reading(Rasi.kanya);
      final byRasi = reading(Rasi.meena);

      expect(byLagna.fragmentIds, isNot(byRasi.fragmentIds));
    });

    test('the houses are genuinely counted from a different sign', () {
      final lagna = HoroscopeSignals.from(
        rasi: Rasi.kanya,
        date: DateTime(2026, 9, 7),
        transiting: sky(),
      );
      final rasi = HoroscopeSignals.from(
        rasi: Rasi.meena,
        date: DateTime(2026, 9, 7),
        transiting: sky(),
      );

      // Saturn is in Pisces. From Virgo that is the 7th; from Pisces it is
      // the 1st, which is sade sati.
      expect(lagna.tags, contains('saturn.house.7'));
      expect(rasi.tags, contains('saturn.house.1'));
      expect(rasi.tags, contains('saturn.sadeSati'));
      expect(lagna.tags, isNot(contains('saturn.sadeSati')));
    });

    test('the same sign on both axes gives the same reading', () {
      // Which is why the screen collapses to one reading rather than showing
      // a toggle between two identical ones.
      expect(reading(Rasi.kanya).fragmentIds, reading(Rasi.kanya).fragmentIds);
    });

    test('every sign produces a full reading on either axis', () {
      for (final r in Rasi.values) {
        expect(
          reading(r).sections.length,
          HoroscopeCategory.values.length,
          reason: r.en,
        );
      }
    });
  });
}

/// Multi-sentence sections must not recycle yesterday's lines.
void _strideTests() {
  List<Fragment> pool(int n) => [
    for (var i = 0; i < n; i++)
      Fragment(
        id: 'general-$i',
        category: HoroscopeCategory.general,
        text: 'Sentence $i.',
      ),
  ];

  Horoscope on(int day, List<Fragment> fragments) => HoroscopeEngine.build(
    signals: HoroscopeSignals.from(
      rasi: Rasi.meena,
      date: DateTime(2026, 3, day),
      transiting: {
        Graha.sun: Rasi.mesha,
        Graha.moon: Rasi.mesha,
        Graha.mars: Rasi.vrishabha,
        Graha.mercury: Rasi.mesha,
        Graha.jupiter: Rasi.mithuna,
        Graha.venus: Rasi.meena,
        Graha.saturn: Rasi.simha,
        Graha.rahu: Rasi.tula,
        Graha.ketu: Rasi.mesha,
      },
    ),
    fragments: fragments,
  );

  group('the general section across consecutive days', () {
    test('shares no sentence with yesterday', () {
      // Picking adjacent slots would carry two of three sentences over to the
      // next day, so a reader sees the same lines three days running while
      // the selection still looks like it is advancing.
      final fragments = pool(30);
      for (var d = 1; d < 28; d++) {
        final today = on(d, fragments).fragmentIds.toSet();
        final tomorrow = on(d + 1, fragments).fragmentIds.toSet();
        expect(
          today.intersection(tomorrow),
          isEmpty,
          reason: 'days $d and ${d + 1} share a sentence',
        );
      }
    });

    test('never prints the same sentence twice in one paragraph', () {
      // Including when the pool is barely larger than the number drawn.
      for (final size in [2, 3, 4, 5, 12, 30]) {
        final ids = on(9, pool(size)).fragmentIds;
        expect(ids.toSet().length, ids.length, reason: 'pool of $size');
      }
    });

    test('still spends the whole pool over a month', () {
      final fragments = pool(30);
      final seen = <String>{};
      for (var d = 1; d <= 30; d++) {
        seen.addAll(on(d, fragments).fragmentIds);
      }
      expect(seen.length, 30);
    });
  });
}
