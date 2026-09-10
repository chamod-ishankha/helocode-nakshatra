import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/onboarding/data/profile_repository.dart';
import '../config/remote_config_service.dart';
import '../logging/analytics_service.dart';
import '../logging/app_logger.dart';
import 'entitlement_cache.dart';
import 'entitlements.dart';
import 'paywall_config.dart';
import 'products.dart';
import 'purchase_gateway.dart';

/// How restoring purchases ended. Each needs its own sentence on screen: a
/// user who taps Restore because they are seeing ads they paid to remove has
/// to be told which of these happened.
enum RestoreOutcome {
  /// Something came back and the app now knows about it.
  restored,

  /// The store answered, and this account owns nothing.
  nothingFound,

  /// The store could not be reached.
  failed,

  /// This build cannot sell or restore anything.
  unavailable,
}

/// The store, for the app to talk to.
///
/// Defaults to the disabled one so every test, and any build without a
/// RevenueCat key, gets a working app that simply cannot sell anything.
/// [bootstrap] overrides it with the real gateway.
final purchaseGatewayProvider = Provider<PurchaseGateway>(
  (ref) => const DisabledPurchaseGateway(),
);

/// The clock the entitlement rules read. Overridden in tests.
final purchaseClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// What the user is entitled to, right now.
///
/// Seeded synchronously from the cache in [build], so the first frame already
/// knows whether to show ads. The network refresh happens in [start] and
/// corrects it a moment later.
class EntitlementNotifier extends Notifier<EntitlementSnapshot> {
  EntitlementCache get _cache =>
      EntitlementCache(ref.read(sharedPreferencesProvider));

  PurchaseGateway get _gateway => ref.read(purchaseGatewayProvider);

  DateTime get _now => ref.read(purchaseClockProvider)();

  @override
  EntitlementSnapshot build() => _cache.read() ?? EntitlementSnapshot.unknown();

  /// Subscribes to store updates and asks it once for the truth.
  ///
  /// Call after the first frame. The listener is what makes a slow payment
  /// method work at all: a cash or wallet purchase is PENDING when the user
  /// leaves the sheet and becomes an entitlement minutes later, with nothing
  /// in the app having asked.
  Future<void> start() async {
    _gateway.listen(_adopt);
    await refresh();
  }

  /// Asks the store and takes its answer as the truth.
  Future<void> refresh() async {
    final fresh = await _gateway.refresh();
    if (fresh == null) return; // Could not ask; keep what we had.
    await _adopt(fresh);
  }

  Future<PurchaseAttempt> buy(PurchaseProduct product) async {
    unawaitedLog('purchase_started', product);

    final attempt = await _gateway.buy(product);
    if (attempt.entitlements case final fresh?) await _adopt(fresh);

    unawaitedLog('purchase_${attempt.outcome.name}', product);
    return attempt;
  }

  Future<RestoreOutcome> restore() async {
    if (!_gateway.isReady) return RestoreOutcome.unavailable;

    final fresh = await _gateway.restore();
    if (fresh == null) return RestoreOutcome.failed;

    await _adopt(fresh);
    return fresh.activeAt(_now).isEmpty
        ? RestoreOutcome.nothingFound
        : RestoreOutcome.restored;
  }

  /// Follows the signed-in account, so purchases survive a new phone.
  Future<void> identify(String appUserId) async {
    await _gateway.identify(appUserId);
    await refresh();
  }

  /// On sign-out. The cache is cleared too: leaving the previous account's
  /// entitlements on screen would show the next person Pro they do not have.
  Future<void> forget() async {
    await _gateway.forget();
    await _cache.clear();
    state = EntitlementSnapshot.unknown();
    await refresh();
  }

  Future<void> _adopt(EntitlementSnapshot fresh) async {
    final before = state.activeAt(_now);
    state = fresh;
    await _cache.write(fresh);

    final after = fresh.activeAt(_now);
    if (!_sameSet(before, after)) {
      AppLogger.info(
        'Entitlements now: ${after.isEmpty ? "none" : after.map((e) => e.identifier).join(", ")}',
      );
    }
  }

  static bool _sameSet(Set<Entitlement> a, Set<Entitlement> b) =>
      a.length == b.length && a.every(b.contains);

  /// Product id and outcome only. Never the price — the store's own reporting
  /// is authoritative on revenue, and duplicating it here would put a number
  /// in analytics that can disagree with the money.
  void unawaitedLog(String event, PurchaseProduct product) {
    AnalyticsService.log(event, {'product': product.id});
  }
}

final entitlementsProvider =
    NotifierProvider<EntitlementNotifier, EntitlementSnapshot>(
      EntitlementNotifier.new,
    );

/// Whether a screen may show a paid feature (KAN-36's feature gate).
///
///     if (ref.watch(featureProvider(PaidFeature.fullDashaTimeline))) ...
///
/// One place to ask, so a new tier or a changed ladder never means auditing
/// every screen that gates something.
final featureProvider = Provider.family<bool, PaidFeature>((ref, feature) {
  // Checked first, and it can only ever say yes. Remote Config removes gates
  // and never adds one, so a stale or fat-fingered value can only be more
  // generous than the code — never lock somebody out of what they were told
  // they would get.
  if (ref.watch(paywallConfigProvider).isFree(feature)) return true;

  final snapshot = ref.watch(entitlementsProvider);
  return snapshot.has(feature, ref.watch(purchaseClockProvider)());
});

/// What Remote Config currently says about the paywall (KAN-36).
///
/// Read once per launch. Remote Config answers from a local cache that
/// [RemoteConfigService.initialize] refreshes in the background, so this is a
/// synchronous read of whatever arrived last time.
final paywallConfigProvider = Provider<PaywallConfig>(
  (ref) => PaywallConfig.parse(
    variant: RemoteConfigService.string('paywall_variant'),
    freeFeatures: RemoteConfigService.string('paywall_free_features'),
    highlight: RemoteConfigService.string('paywall_highlight_tier'),
  ),
);

/// Whether anything can be bought in this build.
final purchasesAvailableProvider = Provider<bool>(
  (ref) => ref.watch(purchaseGatewayProvider).isReady,
);

/// Store prices, in the user's own currency.
///
/// A future rather than a value: a paywall shows that it is loading until this
/// resolves, and shows nothing at all if it fails. It must never fall back to
/// a price written in the app — quoting LKR to somebody Play will charge in
/// USD is a price the app did not honour.
final storePricesProvider = FutureProvider<List<StorePrice>>(
  (ref) => ref.watch(purchaseGatewayProvider).prices(),
);
