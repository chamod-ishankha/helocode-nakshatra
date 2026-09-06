import '../models.dart';

/// Temperament grouping, used by the gaṇa factor.
enum Gana { deva, manushya, rakshasa }

/// Constitutional grouping, used by the nāḍī factor.
///
/// Loosely the three doṣas — vāta, pitta, kapha.
enum Nadi { adi, madhya, antya }

/// Body-part grouping, used by the rajju factor in the Sri Lankan system.
enum Rajju { pada, kati, nabhi, kantha, shiro }

/// The animal assigned to each nakṣatra, used by the yoni factor.
///
/// Fourteen animals across twenty-seven nakṣatras, so most appear twice — once
/// as male and once as female. Both halves matter: the yoni table is not
/// symmetric, and a pairing scores differently depending on which side is
/// which.
enum YoniAnimal {
  horse,
  elephant,
  sheep,
  serpent,
  dog,
  cat,
  rat,
  cow,
  buffalo,
  tiger,
  deer,
  monkey,
  mongoose,
  lion,
}

/// Per-nakṣatra attributes shared by both matching systems (KAN-29).
///
/// These tables are the classical ones and are not derived from anything —
/// they are memorised lists in the tradition, so they are written out in full
/// rather than computed. Where a table has an internal pattern the tests check
/// the pattern instead of restating the list, which is what makes a typo here
/// visible.
abstract final class NakshatraTraits {
  /// Deva, manuṣya or rākṣasa.
  static Gana gana(Nakshatra n) => switch (n) {
    Nakshatra.ashwini ||
    Nakshatra.mrigashira ||
    Nakshatra.punarvasu ||
    Nakshatra.pushya ||
    Nakshatra.hasta ||
    Nakshatra.swati ||
    Nakshatra.anuradha ||
    Nakshatra.shravana ||
    Nakshatra.revati => Gana.deva,

    Nakshatra.bharani ||
    Nakshatra.rohini ||
    Nakshatra.ardra ||
    Nakshatra.purvaPhalguni ||
    Nakshatra.uttaraPhalguni ||
    Nakshatra.purvaAshadha ||
    Nakshatra.uttaraAshadha ||
    Nakshatra.purvaBhadrapada ||
    Nakshatra.uttaraBhadrapada => Gana.manushya,

    Nakshatra.krittika ||
    Nakshatra.ashlesha ||
    Nakshatra.magha ||
    Nakshatra.chitra ||
    Nakshatra.vishakha ||
    Nakshatra.jyeshtha ||
    Nakshatra.mula ||
    Nakshatra.dhanishta ||
    Nakshatra.shatabhisha => Gana.rakshasa,
  };

  /// Ādi, madhya or antya.
  ///
  /// Runs in a repeating 1-2-3-3-2-1 cycle across the twenty-seven, which the
  /// tests assert rather than re-listing.
  static Nadi nadi(Nakshatra n) => switch (n.index + 1) {
    1 || 6 || 7 || 12 || 13 || 18 || 19 || 24 || 25 => Nadi.adi,
    2 || 5 || 8 || 11 || 14 || 17 || 20 || 23 || 26 => Nadi.madhya,
    _ => Nadi.antya,
  };

  /// Which "limb" the nakṣatra belongs to.
  ///
  /// Counts up 1-5 and back down again, repeatedly, so the head (śiro) falls
  /// on 5, 14 and 23.
  static Rajju rajju(Nakshatra n) => switch (n.index + 1) {
    1 || 9 || 10 || 18 || 19 || 27 => Rajju.pada,
    2 || 8 || 11 || 17 || 20 || 26 => Rajju.kati,
    3 || 7 || 12 || 16 || 21 || 25 => Rajju.nabhi,
    4 || 6 || 13 || 15 || 22 || 24 => Rajju.kantha,
    _ => Rajju.shiro,
  };

  /// The yoni animal, and whether this nakṣatra is its male or female half.
  static (YoniAnimal, bool isMale) yoni(Nakshatra n) => switch (n) {
    Nakshatra.ashwini => (YoniAnimal.horse, true),
    Nakshatra.bharani => (YoniAnimal.elephant, true),
    Nakshatra.krittika => (YoniAnimal.sheep, false),
    Nakshatra.rohini => (YoniAnimal.serpent, true),
    Nakshatra.mrigashira => (YoniAnimal.serpent, false),
    Nakshatra.ardra => (YoniAnimal.dog, false),
    Nakshatra.punarvasu => (YoniAnimal.cat, false),
    Nakshatra.pushya => (YoniAnimal.sheep, true),
    Nakshatra.ashlesha => (YoniAnimal.cat, true),
    Nakshatra.magha => (YoniAnimal.rat, true),
    Nakshatra.purvaPhalguni => (YoniAnimal.rat, false),
    Nakshatra.uttaraPhalguni => (YoniAnimal.cow, true),
    Nakshatra.hasta => (YoniAnimal.buffalo, false),
    Nakshatra.chitra => (YoniAnimal.tiger, false),
    Nakshatra.swati => (YoniAnimal.buffalo, true),
    Nakshatra.vishakha => (YoniAnimal.tiger, true),
    Nakshatra.anuradha => (YoniAnimal.deer, false),
    Nakshatra.jyeshtha => (YoniAnimal.deer, true),
    Nakshatra.mula => (YoniAnimal.dog, true),
    Nakshatra.purvaAshadha => (YoniAnimal.monkey, true),
    Nakshatra.uttaraAshadha => (YoniAnimal.mongoose, false),
    Nakshatra.shravana => (YoniAnimal.monkey, false),
    Nakshatra.dhanishta => (YoniAnimal.lion, false),
    Nakshatra.shatabhisha => (YoniAnimal.horse, false),
    Nakshatra.purvaBhadrapada => (YoniAnimal.lion, true),
    Nakshatra.uttaraBhadrapada => (YoniAnimal.cow, false),
    Nakshatra.revati => (YoniAnimal.elephant, false),
  };

  /// Pairs of animals held to be natural enemies.
  ///
  /// A pairing between them scores worst on the yoni factor. Stored one way
  /// round and checked both, since enmity is mutual.
  static const List<(YoniAnimal, YoniAnimal)> _enemies = [
    (YoniAnimal.cow, YoniAnimal.tiger),
    (YoniAnimal.elephant, YoniAnimal.lion),
    (YoniAnimal.horse, YoniAnimal.buffalo),
    (YoniAnimal.dog, YoniAnimal.deer),
    (YoniAnimal.serpent, YoniAnimal.mongoose),
    (YoniAnimal.cat, YoniAnimal.rat),
    (YoniAnimal.monkey, YoniAnimal.sheep),
    (YoniAnimal.lion, YoniAnimal.elephant),
  ];

  static bool areEnemies(YoniAnimal a, YoniAnimal b) => _enemies.any(
    (pair) =>
        (pair.$1 == a && pair.$2 == b) || (pair.$1 == b && pair.$2 == a),
  );
}

/// Social grouping taken from the Moon's rāśi, used by the varṇa factor.
enum Varna {
  shudra(1),
  vaishya(2),
  kshatriya(3),
  brahmin(4);

  const Varna(this.rank);

  /// Higher is "greater" only in the sense the factor uses: the match scores
  /// when the groom's rank is not below the bride's. It is a compatibility
  /// rule, not a statement about people.
  final int rank;
}

/// Movement grouping, used by the vaśya factor.
enum Vashya { chatushpada, manava, jalachara, vanachara, keeta }

/// Per-rāśi attributes.
abstract final class RasiTraits {
  /// Varṇa follows the classical element of the sign.
  static Varna varna(Rasi r) => switch (r) {
    // Water
    Rasi.karka || Rasi.vrischika || Rasi.meena => Varna.brahmin,
    // Fire
    Rasi.mesha || Rasi.simha || Rasi.dhanu => Varna.kshatriya,
    // Earth
    Rasi.vrishabha || Rasi.kanya || Rasi.makara => Varna.vaishya,
    // Air
    Rasi.mithuna || Rasi.tula || Rasi.kumbha => Varna.shudra,
  };

  /// The vaśya group of a sign.
  ///
  /// Sagittarius and Capricorn are split in the strictest form of this rule —
  /// the first half of Sagittarius is human and the second quadruped, and
  /// Capricorn is the reverse. The whole-sign classification below is the one
  /// in common use and is what Sri Lankan almanacs print; the split-sign
  /// refinement is noted here so its absence is a decision rather than an
  /// oversight.
  static Vashya vashya(Rasi r) => switch (r) {
    Rasi.mesha || Rasi.vrishabha || Rasi.dhanu || Rasi.makara =>
      Vashya.chatushpada,
    Rasi.mithuna || Rasi.kanya || Rasi.tula || Rasi.kumbha => Vashya.manava,
    Rasi.karka || Rasi.meena => Vashya.jalachara,
    Rasi.simha => Vashya.vanachara,
    Rasi.vrischika => Vashya.keeta,
  };

  /// The graha that rules a sign.
  static Graha lord(Rasi r) => switch (r) {
    Rasi.mesha || Rasi.vrischika => Graha.mars,
    Rasi.vrishabha || Rasi.tula => Graha.venus,
    Rasi.mithuna || Rasi.kanya => Graha.mercury,
    Rasi.karka => Graha.moon,
    Rasi.simha => Graha.sun,
    Rasi.dhanu || Rasi.meena => Graha.jupiter,
    Rasi.makara || Rasi.kumbha => Graha.saturn,
  };
}

/// Natural friendship between grahas, used by the graha maitrī factor.
///
/// The classical scheme: each graha has friends, neutrals and enemies, and the
/// relation is not always mutual — Sun counts Mercury a friend while Mercury
/// counts Sun neutral. That asymmetry is real and is preserved here rather
/// than flattened, because the factor scores each direction separately.
abstract final class GrahaFriendship {
  static const Map<Graha, List<Graha>> _friends = {
    Graha.sun: [Graha.moon, Graha.mars, Graha.jupiter],
    Graha.moon: [Graha.sun, Graha.mercury],
    Graha.mars: [Graha.sun, Graha.moon, Graha.jupiter],
    Graha.mercury: [Graha.sun, Graha.venus],
    Graha.jupiter: [Graha.sun, Graha.moon, Graha.mars],
    Graha.venus: [Graha.mercury, Graha.saturn],
    Graha.saturn: [Graha.mercury, Graha.venus],
  };

  static const Map<Graha, List<Graha>> _enemies = {
    Graha.sun: [Graha.venus, Graha.saturn],
    Graha.moon: [],
    Graha.mars: [Graha.mercury],
    Graha.mercury: [Graha.moon],
    Graha.jupiter: [Graha.mercury, Graha.venus],
    Graha.venus: [Graha.sun, Graha.moon],
    Graha.saturn: [Graha.sun, Graha.moon, Graha.mars],
  };

  /// How [of] regards [other]: 1 friend, 0 neutral, -1 enemy.
  static int regard(Graha of, Graha other) {
    if (of == other) return 1;
    if (_friends[of]?.contains(other) ?? false) return 1;
    if (_enemies[of]?.contains(other) ?? false) return -1;
    return 0;
  }
}
