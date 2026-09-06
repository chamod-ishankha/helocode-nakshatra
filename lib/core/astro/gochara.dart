/// Gochara — transits read from the natal Moon (KAN-31).
///
/// ## Why from the Moon and not the lagna
///
/// Daily prediction in the Sri Lankan and wider Indian tradition is *rāśi
/// phala*: houses are counted from the janma rāśi, the sign the Moon occupied
/// at birth, not from the ascendant. That is what a newspaper or almanac
/// column means by "your sign", and it is why someone can read their forecast
/// knowing only their birth date and rough time — the Moon's sign is far less
/// sensitive to the minute than the lagna, which changes every two hours.
///
/// Everything here therefore counts from a [Rasi], not from a chart. A natal
/// chart is optional and only adds personalisation on top.
///
/// ## Sources
///
/// The favourability table is the standard one given in Bṛhat Parāśara Horā
/// Śāstra and Phaladeepika, and is consistent across the mainstream printed
/// almanacs. Where traditions genuinely disagree — vedha, and the aspects of
/// the nodes — the disagreement is documented at the point of the decision
/// rather than silently resolved.
library;

import 'models.dart';

/// A transiting graha, placed relative to the natal Moon.
class TransitPosition {
  const TransitPosition({
    required this.graha,
    required this.rasi,
    required this.houseFromMoon,
    required this.favourable,
  });

  final Graha graha;

  /// The sign the graha is transiting now.
  final Rasi rasi;

  /// 1-12, counted inclusively from the natal Moon's sign.
  ///
  /// Inclusive counting is the tradition's convention: a graha in the same
  /// sign as the natal Moon is in the *first* house from it, not the zeroth.
  final int houseFromMoon;

  /// Whether this house is a favourable one for this graha.
  final bool favourable;

  @override
  String toString() =>
      '${graha.en} in ${rasi.en}, house $houseFromMoon from Moon '
      '(${favourable ? 'favourable' : 'unfavourable'})';
}

/// Where Saturn is relative to the natal Moon.
///
/// Saturn gets its own type because it is the transit people actually ask
/// about by name. A Sri Lankan reader knows "සෙනසුරු මාරුව" and will judge the
/// app on whether it agrees with the almanac.
enum SaturnPhase {
  /// Saturn in the 12th from the Moon — the first of the seven and a half.
  sadeSatiRising,

  /// Saturn over the natal Moon itself. The middle and heaviest stretch.
  sadeSatiPeak,

  /// Saturn in the 2nd. The last of the three.
  sadeSatiSetting,

  /// Saturn in the 4th — ardhāṣṭama, "half-eighth", kaṇṭaka śani.
  kantaka,

  /// Saturn in the 8th — aṣṭama śani.
  ashtama,

  /// Saturn somewhere that carries no special name.
  none;

  /// Whether this is one of the three legs of sade sati.
  bool get isSadeSati =>
      this == sadeSatiRising || this == sadeSatiPeak || this == sadeSatiSetting;
}

/// A transiting graha falling on a natal one, by conjunction or aspect.
class NatalContact {
  const NatalContact({
    required this.transiting,
    required this.natal,
    required this.aspect,
  });

  final Graha transiting;
  final Graha natal;

  /// The house offset of the aspect: 1 for a conjunction, else 3, 4, 5, 7,
  /// 8, 9 or 10 depending on the graha.
  final int aspect;

  bool get isConjunction => aspect == 1;

  @override
  String toString() => isConjunction
      ? 'transiting ${transiting.en} conjunct natal ${natal.en}'
      : 'transiting ${transiting.en} aspects natal ${natal.en} '
            '(${aspect}th)';
}

abstract final class Gochara {
  /// Houses, counted from the janma rāśi, in which each graha is held to give
  /// results. Every other house is taken as unfavourable.
  ///
  /// The 3rd, 6th and 11th appear for every malefic: the upacaya houses, where
  /// difficulty is said to turn into effort rewarded. This is the single most
  /// load-bearing table in daily prediction, so it is written out in full
  /// rather than derived.
  static const Map<Graha, Set<int>> favourableHouses = {
    Graha.sun: {3, 6, 10, 11},
    Graha.moon: {1, 3, 6, 7, 10, 11},
    Graha.mars: {3, 6, 11},
    Graha.mercury: {2, 4, 6, 8, 10, 11},
    Graha.jupiter: {2, 5, 7, 9, 11},
    Graha.venus: {1, 2, 3, 4, 5, 8, 9, 11, 12},
    Graha.saturn: {3, 6, 11},
    Graha.rahu: {3, 6, 10, 11},
    Graha.ketu: {3, 6, 11},
  };

  /// Full aspects (pūrṇa dṛṣṭi), as house offsets from the aspecting graha.
  ///
  /// Every graha aspects the 7th. Mars, Jupiter and Saturn have their extra
  /// special aspects, which is the near-universal Parāśari position.
  ///
  /// The nodes are the genuine fork: Parāśara gives them no aspect at all,
  /// while much later practice — and most software — grants them 5, 7 and 9
  /// like Jupiter. Following the software here, for the same reason the daśā
  /// year is Julian: agreeing with what a reader can check elsewhere matters
  /// more than picking a favourite authority. Changing this changes readings,
  /// so it is a deliberate constant.
  static const Map<Graha, Set<int>> aspects = {
    Graha.sun: {7},
    Graha.moon: {7},
    Graha.mars: {4, 7, 8},
    Graha.mercury: {7},
    Graha.jupiter: {5, 7, 9},
    Graha.venus: {7},
    Graha.saturn: {3, 7, 10},
    Graha.rahu: {5, 7, 9},
    Graha.ketu: {5, 7, 9},
  };

  /// The house of [to] counted inclusively from [from]. Always 1-12.
  ///
  /// Inclusive: `houseFrom(mesha, mesha)` is 1, not 0. Getting this wrong
  /// shifts every judgement by one house, which is the difference between the
  /// 12th (loss) and the 1st (the body) — so it is tested directly.
  static int houseFrom(Rasi from, Rasi to) =>
      ((to.index - from.index) % 12) + 1;

  /// The sign that sits [house] houses from [from], inclusively.
  static Rasi rasiAt(Rasi from, int house) =>
      Rasi.values[(from.index + house - 1) % 12];

  static bool isFavourable(Graha graha, int houseFromMoon) =>
      favourableHouses[graha]!.contains(houseFromMoon);

  /// Places every transiting graha relative to [natalMoon].
  ///
  /// [transiting] is a map of graha to the sign it currently occupies, which
  /// is all a gochara reading needs — degrees do not enter into it.
  static List<TransitPosition> place(
    Rasi natalMoon,
    Map<Graha, Rasi> transiting,
  ) {
    final out = <TransitPosition>[];
    for (final graha in Graha.values) {
      final rasi = transiting[graha];
      if (rasi == null) continue;
      final house = houseFrom(natalMoon, rasi);
      out.add(
        TransitPosition(
          graha: graha,
          rasi: rasi,
          houseFromMoon: house,
          favourable: isFavourable(graha, house),
        ),
      );
    }
    return out;
  }

  /// Saturn's named phase relative to [natalMoon].
  static SaturnPhase saturnPhase(Rasi natalMoon, Rasi saturnRasi) =>
      switch (houseFrom(natalMoon, saturnRasi)) {
        12 => SaturnPhase.sadeSatiRising,
        1 => SaturnPhase.sadeSatiPeak,
        2 => SaturnPhase.sadeSatiSetting,
        4 => SaturnPhase.kantaka,
        8 => SaturnPhase.ashtama,
        _ => SaturnPhase.none,
      };

  /// Every transiting graha that conjoins or aspects a natal graha.
  ///
  /// Sign-based, like the rest of gochara: a transiting graha contacts a natal
  /// one when it sits in, or aspects, the sign the natal graha occupies. Orbs
  /// in degrees belong to Western practice, not this one.
  static List<NatalContact> contacts(
    Map<Graha, Rasi> transiting,
    Map<Graha, Rasi> natal,
  ) {
    final out = <NatalContact>[];

    for (final t in Graha.values) {
      final from = transiting[t];
      if (from == null) continue;

      for (final n in Graha.values) {
        final target = natal[n];
        if (target == null) continue;

        final offset = houseFrom(from, target);
        if (offset == 1) {
          out.add(NatalContact(transiting: t, natal: n, aspect: 1));
        } else if (aspects[t]!.contains(offset)) {
          out.add(NatalContact(transiting: t, natal: n, aspect: offset));
        }
      }
    }
    return out;
  }
}
