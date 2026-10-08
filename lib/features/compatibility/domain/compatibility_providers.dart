import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/astro/compatibility/ashtakoota.dart';
import '../../../core/astro/compatibility/kuja_dosha.dart';
import '../../../core/astro/compatibility/porondam.dart';
import '../../../core/astro/ephemeris.dart';
import '../../../core/astro/models.dart';
import '../../../core/purchases/pro_usage.dart';
import '../../onboarding/data/profile_repository.dart';
import '../data/partner_repository.dart';
import '../../onboarding/domain/birth_profile.dart';

/// Which matching system is on screen.
enum MatchSystem { porondam, ashtakoota }

/// Which of the two people is the bride.
///
/// This is not cosmetic. Varṇa, tāra, strī dīrgha and rāśi are all counted
/// from the bride to the groom and give a different answer reversed, so the
/// app has to ask rather than assume.
enum BrideRole { me, partner }

/// The partner's details, kept on this phone between launches.
///
/// It used to be held in memory only, so Android reclaiming the app in the
/// background silently dropped the partner and the reader had to type them in
/// again. See [PartnerRepository] for why it is stored locally and not synced.
class PartnerNotifier extends Notifier<BirthProfile?> {
  @override
  BirthProfile? build() => ref.watch(partnerRepositoryProvider).load();

  void set(BirthProfile profile) {
    state = profile;
    unawaited(ref.read(partnerRepositoryProvider).save(profile));
    // A partner entered is a match checked — counted for Pro's meter (KAN-77).
    unawaited(
      ref
          .read(proUsageRevisionProvider.notifier)
          .record(ProUsage.compatibilityCheck),
    );
  }

  Future<void> clear() async {
    state = null;
    await ref.read(partnerRepositoryProvider).clear();
  }
}

/// The partner the form describes.
///
/// The time wheel opens on 6:00 AM and that is what the reader sees as their
/// answer, so an untouched wheel ([time] null) is 6:00 AM, known. It used to
/// count as "time unknown", which put the missing-time warning on a match
/// where nobody had said the time was missing. Only the box ([timeKnown]
/// false) says that.
BirthProfile partnerFromForm({
  required String name,
  required DateTime date,
  required Duration? time,
  required bool timeKnown,
  required Place place,
}) => BirthProfile(
  name: name.trim(),
  birthDate: date,
  birthTime: timeKnown
      ? (time ?? BirthProfile.defaultUnknownTime)
      : BirthProfile.defaultUnknownTime,
  place: place,
  birthTimeKnown: timeKnown,
);

final partnerRepositoryProvider = Provider<PartnerRepository>(
  (ref) => PartnerRepository(ref.watch(sharedPreferencesProvider)),
);

final partnerProvider = NotifierProvider<PartnerNotifier, BirthProfile?>(
  PartnerNotifier.new,
);

class MatchSystemNotifier extends Notifier<MatchSystem> {
  // Porondam first: this app's first audience reads porondam, not guṇa milan.
  @override
  MatchSystem build() => MatchSystem.porondam;

  void set(MatchSystem s) => state = s;
}

final matchSystemProvider = NotifierProvider<MatchSystemNotifier, MatchSystem>(
  MatchSystemNotifier.new,
);

class BrideRoleNotifier extends Notifier<BrideRole> {
  @override
  BrideRole build() => BrideRole.me;

  void set(BrideRole r) => state = r;
}

final brideRoleProvider = NotifierProvider<BrideRoleNotifier, BrideRole>(
  BrideRoleNotifier.new,
);

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

  final (bride, groom) = role == BrideRole.me
      ? (mine, partner)
      : (partner, mine);

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
