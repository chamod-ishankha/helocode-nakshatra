import '../models.dart';

/// Which reference point Mars was judged from.
enum DoshaReference { lagna, moon, venus }

/// The result of a kuja doṣa check for one chart.
class KujaDoshaResult {
  const KujaDoshaResult({required this.afflictedFrom, required this.marsHouse});

  /// The reference points from which Mars falls in an afflicting house.
  ///
  /// Empty means no doṣa. More entries mean the affliction is repeated, which
  /// the tradition reads as stronger.
  final Set<DoshaReference> afflictedFrom;

  /// Mars's house counted from the lagna, for display.
  final int marsHouse;

  bool get hasDosha => afflictedFrom.isNotEmpty;

  /// Repeated affliction — from more than one reference point.
  bool get isSevere => afflictedFrom.length > 1;
}

/// How a pair stands with respect to kuja doṣa.
class KujaDoshaMatch {
  const KujaDoshaMatch({required this.bride, required this.groom});

  final KujaDoshaResult bride;
  final KujaDoshaResult groom;

  /// The classical mitigation: when both carry the doṣa it is held to cancel.
  ///
  /// This is the one cancellation rule that is agreed on almost everywhere.
  /// Many others exist — Mars in its own or exaltation sign, Mars aspected by
  /// Jupiter, the couple being past a certain age — and they vary by school,
  /// so none of them are applied here.
  bool get cancelsOut => bride.hasDosha && groom.hasDosha;

  /// One partner carries it and the other does not. This is the case the
  /// tradition actually warns about.
  bool get isUnmatched => bride.hasDosha != groom.hasDosha;
}

/// Kuja doṣa, also called maṅgalik or ceṣṭā doṣa (KAN-29).
///
/// Mars sitting in certain houses is held to trouble a marriage. The houses
/// are counted from a reference point — classically the lagna, and in much of
/// South Asian practice from the Moon and from Venus as well, with each
/// additional hit read as strengthening the affliction.
///
/// ## What this does not do
///
/// It does **not** grade severity beyond counting how many reference points
/// are afflicted, and it applies only the one cancellation everyone agrees on
/// (both partners afflicted). Every other mitigation — Mars in its own sign,
/// Jupiter's aspect, the age of the couple, Mars in the 2nd for particular
/// lagnas — differs between traditions. Applying a contested cancellation
/// would tell someone their match is fine on the strength of one school's
/// opinion, which is not a thing this app should do.
abstract final class KujaDosha {
  /// Houses that carry the doṣa, counted from the reference point.
  ///
  /// The 2nd and 12th relate to family and to the marriage bed, the 4th and
  /// 8th to domestic life and longevity, the 7th to the partner directly, and
  /// the 1st to the person.
  static const Set<int> afflictingHouses = {1, 2, 4, 7, 8, 12};

  /// Checks one chart.
  ///
  /// [fromVenus] is included by default because South Asian practice usually
  /// checks it, but it is the least universal of the three — pass false to
  /// judge from the lagna and Moon only.
  static KujaDoshaResult check(BirthChart chart, {bool fromVenus = true}) {
    final mars = chart[Graha.mars];
    final marsSign = mars.rasi.index;

    int houseFrom(Rasi reference) =>
        ((marsSign - reference.index) % 12) + 1;

    final afflicted = <DoshaReference>{};

    if (afflictingHouses.contains(houseFrom(chart.lagnaRasi))) {
      afflicted.add(DoshaReference.lagna);
    }
    if (afflictingHouses.contains(houseFrom(chart[Graha.moon].rasi))) {
      afflicted.add(DoshaReference.moon);
    }
    if (fromVenus &&
        afflictingHouses.contains(houseFrom(chart[Graha.venus].rasi))) {
      afflicted.add(DoshaReference.venus);
    }

    return KujaDoshaResult(
      afflictedFrom: afflicted,
      marsHouse: houseFrom(chart.lagnaRasi),
    );
  }

  static KujaDoshaMatch compare(
    BirthChart bride,
    BirthChart groom, {
    bool fromVenus = true,
  }) =>
      KujaDoshaMatch(
        bride: check(bride, fromVenus: fromVenus),
        groom: check(groom, fromVenus: fromVenus),
      );
}
