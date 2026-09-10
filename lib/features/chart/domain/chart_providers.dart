import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/astro/ephemeris.dart';
import '../../../core/astro/models.dart';
import '../../../core/error/result.dart';
import '../../onboarding/data/profile_repository.dart';

/// The computed chart for the saved profile.
///
/// Recomputes whenever the profile changes, and is memoised by Riverpod in
/// between — so it is computed once per profile, not once per screen.
///
/// ## There is no persistent cache, and there should not be
///
/// KAN-19 asked for one "so charts are computed once, not on every screen
/// open". Measured on the M115F — the cheapest phone this app targets — with a
/// profile build:
///
/// * a whole chart, warm: **0.28 ms**  (4.3 ms on the very first call)
/// * the navāṁśa derived from it: **0.025 ms**
/// * a full Vimśottarī timeline, two levels deep: **1.5 ms**
///
/// A frame is 16.7 ms. Ten complete charts fit inside a fifth of one. A cache
/// on disk would save a fraction of a millisecond once per launch and buy, in
/// exchange, a way for the app to show a chart that no longer matches the
/// engine — a silently wrong horoscope is the one failure this app cannot
/// afford, and it would only ever appear after an ayanāṃśa or engine change,
/// which is exactly when nobody is looking for it.
///
/// If this is ever revisited, the key must include the ayanāṃśa and an engine
/// version, and the reason for wanting it should be a measurement rather than
/// an assumption.
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
