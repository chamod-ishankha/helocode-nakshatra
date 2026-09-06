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
  static Horoscope build({
    required HoroscopeSignals signals,
    required List<Fragment> fragments,
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
  static List<Fragment> _pick({
    required HoroscopeSignals signals,
    required List<Fragment> fragments,
    required HoroscopeCategory category,
    required int count,
  }) {
    final eligible = [
      for (final f in fragments)
        if (f.category == category && f.matches(signals.tags)) f,
    ];
    if (eligible.isEmpty) return const [];

    // Specific copy first, then by id so the order never depends on the order
    // the file happened to be written in. Without the id tiebreak, reordering
    // the JSON would silently change everybody's horoscope.
    eligible.sort((a, b) {
      final bySpecificity = b.specificity.compareTo(a.specificity);
      return bySpecificity != 0 ? bySpecificity : a.id.compareTo(b.id);
    });

    // The most specific tier is what was written for a day like today. Only
    // fall back to generic copy when there is not enough of it.
    final top = eligible.first.specificity;
    final preferred = [
      for (final f in eligible)
        if (f.specificity == top) f,
    ];
    final pool = preferred.length >= count ? preferred : eligible;

    final seed = _hash(
      '${signals.rasi.name}|${category.name}|${signals.date.year}',
    );
    final day = _dayOfYear(signals.date);

    final out = <Fragment>[];
    for (var i = 0; i < count && i < pool.length; i++) {
      // Step one place per day, so consecutive days walk the pool rather than
      // landing anywhere. i offsets the sentences within one day.
      out.add(pool[(seed + day + i) % pool.length]);
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
