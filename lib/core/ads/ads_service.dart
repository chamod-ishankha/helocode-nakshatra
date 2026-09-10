import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../logging/app_logger.dart';
import 'ad_gate.dart';

/// Starts the ads SDK and handles consent (KAN-34).
///
/// ## Nothing here may take the app down
///
/// Every entry point swallows its failures, the same way [FirebaseService]
/// does. An app that will not open because an ad network is unreachable earns
/// nothing at all, and this one's core — charts, nekath, the almanac — is
/// computed on the device and needs no network whatsoever.
///
/// ## Consent
///
/// The UMP SDK decides whether a form is needed from the user's region, so
/// this asks it unconditionally rather than trying to detect the EEA itself.
/// Outside the regions that require one it resolves immediately and shows
/// nothing.
abstract final class AdsService {
  static bool _started = false;
  static String? _lastError;
  static final Completer<bool> _ready = Completer<bool>();

  /// Whether the SDK came up. False leaves every placement empty.
  static bool get isReady => _started;

  /// Completes once initialisation has finished, either way.
  ///
  /// A placement built during the first frames would otherwise check
  /// [isReady], find it false, and never look again — nothing rebuilds a
  /// widget just because an SDK finished starting. Awaiting this is what makes
  /// the difference between a banner that appears and one that never does.
  static Future<bool> get ready => _ready.future;

  static void _finish(bool ok) {
    _started = ok;
    if (!_ready.isCompleted) _ready.complete(ok);
  }

  static String? get lastError => _lastError;

  /// Called once at startup, before the first frame is not required.
  ///
  /// Deliberately not awaited by [bootstrap]: the SDK takes a second or two to
  /// initialise, and the daily screen is the reason people opened the app.
  static Future<void> initialize() async {
    if (_started) return;

    if (!AdUnits.isConfigured) {
      _lastError = 'no ad unit ids in this build';
      AppLogger.info('Ads disabled: $_lastError');
      _finish(false);
      return;
    }

    try {
      // Set before initialise so the very first request already carries it.
      // A live unit that serves a real ad to a tester once is enough to put
      // the account at risk.
      final testDevices = AdUnits.testDeviceIds;
      if (testDevices.isNotEmpty) {
        await MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(testDeviceIds: testDevices),
        );
        AppLogger.info('Ads: ${testDevices.length} test device(s) registered');
      }

      await MobileAds.instance.initialize();
      _finish(true);
      AppLogger.info('Mobile Ads initialised');
      // Consent is requested after initialisation rather than before, so a
      // consent failure cannot stop ads from serving to users who never
      // needed a form.
      unawaited(_requestConsent());
    } on Object catch (e, s) {
      _lastError = '$e';
      _finish(false);
      AppLogger.warn(
        'Mobile Ads failed to start, continuing without ads',
        e,
        s,
      );
    }
  }

  /// Asks UMP whether this user needs a consent form, and shows it if so.
  static Future<void> _requestConsent() async {
    final completer = Completer<void>();

    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        ConsentForm.loadAndShowConsentFormIfRequired((error) {
          if (error != null) {
            AppLogger.warn('Consent form: ${error.message}');
          }
          if (!completer.isCompleted) completer.complete();
        });
      },
      (error) {
        // Not fatal. Without consent the SDK serves non-personalised ads,
        // which is worth less but is still worth something.
        AppLogger.warn('Consent info update failed: ${error.message}');
        if (!completer.isCompleted) completer.complete();
      },
    );

    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => AppLogger.warn('Consent request timed out'),
    );
  }

  static InterstitialAd? _interstitial;
  static bool _loadingInterstitial = false;

  /// Starts loading an interstitial, if one is not already waiting (KAN-55).
  ///
  /// Preloaded rather than fetched at the moment of showing. A load takes a
  /// second or three; asking for one as the user leaves a screen means they
  /// watch the next screen sit there and then get hit by an ad, which is both
  /// a worse interruption and a worse fill rate.
  ///
  /// Never throws, and never queues a second load — an unfilled request that
  /// is retried on every visit is how an app gets its request rate flagged.
  static Future<void> preloadInterstitial() async {
    if (!_started || _interstitial != null || _loadingInterstitial) return;

    final unitId = AdUnits.forSlot(AdSlot.interstitial);
    if (unitId == null) return;

    _loadingInterstitial = true;
    try {
      await InterstitialAd.load(
        adUnitId: unitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitial = ad;
            _loadingInterstitial = false;
          },
          onAdFailedToLoad: (error) {
            // Ordinary: no fill is the common case in a small market.
            AppLogger.info('No interstitial filled: ${error.message}');
            _loadingInterstitial = false;
          },
        ),
      );
    } on Object catch (e, s) {
      AppLogger.warn('Interstitial load threw', e, s);
      _loadingInterstitial = false;
    }
  }

  /// Shows the preloaded interstitial. True only if it really appeared.
  ///
  /// Returns false rather than waiting when nothing is loaded. A placement
  /// that blocks the user while an ad is fetched is worse than a missed
  /// impression, and the caller uses this answer to decide whether the
  /// cooldown has been spent.
  static Future<bool> showInterstitial() async {
    final ad = _interstitial;
    if (ad == null) return false;

    // Cleared before showing, so a second placement firing at the same moment
    // cannot try to show the same ad twice.
    _interstitial = null;

    var shown = true;
    final closed = Completer<void>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!closed.isCompleted) closed.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        AppLogger.warn('Interstitial failed to show: ${error.message}');
        ad.dispose();
        shown = false;
        if (!closed.isCompleted) closed.complete();
      },
    );

    try {
      await ad.show();
    } on Object catch (e, s) {
      AppLogger.warn('Interstitial show threw', e, s);
      return false;
    }

    await closed.future;
    return shown;
  }

  /// Loads a rewarded ad and shows it, resolving true only if the reward was
  /// actually earned.
  ///
  /// A user who dismisses the ad early has not earned anything, and unlocking
  /// the content anyway would train them to always dismiss it.
  static Future<bool> showRewarded() async {
    final unitId = AdUnits.forSlot(AdSlot.rewarded);
    if (!_started || unitId == null) return false;

    final loaded = Completer<RewardedAd?>();

    try {
      await RewardedAd.load(
        adUnitId: unitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: loaded.complete,
          onAdFailedToLoad: (error) {
            AppLogger.warn('Rewarded ad failed to load: ${error.message}');
            loaded.complete(null);
          },
        ),
      );
    } on Object catch (e, s) {
      AppLogger.warn('Rewarded ad load threw', e, s);
      return false;
    }

    final ad = await loaded.future.timeout(
      const Duration(seconds: 20),
      onTimeout: () => null,
    );
    if (ad == null) return false;

    var earned = false;
    final closed = Completer<void>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!closed.isCompleted) closed.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        AppLogger.warn('Rewarded ad failed to show: ${error.message}');
        ad.dispose();
        if (!closed.isCompleted) closed.complete();
      },
    );

    await ad.show(onUserEarnedReward: (_, _) => earned = true);
    await closed.future;
    return earned;
  }
}
