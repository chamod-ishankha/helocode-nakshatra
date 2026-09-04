/// Build flavors.
///
/// Each flavor maps to an Android product flavor with a distinct
/// `applicationId` suffix, so dev, staging and prod can all be installed on the
/// same device at once. See `android/app/build.gradle.kts`.
enum Flavor {
  dev,
  staging,
  prod;

  bool get isDev => this == Flavor.dev;
  bool get isProd => this == Flavor.prod;
}

/// Per-flavor settings, resolved once at startup by the flavor entrypoint.
///
/// Read this through `flavorProvider` rather than the static [current] field
/// wherever a widget or provider needs it — that keeps tests able to override
/// the value instead of depending on global state.
class FlavorConfig {
  const FlavorConfig({
    required this.flavor,
    required this.appName,
    required this.enableAnalytics,
    required this.enableAds,
    required this.verboseLogging,
  });

  final Flavor flavor;
  final String appName;

  /// Off outside prod so development traffic never pollutes real metrics.
  final bool enableAnalytics;

  /// Off outside prod. Serving live ads to a developer's own device risks a
  /// permanent AdMob ban for invalid traffic; test ad units are used instead.
  final bool enableAds;

  final bool verboseLogging;

  /// Defaults to dev so anything reading this before [initialize] runs — a
  /// widget test, a tool entrypoint — gets safe values rather than throwing or
  /// silently enabling live ads. Not `late final`: tests re-initialise freely.
  static FlavorConfig current = _configFor(Flavor.dev);

  static void initialize(Flavor flavor) => current = _configFor(flavor);

  static FlavorConfig _configFor(Flavor flavor) {
    return switch (flavor) {
      Flavor.dev => const FlavorConfig(
        flavor: Flavor.dev,
        appName: 'Nakshatra Dev',
        enableAnalytics: false,
        enableAds: false,
        verboseLogging: true,
      ),
      Flavor.staging => const FlavorConfig(
        flavor: Flavor.staging,
        appName: 'Nakshatra Staging',
        enableAnalytics: false,
        enableAds: false,
        verboseLogging: true,
      ),
      Flavor.prod => const FlavorConfig(
        flavor: Flavor.prod,
        appName: 'Nakshatra',
        enableAnalytics: true,
        enableAds: true,
        verboseLogging: false,
      ),
    };
  }
}
