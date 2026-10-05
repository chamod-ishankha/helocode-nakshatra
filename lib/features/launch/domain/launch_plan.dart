/// What plays between the platform splash and the first real screen (KAN-81).
enum LaunchScene {
  /// The HeloCode Labs mark drawing itself. The publisher's moment, the same
  /// on every HeloCode app, so it is always dark.
  heloCode,

  /// The Nakshatra star drawing itself, the name, the tagline. For a reader
  /// meeting the app for the first time.
  splash,

  /// The finished star, already where the platform splash left it, and the
  /// name fading in beneath. For everyone else: an acknowledgement, not a wait.
  splashBrief,
}

/// Which scenes a launch plays, and for how long.
///
/// Kept apart from the widgets because the rule is the part that can be wrong
/// in a way nobody notices on one device: a returning user made to sit through
/// a publisher's logo every morning, on an app opened to check one time.
class LaunchPlan {
  const LaunchPlan._(this.scenes, {required this.reduceMotion});

  /// Decided once, from whether this install already has someone's chart.
  ///
  /// "Has a profile" rather than a separate first-run flag on purpose. A user
  /// who deleted their details is starting over and should be met as new —
  /// language first — and a reinstall that restored a backup should not be.
  factory LaunchPlan.forStart({
    required bool hasProfile,
    bool reduceMotion = false,
  }) => LaunchPlan._(
    hasProfile
        ? const [LaunchScene.splashBrief]
        : const [LaunchScene.heloCode, LaunchScene.splash],
    reduceMotion: reduceMotion,
  );

  final List<LaunchScene> scenes;

  /// With reduced motion on, nothing draws itself: each scene shows its
  /// finished frame, briefly, so the brand is still seen.
  final bool reduceMotion;

  bool get isFirstLaunch => scenes.contains(LaunchScene.heloCode);

  /// How long [scene] holds the screen, including its own animation.
  Duration durationOf(LaunchScene scene) {
    if (reduceMotion) {
      return switch (scene) {
        LaunchScene.heloCode => const Duration(milliseconds: 900),
        LaunchScene.splash => const Duration(milliseconds: 1100),
        LaunchScene.splashBrief => const Duration(milliseconds: 500),
      };
    }
    return switch (scene) {
      LaunchScene.heloCode => const Duration(milliseconds: 2400),
      LaunchScene.splash => const Duration(milliseconds: 3000),
      LaunchScene.splashBrief => const Duration(milliseconds: 1100),
    };
  }

  /// The fade from the last scene into the app.
  static const Duration exitFade = Duration(milliseconds: 350);

  /// Everything before the first real screen is usable.
  Duration get total =>
      scenes.fold(Duration.zero, (sum, s) => sum + durationOf(s)) + exitFade;
}
