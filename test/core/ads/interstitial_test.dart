import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/ads/ad_gate.dart';
import 'package:nakshatra/core/ads/interstitial.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Running the ad policy at a placement (KAN-55).
///
/// [AdGate] already decides *whether* a full-screen ad may appear, and that is
/// tested on its own. What is new here is the part that spends the decision:
/// asking for the ad, and starting the three-minute cooldown only if one
/// actually interrupted somebody.
void main() {
  late SharedPreferences prefs;

  final launched = DateTime(2026, 9, 10, 8);
  var now = launched.add(const Duration(minutes: 5));

  AdGate gate({
    bool entitled = false,
    bool configured = true,
    bool profile = true,
  }) => AdGate(
    prefs: prefs,
    hasEntitlement: entitled,
    hasProfile: profile,
    isConfigured: configured,
    launchedAt: launched,
    clock: () => now,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    now = launched.add(const Duration(minutes: 5));
  });

  group('showing', () {
    test('a purchaser is never asked for an ad at all', () async {
      var asked = false;
      final controller = InterstitialController(
        gate: gate(entitled: true),
        present: () async {
          asked = true;
          return true;
        },
        preload: () async {},
      );

      expect(await controller.showIfAllowed(), isFalse);
      expect(asked, isFalse, reason: 'the SDK should not even be called');
    });

    test('nothing shows inside the session grace period', () async {
      now = launched.add(const Duration(seconds: 30));
      final controller = InterstitialController(
        gate: gate(),
        present: () async => true,
        preload: () async {},
      );

      expect(await controller.showIfAllowed(), isFalse);
    });

    test('one shows once the grace has passed', () async {
      final controller = InterstitialController(
        gate: gate(),
        present: () async => true,
        preload: () async {},
      );

      expect(await controller.showIfAllowed(), isTrue);
    });
  });

  group('spending the cooldown', () {
    test('a shown ad starts it', () async {
      // The whole point of recording: the next placement, three minutes of
      // reading later, has to know this one happened.
      var shows = 0;
      InterstitialController build() => InterstitialController(
        gate: gate(),
        present: () async {
          shows++;
          return true;
        },
        preload: () async {},
      );

      expect(await build().showIfAllowed(), isTrue);

      now = now.add(const Duration(minutes: 1));
      expect(await build().showIfAllowed(), isFalse);
      expect(shows, 1);

      now = now.add(const Duration(minutes: 3));
      expect(await build().showIfAllowed(), isTrue);
      expect(shows, 2);
    });

    test('an ad that did not fill does not start it', () async {
      // No fill is the common case in a small market. Treating it as an
      // interruption would silently suppress the next real opportunity — the
      // user would be shown fewer ads the worse the fill rate got.
      final empty = InterstitialController(
        gate: gate(),
        present: () async => false,
        preload: () async {},
      );

      expect(await empty.showIfAllowed(), isFalse);

      final filled = InterstitialController(
        gate: gate(),
        present: () async => true,
        preload: () async {},
      );
      expect(
        await filled.showIfAllowed(),
        isTrue,
        reason: 'the failed attempt must not have spent the cooldown',
      );
    });

    test('it survives the app being killed and reopened', () async {
      // AdGate persists it; this is the placement end of that guarantee, and
      // it is on the acceptance for this ticket.
      final first = InterstitialController(
        gate: gate(),
        present: () async => true,
        preload: () async {},
      );
      expect(await first.showIfAllowed(), isTrue);

      // A fresh launch: a new gate, a new session, same preferences.
      final relaunch = AdGate(
        prefs: prefs,
        hasEntitlement: false,
        hasProfile: true,
        isConfigured: true,
        launchedAt: now,
        clock: () => now.add(const Duration(minutes: 2)),
      );

      expect(
        await InterstitialController(
          gate: relaunch,
          present: () async => true,
          preload: () async {},
        ).showIfAllowed(),
        isFalse,
      );
    });
  });

  group('preloading', () {
    test('nothing is fetched for somebody who paid', () async {
      // Not just "would not be shown". A load still asks AdMob for an ad,
      // still spends their data, and still reports which screen they opened —
      // for a user whose entire purchase was to stop that.
      var loads = 0;
      await InterstitialController(
        gate: gate(entitled: true),
        present: () async => true,
        preload: () async => loads++,
      ).prepare();

      expect(loads, 0);
    });

    test('nothing is fetched in a build with no ad ids', () async {
      var loads = 0;
      await InterstitialController(
        gate: gate(configured: false),
        present: () async => true,
        preload: () async => loads++,
      ).prepare();

      expect(loads, 0);
    });

    test('the cooldown does not hold back a load', () async {
      // Deliberate. It may well expire while the user is reading, and a loaded
      // ad that goes unshown costs nothing — a placement with nothing ready
      // earns nothing.
      await InterstitialController(
        gate: gate(),
        present: () async => true,
        preload: () async {},
      ).showIfAllowed();

      var loads = 0;
      await InterstitialController(
        gate: gate(),
        present: () async => true,
        preload: () async => loads++,
      ).prepare();

      expect(loads, 1);
    });
  });
}
