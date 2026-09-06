import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../logging/app_logger.dart';
import 'ad_gate.dart';
import 'ads_service.dart';

/// An adaptive banner, or nothing at all.
///
/// Renders zero height until an ad has actually loaded, so a failed or
/// withheld ad leaves no gap in the layout — a reserved empty strip looks
/// broken, and on this app it would sit under the one thing people opened it
/// for.
///
/// ## Placement rule
///
/// Never put this next to a control that reveals a reading. Accidental clicks
/// beside a "show me my chart" button are the classic pattern that gets an
/// AdMob account banned permanently, and the ban is not appealable in
/// practice. Bottom of a scrolling page, below the content, with real spacing.
class BannerAdSlot extends ConsumerStatefulWidget {
  const BannerAdSlot({super.key});

  @override
  ConsumerState<BannerAdSlot> createState() => _BannerAdSlotState();
}

class _BannerAdSlotState extends ConsumerState<BannerAdSlot> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Once, and from here rather than initState because the adaptive size
    // needs the media query.
    if (_requested) return;
    _requested = true;
    _awaitSdkThenLoad();
  }

  /// Waits for the SDK before loading.
  ///
  /// Initialisation finishes a second or two after launch, long after the
  /// first frames. Checking readiness synchronously and giving up is why the
  /// banner never appeared at all on the first attempt at this.
  Future<void> _awaitSdkThenLoad() async {
    final ok = await AdsService.ready;
    if (!ok || !mounted) return;
    await _load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final unitId = AdUnits.forSlot(AdSlot.banner);
    if (_ad != null || !AdsService.isReady || unitId == null) return;

    // Adaptive: the height is chosen from the device width, which fills better
    // and pays better than the fixed 320x50.
    final width = MediaQuery.of(context).size.width.truncate();
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (size == null || !mounted) return;

    final ad = BannerAd(
      adUnitId: unitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          AppLogger.warn('Banner failed to load: ${error.message}');
          ad.dispose();
          if (mounted) setState(() => _ad = null);
        },
      ),
    );

    _ad = ad;
    await ad.load();
  }

  @override
  Widget build(BuildContext context) {
    // Watched rather than read once: buying Remove Ads must take the banner
    // away immediately, not at the next launch.
    if (!ref.watch(adGateProvider).allows(AdSlot.banner)) {
      return const SizedBox.shrink();
    }

    final ad = _ad;
    if (ad == null || !_loaded) return const SizedBox.shrink();

    return Padding(
      // Space above, so the ad never reads as part of the content it follows.
      padding: const EdgeInsets.only(top: 24),
      child: SizedBox(
        width: ad.size.width.toDouble(),
        height: ad.size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
