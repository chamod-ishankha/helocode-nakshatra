/// Build-time configuration, supplied by `--dart-define-from-file`.
///
/// ## These are not secrets
///
/// Everything here is compiled into the APK and can be recovered by anyone who
/// unzips it. AdMob identifiers are declared in the Android manifest anyway,
/// and a RevenueCat *public* SDK key is published by design. Keeping them out
/// of source control lets dev and prod differ and makes rotation easy — it does
/// not make them confidential, and nothing that must stay confidential belongs
/// in this file.
///
/// Genuine secrets — the upload keystore, its passwords, a Play service account
/// JSON, a RevenueCat *secret* key — never reach the app at all. They live in
/// `android/key.properties` locally and in GitHub Actions secrets for CI.
///
/// ## Usage
///
///     flutter run --flavor dev --target lib/main_dev.dart \
///       --dart-define-from-file=env/dev.json
///
/// Values default to empty when the file is absent, so a fresh clone still
/// builds. [assertConfigured] is how a feature checks whether it can run.
abstract final class Env {
  static const String admobAppId = String.fromEnvironment('ADMOB_APP_ID');
  static const String admobBannerUnitId = String.fromEnvironment(
    'ADMOB_BANNER_UNIT_ID',
  );
  static const String admobInterstitialUnitId = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_UNIT_ID',
  );
  static const String admobRewardedUnitId = String.fromEnvironment(
    'ADMOB_REWARDED_UNIT_ID',
  );
  static const String revenueCatPublicKey = String.fromEnvironment(
    'REVENUECAT_PUBLIC_SDK_KEY',
  );

  static bool get hasAdmob =>
      admobAppId.isNotEmpty && admobBannerUnitId.isNotEmpty;

  static bool get hasRevenueCat => revenueCatPublicKey.isNotEmpty;

  /// Names of the values that are missing, for a diagnostic screen or log.
  static List<String> get missing => [
    if (admobAppId.isEmpty) 'ADMOB_APP_ID',
    if (admobBannerUnitId.isEmpty) 'ADMOB_BANNER_UNIT_ID',
    if (admobInterstitialUnitId.isEmpty) 'ADMOB_INTERSTITIAL_UNIT_ID',
    if (admobRewardedUnitId.isEmpty) 'ADMOB_REWARDED_UNIT_ID',
    if (revenueCatPublicKey.isEmpty) 'REVENUECAT_PUBLIC_SDK_KEY',
  ];
}
