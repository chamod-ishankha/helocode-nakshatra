import '../../../core/astro/models.dart';
import 'fragment.dart';
import 'horoscope_signals.dart';

/// A finished daily reading.
class Horoscope {
  const Horoscope({
    required this.rasi,
    required this.date,
    required this.sections,
    required this.luckyNumber,
    required this.luckyColour,
    required this.mood,
    required this.fragmentIds,
  });

  final Rasi rasi;
  final DateTime date;
  final Map<HoroscopeCategory, String> sections;
  final int luckyNumber;
  final String luckyColour;
  final int mood;

  /// Which fragments were used, in order. Not shown to the reader — it is how
  /// repetition is tested and how a complaint about a specific line can be
  /// traced back to the copy that produced it.
  final List<String> fragmentIds;

  String? operator [](HoroscopeCategory c) => sections[c];
}

/// Assembles a daily reading from authored fragments (KAN-31).
///
/// ## Deterministic, not random
///
/// The same sign on the same day must produce the same reading on every
/// device, forever. Two people comparing phones is the obvious case; the
/// harder one is a reader who screenshots their morning horoscope and reopens
/// it that evening. So there is no RNG anywhere: selection is a pure function
/// of (sign, category, date).
///
/// That rules out [Object.hashCode], which Dart does not guarantee to be
/// stable across runs, platforms or SDK versions. [_hash] is FNV-1a, written
/// out here so the numbers can never drift underneath the app.
///
/// ## Not repeating within a month
///
/// Picking by hash alone would let the same line land two days running about
/// one time in N. Instead the day advances one step through the eligible
/// pool, so a stable pool of N fragments cannot repeat until N days have
/// passed. Whether N is large enough to cover a month is KAN-32's job; the
/// engine's job is to spend the pool it is given as slowly as possible.
abstract final class HoroscopeEngine {
  /// Categories every reading tries to fill, in the order they are shown.
  static const List<HoroscopeCategory> sectionOrder = [
    HoroscopeCategory.general,
    HoroscopeCategory.career,
    HoroscopeCategory.money,
    HoroscopeCategory.love,
    HoroscopeCategory.health,
    HoroscopeCategory.advice,
  ];

  /// How many sentences the general section is built from, by mood.
  ///
  /// A bright day gets a little more room than an ordinary one. Varying the
  /// length is most of what stops consecutive days reading mechanically.
  static int generalSentences(int mood) => switch (mood) {
    >= 2 => 3,
    <= -2 => 3,
    _ => 2,
  };

  static const List<String> _colours = [
    'white',
    'red',
    'yellow',
    'green',
    'blue',
    'orange',
    'brown',
    'gold',
    'silver',
    'purple',
  ];

  /// Builds the reading for [signals] out of [fragments].
  ///
  /// Fragments for other languages are simply a different list with the same
  /// ids, so the choice of language cannot change which prediction is made.
  ///
  /// [avoid] is yesterday's line ids. Rotation alone cannot guarantee that two
  /// consecutive days differ: when the slot a day lands on is not eligible the
  /// search walks forward, and two different starting points can walk into the
  /// same line. Excluding yesterday explicitly is the only exact fix, and
  /// repeating a line the very next day is the repetition a reader notices
  /// first.
  static Horoscope build({
    required HoroscopeSignals signals,
    required List<Fragment> fragments,
    Set<String> avoid = const {},
  }) {
    final sections = <HoroscopeCategory, String>{};
    final used = <String>[];

    for (final category in sectionOrder) {
      final wanted = category == HoroscopeCategory.general
          ? generalSentences(signals.mood)
          : 1;

      final picked = _pick(
        signals: signals,
        fragments: fragments,
        category: category,
        count: wanted,
        avoid: avoid,
      );
      if (picked.isEmpty) continue;

      used.addAll(picked.map((f) => f.id));
      sections[category] = picked.map((f) => f.text).join(' ');
    }

    return Horoscope(
      rasi: signals.rasi,
      date: signals.date,
      sections: sections,
      luckyNumber: _luckyNumber(signals),
      luckyColour: _luckyColour(signals),
      mood: signals.mood,
      fragmentIds: used,
    );
  }

  /// Chooses [count] distinct fragments for one category.
  ///
  /// ## How the day picks a line
  ///
  /// Today's eligible lines are put in a fixed order and indexed by the day
  /// number, so each day steps one place along. Two earlier attempts are worth
  /// recording because both look right:
  ///
  /// Ordering by id groups every conditional line together — `car-sade` sorts
  /// after `car-01`..`car-30` — so the ordering is mostly ordinary copy
  /// followed by a block that is ineligible on most days. Ordering by a hash
  /// of the id scatters them, which is what this does.
  ///
  /// Rotating over the *whole* category and stepping past ineligible lines is
  /// worse still: one ineligible slot at position s sends today to s+1, and
  /// tomorrow starts at s+1 and lands on the same line. Indexing into the
  /// eligible lines instead means consecutive days move one eligible line
  /// apart by construction.
  static List<Fragment> _pick({
    required HoroscopeSignals signals,
    required List<Fragment> fragments,
    required HoroscopeCategory category,
    required int count,
    Set<String> avoid = const {},
  }) {
    final eligible =
        [
          for (final f in fragments)
            if (f.category == category && f.matches(signals.tags)) f,
        ]..sort((a, b) {
          final byHash = _hash(a.id).compareTo(_hash(b.id));
          return byHash != 0 ? byHash : a.id.compareTo(b.id);
        });
    if (eligible.isEmpty) return const [];

    // Yesterday's lines are dropped where that still leaves enough to fill the
    // section. Never at the cost of leaving a section short.
    final fresh = [
      for (final f in eligible)
        if (!avoid.contains(f.id)) f,
    ];
    final pool = fresh.length >= count ? fresh : eligible;

    final seed = _hash(
      '${signals.rasi.name}|${category.name}|${signals.date.year}',
    );
    final day = _dayOfYear(signals.date);

    // Sentences within one day come from far apart in the pool. Adjacent
    // slots would make tomorrow's three overlap today's by two.
    final stride = count <= 1
        ? 1
        : (pool.length ~/ count).clamp(1, pool.length);

    final out = <Fragment>[];
    final taken = <int>{};
    for (var i = 0; i < count && taken.length < pool.length; i++) {
      var index = (seed + day + i * stride) % pool.length;
      while (taken.contains(index)) {
        index = (index + 1) % pool.length;
      }
      taken.add(index);
      out.add(pool[index]);
    }
    return out;
  }

  /// 1-9. Numerology rather than astrology, and treated as such: readers
  /// expect one, and it costs nothing to derive it stably.
  static int _luckyNumber(HoroscopeSignals s) =>
      _hash(
        '${s.rasi.name}|number|${s.date.year}-${s.date.month}-${s.date.day}',
      ).remainder(9) +
      1;

  static String _luckyColour(HoroscopeSignals s) =>
      _colours[_hash(
        '${s.rasi.name}|colour|${s.date.year}-${s.date.month}-${s.date.day}',
      ).remainder(_colours.length)];

  static int _dayOfYear(DateTime date) =>
      date.difference(DateTime(date.year)).inDays;

  /// FNV-1a, 32-bit.
  ///
  /// Written out rather than using [Object.hashCode] because that is not
  /// guaranteed stable across runs or SDK versions, and a horoscope that
  /// changes when the app is rebuilt is worse than no horoscope.
  static int _hash(String input) {
    var hash = 0x811c9dc5;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash;
  }
}
