import '../../../core/astro/dasha.dart';
import '../../../core/astro/gochara.dart';
import '../../../core/astro/models.dart';

/// What the sky says today, reduced to tags a content fragment can ask for
/// (KAN-31).
///
/// ## Why tags rather than a score
///
/// A single "today is a 7/10" number would make every reading interchangeable
/// and force the writing to be vague. Tags keep the *reason* attached — a day
/// is not merely good, it is good because Jupiter is in the 11th from the
/// Moon — so a fragment can be written specifically and still only appear when
/// it is true.
///
/// Tags are plain strings on purpose. Fragments are authored as data
/// (KAN-32), possibly by someone who is not editing Dart, and a typo in a tag
/// must fail by never matching rather than by failing to compile.
class HoroscopeSignals {
  const HoroscopeSignals({
    required this.rasi,
    required this.date,
    required this.transits,
    required this.saturn,
    required this.tags,
    required this.mood,
    this.dashaLord,
    this.contacts = const [],
  });

  /// The sign the reading is for — the reader's janma rāśi.
  final Rasi rasi;

  /// Local calendar day. Never a timestamp: two readers opening the app at
  /// different times of the same day must see the same reading.
  final DateTime date;

  final List<TransitPosition> transits;
  final SaturnPhase saturn;

  /// Null when the reader has no chart, or their birth time is unknown.
  /// Everything else still works — this only adds personalisation.
  final Graha? dashaLord;

  final List<NatalContact> contacts;

  /// Conditions a fragment can require, e.g. `moon.house.11`,
  /// `saturn.sadeSati`, `jupiter.favourable`, `dasha.venus`.
  final Set<String> tags;

  /// -3 (hard) to +3 (bright). Used to pick the register of the writing, not
  /// to replace it.
  final int mood;

  bool get isBright => mood >= 2;
  bool get isHard => mood <= -2;

  /// Derives the signals for [rasi] on [date].
  ///
  /// [transiting] is where each graha is today. [natal] and [dasha] are
  /// optional: without them this is the rāśi-wide reading a newspaper prints,
  /// with them it is personalised.
  factory HoroscopeSignals.from({
    required Rasi rasi,
    required DateTime date,
    required Map<Graha, Rasi> transiting,
    Map<Graha, Rasi>? natal,
    DashaSnapshot? dasha,
  }) {
    final placed = Gochara.place(rasi, transiting);
    final saturnRasi = transiting[Graha.saturn];
    final saturn = saturnRasi == null
        ? SaturnPhase.none
        : Gochara.saturnPhase(rasi, saturnRasi);

    final tags = <String>{};
    var mood = 0;

    for (final t in placed) {
      final name = t.graha.name;
      tags.add('$name.house.${t.houseFromMoon}');
      tags.add(t.favourable ? '$name.favourable' : '$name.difficult');

      // The Moon moves a sign every two and a bit days, so it is what makes
      // one day differ from the next. Weighted above the slow grahas, which
      // would otherwise say the same thing for months.
      final weight = switch (t.graha) {
        Graha.moon => 2,
        Graha.sun || Graha.mercury || Graha.venus || Graha.mars => 1,
        // Jupiter and Saturn set the season, not the day.
        Graha.jupiter || Graha.saturn => 1,
        Graha.rahu || Graha.ketu => 0,
      };
      mood += t.favourable ? weight : -weight;
    }

    if (saturn != SaturnPhase.none) {
      tags.add('saturn.${saturn.name}');
      if (saturn.isSadeSati) tags.add('saturn.sadeSati');
      // Named Saturn transits dominate a reading whatever else is running.
      mood -= saturn.isSadeSati ? 2 : 1;
    }

    if (dasha != null) {
      tags.add('dasha.${dasha.maha.lord.name}');
      final antara = dasha.antara;
      if (antara != null) tags.add('antara.${antara.lord.name}');
    }

    final contacts = natal == null
        ? const <NatalContact>[]
        : Gochara.contacts(transiting, natal);

    for (final c in contacts) {
      tags.add(
        c.isConjunction
            ? 'contact.${c.transiting.name}.conjunct.${c.natal.name}'
            : 'contact.${c.transiting.name}.aspects.${c.natal.name}',
      );
    }

    mood = mood.clamp(-3, 3);
    tags.add('mood.${_moodName(mood)}');

    return HoroscopeSignals(
      rasi: rasi,
      date: DateTime(date.year, date.month, date.day),
      transits: placed,
      saturn: saturn,
      dashaLord: dasha?.maha.lord,
      contacts: contacts,
      tags: tags,
      mood: mood,
    );
  }

  static String _moodName(int mood) => switch (mood) {
    >= 2 => 'bright',
    1 => 'mild',
    0 => 'even',
    -1 => 'mixed',
    _ => 'hard',
  };
}
