import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/astro/compatibility/ashtakoota.dart';
import '../../../core/astro/compatibility/kuja_dosha.dart';
import '../../../core/astro/compatibility/porondam.dart';
import '../../../core/astro/ephemeris.dart';
import '../../../core/astro/models.dart';
import '../../onboarding/data/profile_repository.dart';
import '../../onboarding/domain/birth_profile.dart';

/// Which matching system is on screen.
enum MatchSystem { porondam, ashtakoota }

/// Which of the two people is the bride.
///
/// This is not cosmetic. Varṇa, tāra, strī dīrgha and rāśi are all counted
/// from the bride to the groom and give a different answer reversed, so the
/// app has to ask rather than assume.
enum BrideRole { me, partner }

/// The partner's details.
///
/// Held in memory only. Saving a second person needs the multi-profile storage
/// from KAN-19, and writing one to the single-profile slot would overwrite the
/// user's own chart.
class PartnerNotifier extends Notifier<BirthProfile?> {
  @override
  BirthProfile? build() => null;

  void set(BirthProfile profile) => state = profile;
  void clear() => state = null;
}

final partnerProvider =
    NotifierProvider<PartnerNotifier, BirthProfile?>(PartnerNotifier.new);

class MatchSystemNotifier extends Notifier<MatchSystem> {
  // Porondam first: this app's first audience reads porondam, not guṇa milan.
  @override
  MatchSystem build() => MatchSystem.porondam;

  void set(MatchSystem s) => state = s;
}

final matchSystemProvider =
    NotifierProvider<MatchSystemNotifier, MatchSystem>(MatchSystemNotifier.new);

class BrideRoleNotifier extends Notifier<BrideRole> {
  @override
  BrideRole build() => BrideRole.me;

  void set(BrideRole r) => state = r;
}

final brideRoleProvider =
    NotifierProvider<BrideRoleNotifier, BrideRole>(BrideRoleNotifier.new);

/// Everything a compatibility screen needs, computed together.
class MatchResult {
  const MatchResult({
    required this.ashtakoota,
    required this.porondam,
    required this.kuja,
    required this.brideNakshatra,
    required this.brideRasi,
    required this.groomNakshatra,
    required this.groomRasi,
    required this.brideTimeKnown,
    required this.groomTimeKnown,
  });

  final AshtakootaResult ashtakoota;
  final PorondamResult porondam;
  final KujaDoshaMatch kuja;

  final Nakshatra brideNakshatra;
  final Rasi brideRasi;
  final Nakshatra groomNakshatra;
  final Rasi groomRasi;

  /// Both systems read the Moon's nakṣatra, which moves roughly one nakṣatra
  /// a day. An unknown birth time can therefore land the Moon in a
  /// neighbouring nakṣatra and change several factors at once — worth saying
  /// on screen rather than leaving a reader to trust a precise-looking score.
  final bool brideTimeKnown;
  final bool groomTimeKnown;

  bool get anyTimeUnknown => !brideTimeKnown || !groomTimeKnown;
}

/// The match, or null until a partner has been entered.
final matchProvider = Provider<MatchResult?>((ref) {
  final mine = ref.watch(profileProvider);
  final partner = ref.watch(partnerProvider);
  final role = ref.watch(brideRoleProvider);

  if (mine == null || partner == null) return null;

  final (bride, groom) =
      role == BrideRole.me ? (mine, partner) : (partner, mine);

  BirthChart? chartFor(BirthProfile p) => Ephemeris.computeChart(
    localWallClock: p.localWallClock,
    zoneName: p.place.timezone,
    latitude: p.place.latitude,
    longitude: p.place.longitude,
  ).valueOrNull;

  final brideChart = chartFor(bride);
  final groomChart = chartFor(groom);
  if (brideChart == null || groomChart == null) return null;

  final bn = brideChart.birthNakshatra;
  final br = brideChart[Graha.moon].rasi;
  final gn = groomChart.birthNakshatra;
  final gr = groomChart[Graha.moon].rasi;

  return MatchResult(
    ashtakoota: Ashtakoota.match(
      brideNakshatra: bn,
      brideRasi: br,
      groomNakshatra: gn,
      groomRasi: gr,
    ),
    porondam: Porondams.match(
      brideNakshatra: bn,
      brideRasi: br,
      groomNakshatra: gn,
      groomRasi: gr,
    ),
    kuja: KujaDosha.compare(brideChart, groomChart),
    brideNakshatra: bn,
    brideRasi: br,
    groomNakshatra: gn,
    groomRasi: gr,
    brideTimeKnown: bride.birthTimeKnown,
    groomTimeKnown: groom.birthTimeKnown,
  );
});
