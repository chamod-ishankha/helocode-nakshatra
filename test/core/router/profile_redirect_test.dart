import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/router/app_router.dart';

/// Who is allowed onto the onboarding wizard, and who is sent away from it.
///
/// Three cases, and the rule has to tell all three apart:
///
///  * no profile — everything funnels into the wizard, because there is
///    nothing to show until it is finished;
///  * a profile, and the wizard was landed on by accident (a restored location
///    after a restart, a stale redirect) — send them home;
///  * a profile, and the wizard was asked for — let them in, because it is the
///    only editor the app has.
///
/// The second rule was written first and ate the third, so Settings > "Edit
/// birth details" bounced straight back to home and birth details could not be
/// corrected at all — on an app whose every output depends on them (KAN-61).
/// Nothing tested the redirect, so a dead row on the settings screen shipped
/// to closed testing.
void main() {
  group('without a profile', () {
    test('every route funnels into onboarding', () {
      for (final target in [
        Routes.home,
        Routes.chart,
        Routes.settings,
        Routes.calendar,
      ]) {
        expect(
          redirectFor(location: target, hasProfile: false),
          Routes.onboarding,
          reason: '$target should redirect to onboarding',
        );
      }
    });

    test('onboarding itself is left alone', () {
      expect(
        redirectFor(location: Routes.onboarding, hasProfile: false),
        isNull,
      );
    });

    test('the edit flag changes nothing when there is nothing to edit', () {
      expect(
        redirectFor(location: Routes.editProfile, hasProfile: false),
        isNull,
      );
    });
  });

  group('with a profile', () {
    test('landing on onboarding by accident goes home', () {
      expect(
        redirectFor(location: Routes.onboarding, hasProfile: true),
        Routes.home,
      );
    });

    test('asking to edit is allowed through', () {
      expect(
        redirectFor(location: Routes.editProfile, hasProfile: true),
        isNull,
        reason: 'Settings > "Edit birth details" must reach the wizard',
      );
    });

    test('ordinary routes are left alone', () {
      for (final target in [Routes.home, Routes.chart, Routes.settings]) {
        expect(redirectFor(location: target, hasProfile: true), isNull);
      }
    });

    test('a flag that is not the flag does not open the wizard', () {
      // The check is exact on purpose. Anything else — a truthy-looking value,
      // a different key — is not a deliberate edit and should be turned away
      // rather than quietly let through.
      for (final location in [
        '${Routes.onboarding}?edit=0',
        '${Routes.onboarding}?edit=true',
        '${Routes.onboarding}?editing=1',
        '${Routes.onboarding}?edit=',
      ]) {
        expect(
          redirectFor(location: location, hasProfile: true),
          Routes.home,
          reason: '$location is not the edit location',
        );
      }
    });
  });

  test('the edit location is the onboarding path with the flag', () {
    // Guards the two halves against drifting apart: the rule matches on the
    // path and reads the flag, so a typo in either silently disables editing
    // rather than failing loudly.
    final uri = Uri.parse(Routes.editProfile);

    expect(uri.path, Routes.onboarding);
    expect(uri.queryParameters['edit'], '1');
  });
}
