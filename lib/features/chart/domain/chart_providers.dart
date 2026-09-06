import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/astro/ephemeris.dart';
import '../../../core/astro/models.dart';
import '../../../core/error/result.dart';
import '../../onboarding/data/profile_repository.dart';

/// The computed chart for the saved profile.
///
/// Recomputes whenever the profile changes. Cheap enough to do synchronously —
/// a full chart is a handful of ephemeris calls — so there is no cache yet;
/// KAN-19 adds persistence when multiple profiles arrive.
///
/// Lives in domain rather than beside the chart screen because the horoscope
/// engine needs it too (KAN-31), and a feature's domain must not have to
/// import another feature's presentation to get at its data.
final chartProvider = Provider<Result<BirthChart>?>((ref) {
  final profile = ref.watch(profileProvider);
  if (profile == null) return null;

  return Ephemeris.computeChart(
    localWallClock: profile.localWallClock,
    zoneName: profile.place.timezone,
    latitude: profile.place.latitude,
    longitude: profile.place.longitude,
  );
});
