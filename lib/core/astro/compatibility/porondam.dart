import '../models.dart';
import 'nakshatra_traits.dart';

/// How well a single porondam matches.
enum PorondamVerdict {
  /// Fully met.
  good,

  /// Met with a qualification. Some porondam have a middle grade; others are
  /// pass or fail and never return this.
  partial,

  /// Not met.
  poor,
}

/// The porondam this app computes.
///
/// **This is twelve, not twenty.** The ten classical poruthams below are
/// stated the same way in every Sri Lankan and South Indian source, and varṇa
/// and nāḍī are equally settled. The remaining eight of the "twenty" differ
/// between almanacs — which eight they are, and how each is judged — so they
/// are deliberately absent rather than guessed at. See the note on
/// [Porondam.remainingAreSourceDependent].
enum Porondam {
  dina,
  gana,
  mahendra,
  streeDeergha,
  yoni,
  rasi,
  rasiadhipathi,
  vashya,
  rajju,
  vedha,
  varna,
  nadi;

  /// Kept as a named constant so the gap is visible in code, not only in a
  /// commit message: eight further porondam are traditionally counted and are
  /// not implemented, because sources disagree on them.
  static const int remainingAreSourceDependent = 8;

  static const int traditionalTotal = 20;
}

/// One porondam's result.
class PorondamScore {
  const PorondamScore({required this.porondam, required this.verdict});

  final Porondam porondam;
  final PorondamVerdict verdict;

  bool get isGood => verdict == PorondamVerdict.good;
}

class PorondamResult {
  const PorondamResult({required this.scores});

  final List<PorondamScore> scores;

  /// How many were fully met.
  int get matched => scores.where((s) => s.isGood).length;

  /// How many were judged at all. Not twenty — see [Porondam].
  int get judged => scores.length;

  PorondamScore operator [](Porondam p) =>
      scores.firstWhere((s) => s.porondam == p);

  /// Rajju failing is read as the gravest of these in Sri Lankan practice,
  /// so it is surfaced rather than left to be one row among twelve.
  bool get hasRajjuDosha =>
      this[Porondam.rajju].verdict == PorondamVerdict.poor;
}

/// Porondam — the Sri Lankan matching system (KAN-29).
///
/// Like aṣṭakūṭa, everything is read from the Moon's nakṣatra and rāśi for
/// each person. The two systems overlap heavily and disagree in emphasis: the
/// same pairing can score well on one and poorly on the other, which is why
/// the app offers both rather than converting between them.
///
/// ## Bride and groom are not interchangeable
///
/// Several of these count *from* the bride *to* the groom and give a different
/// answer reversed — strī dīrgha most obviously, which asks that the groom's
/// nakṣatra lie well ahead of the bride's. That asymmetry is in the tradition.
abstract final class Porondams {
  static PorondamResult match({
    required Nakshatra brideNakshatra,
    required Rasi brideRasi,
    required Nakshatra groomNakshatra,
    required Rasi groomRasi,
  }) {
    return PorondamResult(
      scores: [
        _dina(brideNakshatra, groomNakshatra),
        _gana(brideNakshatra, groomNakshatra),
        _mahendra(brideNakshatra, groomNakshatra),
        _streeDeergha(brideNakshatra, groomNakshatra),
        _yoni(brideNakshatra, groomNakshatra),
        _rasi(brideRasi, groomRasi),
        _rasiadhipathi(brideRasi, groomRasi),
        _vashya(brideRasi, groomRasi),
        _rajju(brideNakshatra, groomNakshatra),
        _vedha(brideNakshatra, groomNakshatra),
        _varna(brideRasi, groomRasi),
        _nadi(brideNakshatra, groomNakshatra),
      ],
    );
  }

  /// Counts inclusively from [from] to [to] around the twenty-seven.
  ///
  /// Inclusive is the tradition's convention: a nakṣatra counted to itself is
  /// one, not zero. Getting this wrong shifts every count by one and quietly
  /// changes several porondam at once.
  static int countTo(Nakshatra from, Nakshatra to) =>
      ((to.index - from.index) % 27) + 1;

  /// Dina — the day match. Counted from the bride.
  static PorondamScore _dina(Nakshatra bride, Nakshatra groom) {
    final remainder = countTo(bride, groom) % 9;
    // 2, 4, 6, 8 and 0 (a full nine) are the favourable remainders.
    final good = remainder == 0 || remainder.isEven;
    return PorondamScore(
      porondam: Porondam.dina,
      verdict: good ? PorondamVerdict.good : PorondamVerdict.poor,
    );
  }

  /// Gaṇa — temperament.
  static PorondamScore _gana(Nakshatra bride, Nakshatra groom) {
    final b = NakshatraTraits.gana(bride);
    final g = NakshatraTraits.gana(groom);

    return PorondamScore(
      porondam: Porondam.gana,
      verdict: switch ((b, g)) {
        _ when b == g => PorondamVerdict.good,
        (Gana.deva, Gana.manushya) ||
        (Gana.manushya, Gana.deva) => PorondamVerdict.partial,
        _ => PorondamVerdict.poor,
      },
    );
  }

  /// Mahendra — held to bear on children and on the couple's welfare.
  ///
  /// Met when the groom's nakṣatra falls at one of these counts from the
  /// bride's.
  static const Set<int> _mahendraCounts = {4, 7, 10, 13, 16, 19, 22, 25};

  static PorondamScore _mahendra(Nakshatra bride, Nakshatra groom) {
    final good = _mahendraCounts.contains(countTo(bride, groom));
    return PorondamScore(
      porondam: Porondam.mahendra,
      verdict: good ? PorondamVerdict.good : PorondamVerdict.poor,
    );
  }

  /// Strī dīrgha — longevity and wellbeing of the wife.
  ///
  /// Asks that the groom's nakṣatra lie well ahead of the bride's: more than
  /// thirteen is held to be strong, more than nine acceptable. This is the
  /// most obviously direction-dependent of the set.
  static PorondamScore _streeDeergha(Nakshatra bride, Nakshatra groom) {
    final count = countTo(bride, groom);
    return PorondamScore(
      porondam: Porondam.streeDeergha,
      verdict: count > 13
          ? PorondamVerdict.good
          : count > 9
          ? PorondamVerdict.partial
          : PorondamVerdict.poor,
    );
  }

  static PorondamScore _yoni(Nakshatra bride, Nakshatra groom) {
    final (b, _) = NakshatraTraits.yoni(bride);
    final (g, _) = NakshatraTraits.yoni(groom);

    return PorondamScore(
      porondam: Porondam.yoni,
      verdict: b == g
          ? PorondamVerdict.good
          : NakshatraTraits.areEnemies(b, g)
          ? PorondamVerdict.poor
          : PorondamVerdict.partial,
    );
  }

  /// Rāśi — met when the groom's Moon sign lies in the seventh or beyond from
  /// the bride's.
  static PorondamScore _rasi(Rasi bride, Rasi groom) {
    final count = ((groom.index - bride.index) % 12) + 1;
    return PorondamScore(
      porondam: Porondam.rasi,
      verdict: count >= 7
          ? PorondamVerdict.good
          // Being in the same sign is accepted where the count is otherwise
          // short; the objection is to the near-but-not-same placements.
          : count == 1
          ? PorondamVerdict.partial
          : PorondamVerdict.poor,
    );
  }

  /// Rāśyādhipati — the lords of the two Moon signs.
  static PorondamScore _rasiadhipathi(Rasi bride, Rasi groom) {
    final b = RasiTraits.lord(bride);
    final g = RasiTraits.lord(groom);
    if (b == g) {
      return const PorondamScore(
        porondam: Porondam.rasiadhipathi,
        verdict: PorondamVerdict.good,
      );
    }

    final sum = GrahaFriendship.regard(b, g) + GrahaFriendship.regard(g, b);
    return PorondamScore(
      porondam: Porondam.rasiadhipathi,
      verdict: sum >= 1
          ? PorondamVerdict.good
          : sum == 0
          ? PorondamVerdict.partial
          : PorondamVerdict.poor,
    );
  }

  static PorondamScore _vashya(Rasi bride, Rasi groom) {
    final b = RasiTraits.vashya(bride);
    final g = RasiTraits.vashya(groom);

    return PorondamScore(
      porondam: Porondam.vashya,
      verdict: b == g
          ? PorondamVerdict.good
          : (b == Vashya.vanachara || g == Vashya.vanachara)
          ? PorondamVerdict.poor
          : PorondamVerdict.partial,
    );
  }

  /// Rajju — met when the two fall in *different* limbs.
  ///
  /// The only porondam here that is failed by sameness rather than difference.
  /// Sharing the head (śiro) is held to be the gravest case, but this does not
  /// grade it: the distinction between "same limb" and "same limb, and it is
  /// the head" varies enough between sources that reporting it as fact would
  /// overstate what is agreed.
  static PorondamScore _rajju(Nakshatra bride, Nakshatra groom) {
    final same = NakshatraTraits.rajju(bride) == NakshatraTraits.rajju(groom);
    return PorondamScore(
      porondam: Porondam.rajju,
      verdict: same ? PorondamVerdict.poor : PorondamVerdict.good,
    );
  }

  /// Nakṣatra pairs held to pierce one another.
  ///
  /// Thirteen pairs cover twenty-six of the twenty-seven. Mṛgaśira is left
  /// without a counterpart, which is correct and not an omission — the count
  /// is odd.
  static const List<(Nakshatra, Nakshatra)> vedhaPairs = [
    (Nakshatra.ashwini, Nakshatra.jyeshtha),
    (Nakshatra.bharani, Nakshatra.anuradha),
    (Nakshatra.krittika, Nakshatra.vishakha),
    (Nakshatra.rohini, Nakshatra.swati),
    (Nakshatra.ardra, Nakshatra.shravana),
    (Nakshatra.punarvasu, Nakshatra.uttaraAshadha),
    (Nakshatra.pushya, Nakshatra.purvaAshadha),
    (Nakshatra.ashlesha, Nakshatra.mula),
    (Nakshatra.magha, Nakshatra.revati),
    (Nakshatra.purvaPhalguni, Nakshatra.uttaraBhadrapada),
    (Nakshatra.uttaraPhalguni, Nakshatra.purvaBhadrapada),
    (Nakshatra.hasta, Nakshatra.shatabhisha),
    (Nakshatra.chitra, Nakshatra.dhanishta),
  ];

  static PorondamScore _vedha(Nakshatra bride, Nakshatra groom) {
    final pierced = vedhaPairs.any(
      (p) =>
          (p.$1 == bride && p.$2 == groom) || (p.$1 == groom && p.$2 == bride),
    );
    return PorondamScore(
      porondam: Porondam.vedha,
      verdict: pierced ? PorondamVerdict.poor : PorondamVerdict.good,
    );
  }

  static PorondamScore _varna(Rasi bride, Rasi groom) {
    final ok = RasiTraits.varna(groom).rank >= RasiTraits.varna(bride).rank;
    return PorondamScore(
      porondam: Porondam.varna,
      verdict: ok ? PorondamVerdict.good : PorondamVerdict.poor,
    );
  }

  static PorondamScore _nadi(Nakshatra bride, Nakshatra groom) {
    final same = NakshatraTraits.nadi(bride) == NakshatraTraits.nadi(groom);
    return PorondamScore(
      porondam: Porondam.nadi,
      verdict: same ? PorondamVerdict.poor : PorondamVerdict.good,
    );
  }
}
