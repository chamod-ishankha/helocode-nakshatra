import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/ads/ad_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ad frequency policy (KAN-34).
///
/// Every rule here costs real money when it is wrong: a purchaser shown ads
/// asks for a refund, a user interrupted in their first minute uninstalls, and
/// an accidental-click pattern gets the AdMob account banned permanently. None
/// of that is visible by looking at the screen, which is why the policy is
/// separated from the SDK and tested on its own.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  final launch = DateTime(2026, 3, 10, 9, 0);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  AdGate gate({
    bool entitled = false,
    bool hasProfile = true,
    bool configured = true,
    Duration since = const Duration(minutes: 5),
  }) => AdGate(
    prefs: prefs,
    hasEntitlement: entitled,
    hasProfile: hasProfile,
    isConfigured: configured,
    launchedAt: launch,
    clock: () => launch.add(since),
  );

  group('who never sees an ad', () {
    test('a purchaser sees none of any kind', () {
      final g = gate(entitled: true);
      for (final slot in AdSlot.values) {
        expect(g.allows(slot), isFalse, reason: slot.name);
        expect(g.refuse(slot), AdRefusal.purchased);
      }
    });

    test('purchase outranks every other reason', () {
      // Entitlement is checked first on purpose. If a later rule happened to
      // allow an ad, a paying user would see one.
      final g = AdGate(
        prefs: prefs,
        hasEntitlement: true,
        hasProfile: false,
        isConfigured: false,
        launchedAt: launch,
        clock: () => launch,
      );
      expect(g.refuse(AdSlot.interstitial), AdRefusal.purchased);
    });

    test('nobody sees ads before onboarding is finished', () {
      // The user has been given nothing yet, so there is nothing to interrupt.
      final g = gate(hasProfile: false);
      for (final slot in AdSlot.values) {
        expect(g.refuse(slot), AdRefusal.noProfileYet, reason: slot.name);
      }
    });

    test('an unconfigured build shows nothing rather than crashing', () {
      // A fresh clone has no env file, so the unit ids are empty strings.
      final g = gate(configured: false);
      for (final slot in AdSlot.values) {
        expect(g.refuse(slot), AdRefusal.notConfigured, reason: slot.name);
      }
    });
  });

  group('the session grace period', () {
    test('no interstitial in the first ninety seconds', () {
      expect(
        gate(since: const Duration(seconds: 10)).refuse(AdSlot.interstitial),
        AdRefusal.withinSessionGrace,
      );
      expect(
        gate(since: const Duration(seconds: 89)).refuse(AdSlot.interstitial),
        AdRefusal.withinSessionGrace,
      );
    });

    test('allowed once the grace has passed', () {
      expect(
        gate(since: const Duration(seconds: 91)).allows(AdSlot.interstitial),
        isTrue,
      );
    });

    test('the banner is not held back by it', () {
      // It sits in the layout rather than interrupting, so there is nothing
      // to protect the first minute from.
      expect(gate(since: Duration.zero).allows(AdSlot.banner), isTrue);
    });

    test('a rewarded ad is never held back', () {
      // The user asked to watch it in exchange for something. Refusing would
      // withhold what they came for.
      expect(gate(since: Duration.zero).allows(AdSlot.rewarded), isTrue);
    });
  });

  group('the interstitial cooldown', () {
    test('a second one inside three minutes is refused', () async {
      final first = gate(since: const Duration(minutes: 5));
      expect(first.allows(AdSlot.interstitial), isTrue);
      await first.recordShown(AdSlot.interstitial);

      // Two minutes after the one just recorded.
      final soon = gate(since: const Duration(minutes: 7));
      expect(soon.refuse(AdSlot.interstitial), AdRefusal.withinCooldown);
    });

    test('allowed again once three minutes have passed', () async {
      final first = gate(since: const Duration(minutes: 5));
      await first.recordShown(AdSlot.interstitial);

      final later = gate(since: const Duration(minutes: 8, seconds: 1));
      expect(later.allows(AdSlot.interstitial), isTrue);
    });

    test('the cooldown survives a restart', () async {
      // Held in memory it would reset on every launch, and a user could be
      // shown one interstitial after another by killing the app — which is
      // exactly the person the rule exists to protect.
      final first = gate(since: const Duration(minutes: 5));
      await first.recordShown(AdSlot.interstitial);

      // A new gate with a fresh launch time, same storage.
      final relaunched = AdGate(
        prefs: prefs,
        hasEntitlement: false,
        hasProfile: true,
        isConfigured: true,
        // Relaunched right after, and checked two minutes later: past the
        // session grace, still inside the three-minute cooldown.
        launchedAt: launch.add(const Duration(minutes: 5)),
        clock: () => launch.add(const Duration(minutes: 7)),
      );
      expect(relaunched.refuse(AdSlot.interstitial), AdRefusal.withinCooldown);
    });

    test('only interstitials are recorded', () async {
      // Recording a banner or a rewarded view would start a cooldown that
      // silently blocks the next interstitial for no reason.
      final g = gate();
      await g.recordShown(AdSlot.banner);
      await g.recordShown(AdSlot.rewarded);

      expect(
        gate(since: const Duration(minutes: 5)).allows(AdSlot.interstitial),
        isTrue,
      );
    });

    test('reset clears it', () async {
      final g = gate(since: const Duration(minutes: 5));
      await g.recordShown(AdSlot.interstitial);
      await g.reset();

      expect(
        gate(since: const Duration(minutes: 6)).allows(AdSlot.interstitial),
        isTrue,
      );
    });
  });

  group('unit ids', () {
    test('an empty id is reported as absent, not passed to the SDK', () {
      // String.fromEnvironment gives '' when the define is missing, and
      // handing that to AdMob is an error rather than a no-op.
      for (final slot in AdSlot.values) {
        final id = AdUnits.forSlot(slot);
        expect(id, anyOf(isNull, isNotEmpty), reason: slot.name);
      }
    });

    test('an unset test-device list is empty, not a single blank id', () {
      // ''.split(',') is [''], not [], so a naive parse would register one
      // test device whose id is the empty string. Harmless-looking, but it
      // means nobody notices the list is not actually wired up.
      expect(AdUnits.testDeviceIds, isEmpty);
      expect(AdUnits.testDeviceIds, everyElement(isNotEmpty));
    });

    test('every slot is mapped', () {
      // A new slot with no id would silently fall through to null and never
      // show, which looks like a serving problem rather than a missing case.
      for (final slot in AdSlot.values) {
        expect(() => AdUnits.forSlot(slot), returnsNormally);
      }
    });
  });
}
