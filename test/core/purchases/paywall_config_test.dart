import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/ads/ad_gate.dart';
import 'package:nakshatra/core/purchases/entitlements.dart';
import 'package:nakshatra/core/purchases/paywall_config.dart';
import 'package:nakshatra/core/purchases/products.dart';
import 'package:nakshatra/core/purchases/purchase_controller.dart';
import 'package:nakshatra/features/onboarding/data/profile_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What Remote Config is allowed to do to the paywall (KAN-36).
///
/// A config value is a live wire: it changes behaviour on a phone in
/// somebody's hand, with no release and no review. Everything here is about
/// bounding the damage a wrong one can do.
void main() {
  group('parsing', () {
    test('nothing set is the compiled-in default', () {
      final config = PaywallConfig.parse();

      expect(config.variant, PaywallVariant.value);
      expect(config.freeFeatures, isEmpty);
      expect(config.highlight, PurchaseProduct.proYearly);
    });

    test('a value nobody understands falls back rather than throwing', () {
      // Somebody will type "Value" or "yearly_plan" into the console at some
      // point. It must land on the default, not on a crash in a screen.
      final config = PaywallConfig.parse(
        variant: 'Value',
        freeFeatures: 'nonsense,,  ,',
        highlight: 'lifetime',
      );

      expect(config.variant, PaywallVariant.value);
      expect(config.freeFeatures, isEmpty);
      expect(config.highlight, PurchaseProduct.proYearly);
    });

    test('the variant and the highlighted tier can be switched', () {
      final config = PaywallConfig.parse(
        variant: 'support',
        highlight: 'pro_monthly',
      );

      expect(config.variant, PaywallVariant.support);
      expect(config.highlight, PurchaseProduct.proMonthly);
    });

    test('a list of soft features is read, spaces and all', () {
      final config = PaywallConfig.parse(
        freeFeatures: 'fullDashaTimeline, divisionalCharts',
      );

      expect(config.freeFeatures, {
        PaidFeature.fullDashaTimeline,
        PaidFeature.divisionalCharts,
      });
    });
  });

  group('what a config value may not give away', () {
    test('it cannot switch off ads for everybody', () {
      // Ads are the revenue floor and there is no signal when they stop:
      // impressions simply go to zero, which looks like a quiet week. A typo
      // must not be able to do that.
      final config = PaywallConfig.parse(freeFeatures: 'removeAds');

      expect(config.isFree(PaidFeature.removeAds), isFalse);
    });

    test('it cannot hand out a product somebody else paid for', () {
      final config = PaywallConfig.parse(
        freeFeatures: 'birthChartPdf,compatibilityReport',
      );

      expect(config.freeFeatures, isEmpty);
    });

    test('it drops what it may not open and keeps the rest', () {
      // A partly-wrong value must not fail closed on the whole list, or an
      // experiment would silently stop halfway.
      final config = PaywallConfig.parse(
        freeFeatures: 'removeAds,transitAlerts',
      );

      expect(config.freeFeatures, {PaidFeature.transitAlerts});
    });

    test('the openable set is exactly the subscription-only features', () {
      // Derived from the ladder rather than listed, so adding a product keeps
      // this honest. Anything sold outright is off limits by construction.
      expect(PaywallConfig.freeable, {
        PaidFeature.unlimitedCompatibility,
        PaidFeature.fullDashaTimeline,
        PaidFeature.divisionalCharts,
        PaidFeature.transitAlerts,
        PaidFeature.multipleProfiles,
      });
    });
  });

  group('against the live feature gate', () {
    late SharedPreferences prefs;

    ProviderContainer harness(PaywallConfig config) {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          paywallConfigProvider.overrideWithValue(config),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('a freed feature opens without anybody paying', () {
      final container = harness(
        PaywallConfig.parse(freeFeatures: 'fullDashaTimeline'),
      );

      expect(
        container.read(featureProvider(PaidFeature.fullDashaTimeline)),
        isTrue,
      );
      // And only that one.
      expect(
        container.read(featureProvider(PaidFeature.divisionalCharts)),
        isFalse,
      );
    });

    test('config never reaches the ads decision', () {
      // Belt and braces on the rule above, checked where it actually matters:
      // the provider every ad placement reads.
      final container = harness(
        PaywallConfig.parse(freeFeatures: 'removeAds,fullDashaTimeline'),
      );

      expect(container.read(adFreeEntitlementProvider), isFalse);
    });

    test('a purchase still wins when config says nothing', () async {
      final container = harness(PaywallConfig.defaults);
      final store = container.read(entitlementsProvider.notifier);

      expect(container.read(featureProvider(PaidFeature.removeAds)), isFalse);

      // Straight into the notifier, standing in for a completed purchase.
      store.state = EntitlementSnapshot(
        grants: const {Entitlement.adFree: null},
        refreshedAt: DateTime(2026),
      );

      expect(container.read(featureProvider(PaidFeature.removeAds)), isTrue);
    });
  });
}
