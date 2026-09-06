import '../models.dart';
import 'nakshatra_traits.dart';

/// The eight factors of guṇa milan, in their conventional order.
enum Koota {
  varna(1),
  vashya(2),
  tara(3),
  yoni(4),
  grahaMaitri(5),
  gana(6),
  bhakoot(7),
  nadi(8);

  const Koota(this.maximum);

  /// Points this factor can contribute. They sum to 36.
  final int maximum;
}

/// One factor's result.
class KootaScore {
  const KootaScore({
    required this.koota,
    required this.points,
    required this.detail,
  });

  final Koota koota;
  final double points;

  /// A machine-readable note the UI turns into a sentence, so this layer stays
  /// free of language — the same split used for auth errors.
  final KootaDetail detail;

  int get maximum => koota.maximum;
  bool get isFull => points >= maximum;
  bool get isZero => points <= 0;
}

/// Why a factor scored what it did.
enum KootaDetail {
  varnaGroomEqualOrHigher,
  varnaGroomLower,
  vashyaSameGroup,
  vashyaCompatibleGroup,
  vashyaWeakGroup,
  vashyaIncompatibleGroup,
  taraBothAuspicious,
  taraOneAuspicious,
  taraNeitherAuspicious,
  yoniSameAnimal,
  yoniNeutralAnimals,
  yoniEnemyAnimals,
  grahaMaitriMutualFriends,
  grahaMaitriFriendNeutral,
  grahaMaitriBothNeutral,
  grahaMaitriMixed,
  grahaMaitriMutualEnemies,
  ganaSame,
  ganaDevaManushya,
  ganaDevaRakshasa,
  ganaManushyaRakshasa,
  bhakootFavourable,
  bhakootAfflicted,
  nadiDifferent,
  nadiSame,
}

/// The whole match.
class AshtakootaResult {
  const AshtakootaResult({required this.scores});

  final List<KootaScore> scores;

  double get total => scores.fold(0, (sum, s) => sum + s.points);

  static const int maximum = 36;

  KootaScore operator [](Koota k) => scores.firstWhere((s) => s.koota == k);

  /// Nāḍī and bhakūṭa scoring zero are treated as serious in the tradition —
  /// they are the two largest factors and are read as blocking rather than
  /// merely reducing the total. Surfaced separately so the UI can say so
  /// instead of leaving a reader to infer it from a number.
  bool get hasNadiDosha => this[Koota.nadi].isZero;
  bool get hasBhakootDosha => this[Koota.bhakoot].isZero;
}

/// Aṣṭakūṭa / guṇa milan — the 36-point North Indian matching system (KAN-29).
///
/// Everything here is derived from the Moon's nakṣatra and rāśi for each
/// person; no other placement is consulted. That is the system as it stands,
/// and it is why a match can be computed from a birth time alone.
///
/// ## Convention on who is who
///
/// Several factors are **asymmetric** — varṇa and tāra in particular give a
/// different answer if the two people are swapped. The tradition states them
/// in terms of bride and groom, so this API does too. It is a property of the
/// rule set, not an endorsement of it, and the UI should let either person be
/// entered in either slot.
///
/// ## Where sources disagree
///
/// Two factors are reduced from tables that vary between sources, and are
/// marked in the code where that happens:
///
///  * **Vaśya** — the five-group cross table differs between almanacs, and the
///    strictest form splits Sagittarius and Capricorn in half.
///  * **Yoni** — the full table grades fourteen animals against each other as
///    friendly, neutral or hostile. This reduces that to same / neutral /
///    enemy, which is conservative: it can understate a pairing, never
///    overstate one.
///
/// Both are worth checking against a printed Sri Lankan almanac before this
/// feature is user-visible.
abstract final class Ashtakoota {
  /// Scores a pairing from each person's Moon position.
  static AshtakootaResult match({
    required Nakshatra brideNakshatra,
    required Rasi brideRasi,
    required Nakshatra groomNakshatra,
    required Rasi groomRasi,
  }) {
    return AshtakootaResult(
      scores: [
        _varna(brideRasi, groomRasi),
        _vashya(brideRasi, groomRasi),
        _tara(brideNakshatra, groomNakshatra),
        _yoni(brideNakshatra, groomNakshatra),
        _grahaMaitri(brideRasi, groomRasi),
        _gana(brideNakshatra, groomNakshatra),
        _bhakoot(brideRasi, groomRasi),
        _nadi(brideNakshatra, groomNakshatra),
      ],
    );
  }

  /// 1 point. Scores when the groom's varṇa is not below the bride's.
  static KootaScore _varna(Rasi bride, Rasi groom) {
    final ok = RasiTraits.varna(groom).rank >= RasiTraits.varna(bride).rank;
    return KootaScore(
      koota: Koota.varna,
      points: ok ? 1 : 0,
      detail: ok
          ? KootaDetail.varnaGroomEqualOrHigher
          : KootaDetail.varnaGroomLower,
    );
  }

  /// 2 points.
  static KootaScore _vashya(Rasi bride, Rasi groom) {
    final b = RasiTraits.vashya(bride);
    final g = RasiTraits.vashya(groom);

    // Reduced from a cross table that varies between sources. Same group is
    // full marks everywhere; a quadruped with a wild animal is nil everywhere
    // (the lion eats it); the rest sit in between.
    final (double points, KootaDetail detail) = switch ((b, g)) {
      _ when b == g => (2.0, KootaDetail.vashyaSameGroup),
      (Vashya.chatushpada, Vashya.vanachara) ||
      (
        Vashya.vanachara,
        Vashya.chatushpada,
      ) => (0.0, KootaDetail.vashyaIncompatibleGroup),
      (Vashya.manava, Vashya.jalachara) ||
      (Vashya.jalachara, Vashya.manava) => (0.5, KootaDetail.vashyaWeakGroup),
      _ => (1.0, KootaDetail.vashyaCompatibleGroup),
    };

    return KootaScore(koota: Koota.vashya, points: points, detail: detail);
  }

  /// 3 points. Counts each way round the twenty-seven and checks the remainder.
  ///
  /// Remainders of 3, 5 and 7 are the inauspicious tārās. Zero counts as nine,
  /// which is auspicious — a common off-by-one when this is implemented.
  static KootaScore _tara(Nakshatra bride, Nakshatra groom) {
    bool auspicious(Nakshatra from, Nakshatra to) {
      final count = ((to.index - from.index) % 27) + 1;
      final remainder = count % 9;
      return remainder != 3 && remainder != 5 && remainder != 7;
    }

    final fromBride = auspicious(bride, groom);
    final fromGroom = auspicious(groom, bride);
    final good = (fromBride ? 1 : 0) + (fromGroom ? 1 : 0);

    return KootaScore(
      koota: Koota.tara,
      points: good * 1.5,
      detail: switch (good) {
        2 => KootaDetail.taraBothAuspicious,
        1 => KootaDetail.taraOneAuspicious,
        _ => KootaDetail.taraNeitherAuspicious,
      },
    );
  }

  /// 4 points.
  static KootaScore _yoni(Nakshatra bride, Nakshatra groom) {
    final (b, _) = NakshatraTraits.yoni(bride);
    final (g, _) = NakshatraTraits.yoni(groom);

    // Conservative reduction of the full fourteen-by-fourteen table: it can
    // understate a pairing but never overstate one.
    final (double points, KootaDetail detail) = b == g
        ? (4.0, KootaDetail.yoniSameAnimal)
        : NakshatraTraits.areEnemies(b, g)
        ? (0.0, KootaDetail.yoniEnemyAnimals)
        : (2.0, KootaDetail.yoniNeutralAnimals);

    return KootaScore(koota: Koota.yoni, points: points, detail: detail);
  }

  /// 5 points. Friendship between the lords of the two Moon signs.
  static KootaScore _grahaMaitri(Rasi bride, Rasi groom) {
    final b = RasiTraits.lord(bride);
    final g = RasiTraits.lord(groom);

    // Each direction is scored separately because the classical friendships
    // are not always mutual.
    final bToG = GrahaFriendship.regard(b, g);
    final gToB = GrahaFriendship.regard(g, b);
    final sum = bToG + gToB;

    final (double points, KootaDetail detail) = switch (sum) {
      2 => (5.0, KootaDetail.grahaMaitriMutualFriends),
      1 => (4.0, KootaDetail.grahaMaitriFriendNeutral),
      0 when bToG == 0 => (3.0, KootaDetail.grahaMaitriBothNeutral),
      // One friend and one enemy also sums to zero, and is worse than two
      // neutrals — hence the guard above.
      0 => (1.0, KootaDetail.grahaMaitriMixed),
      -1 => (0.5, KootaDetail.grahaMaitriMixed),
      _ => (0.0, KootaDetail.grahaMaitriMutualEnemies),
    };

    return KootaScore(koota: Koota.grahaMaitri, points: points, detail: detail);
  }

  /// 6 points.
  static KootaScore _gana(Nakshatra bride, Nakshatra groom) {
    final b = NakshatraTraits.gana(bride);
    final g = NakshatraTraits.gana(groom);

    final (double points, KootaDetail detail) = switch ((b, g)) {
      _ when b == g => (6.0, KootaDetail.ganaSame),
      (Gana.deva, Gana.manushya) ||
      (Gana.manushya, Gana.deva) => (5.0, KootaDetail.ganaDevaManushya),
      (Gana.deva, Gana.rakshasa) ||
      (Gana.rakshasa, Gana.deva) => (1.0, KootaDetail.ganaDevaRakshasa),
      _ => (0.0, KootaDetail.ganaManushyaRakshasa),
    };

    return KootaScore(koota: Koota.gana, points: points, detail: detail);
  }

  /// 7 points. All or nothing, on the distance between the two Moon signs.
  ///
  /// The afflicted separations are 2/12, 5/9 and 6/8 — counted one way and the
  /// other, which is why both directions are computed.
  static KootaScore _bhakoot(Rasi bride, Rasi groom) {
    final forward = ((groom.index - bride.index) % 12) + 1;
    final backward = ((bride.index - groom.index) % 12) + 1;
    final pair = {forward, backward};

    final afflicted =
        pair.containsAll({2, 12}) ||
        pair.containsAll({5, 9}) ||
        pair.containsAll({6, 8});

    return KootaScore(
      koota: Koota.bhakoot,
      points: afflicted ? 0 : 7,
      detail: afflicted
          ? KootaDetail.bhakootAfflicted
          : KootaDetail.bhakootFavourable,
    );
  }

  /// 8 points. The largest single factor, and all or nothing.
  ///
  /// Sharing a nāḍī scores zero. It is the heaviest penalty in the system,
  /// which is why the result surfaces it separately rather than letting it
  /// disappear into a total.
  static KootaScore _nadi(Nakshatra bride, Nakshatra groom) {
    final same = NakshatraTraits.nadi(bride) == NakshatraTraits.nadi(groom);
    return KootaScore(
      koota: Koota.nadi,
      points: same ? 0 : 8,
      detail: same ? KootaDetail.nadiSame : KootaDetail.nadiDifferent,
    );
  }
}
