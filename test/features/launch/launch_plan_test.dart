import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/features/launch/domain/launch_plan.dart';

/// What plays before the first real screen (KAN-81).
///
/// The rule that matters is the one nobody notices on their own phone: a
/// returning reader, opening the app to check one time, must not sit through
/// the publisher's logo or the star drawing itself every morning.
void main() {
  group('a first launch', () {
    final plan = LaunchPlan.forStart(hasProfile: false);

    test('plays the publisher, then the splash, in that order', () {
      expect(plan.scenes, [LaunchScene.heloCode, LaunchScene.splash]);
      expect(plan.isFirstLaunch, isTrue);
    });

    test('lets the star finish drawing before it leaves', () {
      // The splash draws over its first 60%; anything under ~2s would cut the
      // drawing off before the name has faded in.
      expect(
        plan.durationOf(LaunchScene.splash),
        greaterThanOrEqualTo(const Duration(seconds: 2)),
      );
    });
  });

  group('a returning reader', () {
    final plan = LaunchPlan.forStart(hasProfile: true);

    test('never sees the publisher or the drawing', () {
      expect(plan.scenes, [LaunchScene.splashBrief]);
      expect(plan.isFirstLaunch, isFalse);
    });

    test('is in the app in under a second and a half', () {
      // A ceiling, so the splash cannot grow by a tweak at a time into a
      // wait the daily reader pays on every open.
      expect(plan.total, lessThan(const Duration(milliseconds: 1500)));
    });
  });

  group('reduced motion', () {
    test('shortens every scene, and keeps the same scenes', () {
      for (final hasProfile in [false, true]) {
        final normal = LaunchPlan.forStart(hasProfile: hasProfile);
        final reduced = LaunchPlan.forStart(
          hasProfile: hasProfile,
          reduceMotion: true,
        );

        expect(reduced.scenes, normal.scenes);
        for (final scene in normal.scenes) {
          expect(
            reduced.durationOf(scene),
            lessThan(normal.durationOf(scene)),
            reason: '$scene should be shorter with reduced motion',
          );
        }
      }
    });
  });

  test('total is every scene plus the fade out', () {
    final plan = LaunchPlan.forStart(hasProfile: false);
    expect(
      plan.total,
      plan.durationOf(LaunchScene.heloCode) +
          plan.durationOf(LaunchScene.splash) +
          LaunchPlan.exitFade,
    );
  });
}
