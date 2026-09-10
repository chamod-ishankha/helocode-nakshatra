import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;

import '../config/flavor.dart';
import '../logging/app_logger.dart';
import '../logging/crash_reporter.dart';
import 'entitlements.dart';
import 'products.dart';
import 'purchase_gateway.dart';

/// The real store, through RevenueCat (KAN-35).
///
/// ## Why RevenueCat rather than `in_app_purchase`
///
/// A Play purchase token has to be checked against Google's servers, or a
/// rooted phone can hand the app a forged one. Doing that check ourselves
/// needs a server, and this project is on the Firebase Spark plan — no Cloud
/// Functions, no Admin SDK, so there is nowhere to put it. RevenueCat does
/// receipt validation, subscription state and cross-device restore on its own
/// backend, and its free tier covers the revenue this app will make for a long
/// time. The dependency buys the one thing the free stack cannot provide.
///
/// ## Everything here is caught
///
/// The same rule as Firebase, Crashlytics and ads: a store that is down, a
/// device with no Play Services, a build with no key — none of it may take the
/// app down or stop a chart being drawn. Failures return null or an outcome,
/// never an exception.
class RevenueCatGateway implements PurchaseGateway {
  RevenueCatGateway({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  bool _ready = false;

  @override
  bool get isReady => _ready;

  @override
  Future<bool> configure({required String publicKey, String? appUserId}) async {
    if (publicKey.isEmpty) {
      AppLogger.info('Purchases off: no RevenueCat key in this build');
      return false;
    }

    // A `test_` key is RevenueCat's Test Store: purchases are simulated, no
    // money moves, and — in the SDK's own words — "our SDK will crash if using
    // it in production". A crash on launch for every user is not a failure
    // mode this app is allowed to have, and the mistake is an easy one: copy
    // the dev env file, forget one line, ship it.
    //
    // Refused rather than passed through, so the worst case is a prod build
    // that cannot sell anything until the right key is in place. Play would
    // reject the submission anyway; better to find out from a log than from
    // review.
    if (isTestKey(publicKey) && FlavorConfig.current.flavor == Flavor.prod) {
      AppLogger.error(
        'Refusing a RevenueCat Test Store key in a prod build — purchases '
        'are off. Put the Play-backed public key in env/prod.json.',
      );
      return false;
    }

    try {
      // Verbose only where a developer is watching. The SDK logs the app user
      // id and product ids at debug level, which is noise in a release build
      // and needless detail in a bug report.
      await rc.Purchases.setLogLevel(
        FlavorConfig.current.flavor == Flavor.prod
            ? rc.LogLevel.warn
            : rc.LogLevel.debug,
      );

      final config = rc.PurchasesConfiguration(publicKey);
      // Null means RevenueCat generates its own anonymous id. That is the
      // right default: purchases still restore through the Play account, and
      // an id is only attached later if the user signs in.
      if (appUserId != null && appUserId.isNotEmpty) {
        config.appUserID = appUserId;
      }

      await rc.Purchases.configure(config);
      _ready = true;
      AppLogger.info('Purchases ready');
      return true;
    } on Object catch (e, s) {
      AppLogger.error('Purchases unavailable, continuing', e, s);
      CrashReporter.record(e, s);
      _ready = false;
      return false;
    }
  }

  @override
  Future<EntitlementSnapshot?> refresh() =>
      _customerInfo(rc.Purchases.getCustomerInfo, 'refresh');

  @override
  Future<EntitlementSnapshot?> restore() =>
      _customerInfo(rc.Purchases.restorePurchases, 'restore');

  Future<EntitlementSnapshot?> _customerInfo(
    Future<rc.CustomerInfo> Function() call,
    String what,
  ) async {
    if (!_ready) return null;
    try {
      return snapshotOf(await call(), _clock());
    } on Object catch (e, s) {
      // Offline is the ordinary case here, not a fault worth reporting.
      AppLogger.warn('Could not $what entitlements', e, s);
      return null;
    }
  }

  @override
  Future<PurchaseAttempt> buy(PurchaseProduct product) async {
    if (!_ready) return const PurchaseAttempt(PurchaseOutcome.unavailable);

    try {
      final storeProduct = await _storeProduct(product);
      if (storeProduct == null) {
        AppLogger.warn('Product not offered by the store: ${product.id}');
        return const PurchaseAttempt(PurchaseOutcome.unavailable);
      }

      final result = await rc.Purchases.purchase(
        rc.PurchaseParams.storeProduct(storeProduct),
      );
      return PurchaseAttempt(
        PurchaseOutcome.purchased,
        entitlements: snapshotOf(result.customerInfo, _clock()),
      );
    } on PlatformException catch (e, s) {
      final outcome = outcomeFor(rc.PurchasesErrorHelper.getErrorCode(e));

      // A cancelled purchase is a decision, not a fault. Reporting it would
      // bury the real failures under the most common tap in the flow.
      if (outcome == PurchaseOutcome.cancelled) {
        AppLogger.info('Purchase cancelled: ${product.id}');
      } else {
        AppLogger.warn(
          'Purchase failed (${outcome.name}): ${product.id}',
          e,
          s,
        );
      }
      return PurchaseAttempt(outcome);
    } on Object catch (e, s) {
      AppLogger.error('Purchase failed: ${product.id}', e, s);
      CrashReporter.record(e, s);
      return const PurchaseAttempt(PurchaseOutcome.failed);
    }
  }

  @override
  Future<void> identify(String appUserId) async {
    if (!_ready || appUserId.isEmpty) return;
    try {
      // Merges whatever the anonymous id bought into this account, so signing
      // in after paying does not lose the purchase.
      await rc.Purchases.logIn(appUserId);
    } on Object catch (e, s) {
      AppLogger.warn('Could not attach purchases to the account', e, s);
    }
  }

  @override
  Future<void> forget() async {
    if (!_ready) return;
    try {
      await rc.Purchases.logOut();
    } on Object catch (e) {
      // Signing out of an anonymous id is an error in the SDK and a no-op
      // here: there was no account to leave.
      AppLogger.info('Purchases sign-out skipped: $e');
    }
  }

  @override
  Future<List<StorePrice>> prices() async {
    if (!_ready) return const [];

    // Two calls, because Android will not return a one-time product under the
    // subscription category or the other way round — `getProducts` filters on
    // it, and asking once quietly returns half the ladder.
    final subscriptions = PurchaseProduct.values
        .where((p) => p.isSubscription)
        .toList();
    final oneTime = PurchaseProduct.values
        .where((p) => !p.isSubscription)
        .toList();

    final found = <StorePrice>[
      ...await _fetch(subscriptions, rc.ProductCategory.subscription),
      ...await _fetch(oneTime, rc.ProductCategory.nonSubscription),
    ];

    if (found.length < PurchaseProduct.values.length) {
      final missing = PurchaseProduct.values
          .where((p) => !found.any((s) => s.product == p))
          .map((p) => p.id)
          .join(', ');
      // Almost always a product that is still a draft in Play Console, or a
      // build whose ids do not match it. Worth saying out loud: the symptom is
      // a paywall with a row missing and no error anywhere.
      AppLogger.warn('Store did not offer: $missing');
    }
    return found;
  }

  Future<List<StorePrice>> _fetch(
    List<PurchaseProduct> wanted,
    rc.ProductCategory category,
  ) async {
    if (wanted.isEmpty) return const [];
    try {
      final products = await rc.Purchases.getProducts(
        wanted.map((p) => p.id).toList(),
        productCategory: category,
      );
      return [
        for (final sp in products)
          if (PurchaseProduct.byId(sp.identifier) case final product?)
            StorePrice(
              product: product,
              formatted: sp.priceString,
              currencyCode: sp.currencyCode,
              amount: sp.price,
              freeTrialDays: freeTrialDays(sp.introductoryPrice),
            ),
      ];
    } on Object catch (e, s) {
      AppLogger.warn('Could not load ${category.name} prices', e, s);
      return const [];
    }
  }

  @override
  void listen(void Function(EntitlementSnapshot) onChange) {
    if (!_ready) return;
    // Fires on renewals, cancellations, refunds, and when a pending payment
    // finally settles — the last of which is the only way a cash or wallet
    // purchase ever turns into an entitlement.
    rc.Purchases.addCustomerInfoUpdateListener(
      (info) => onChange(snapshotOf(info, _clock())),
    );
  }

  Future<rc.StoreProduct?> _storeProduct(PurchaseProduct product) async {
    final products = await rc.Purchases.getProducts(
      [product.id],
      productCategory: product.isSubscription
          ? rc.ProductCategory.subscription
          : rc.ProductCategory.nonSubscription,
    );
    for (final sp in products) {
      if (sp.identifier == product.id) return sp;
    }
    // Play returns subscription ids as `product:base_plan` in some
    // configurations, so fall back to a prefix match before giving up.
    for (final sp in products) {
      if (sp.identifier.startsWith('${product.id}:')) return sp;
    }
    return products.isEmpty ? null : products.first;
  }

  /// Turns what RevenueCat says into what this app stores.
  ///
  /// Only `entitlements.active` is read. RevenueCat has already applied the
  /// subscription state, the billing-retry grace period and any refund, so
  /// re-deriving activity from dates here would be second-guessing the one
  /// party that can actually see the receipt.
  static EntitlementSnapshot snapshotOf(rc.CustomerInfo info, DateTime now) {
    final grants = <Entitlement, DateTime?>{};

    for (final active in info.entitlements.active.values) {
      final entitlement = Entitlement.fromIdentifier(active.identifier);
      if (entitlement == null) {
        AppLogger.warn('Unknown entitlement "${active.identifier}", ignoring');
        continue;
      }

      final raw = active.expirationDate;
      if (raw == null) {
        grants[entitlement] = null; // Bought outright.
        continue;
      }

      final expires = DateTime.tryParse(raw)?.toLocal();
      if (expires == null) {
        // A date we cannot read must not become "never expires" — that would
        // hand out a permanent subscription. Treating it as expiring at the
        // end of the offline grace keeps the user served now and lets the next
        // successful refresh replace it with something readable.
        AppLogger.warn('Unreadable expiry "$raw" for ${active.identifier}');
        grants[entitlement] = now.add(EntitlementSnapshot.offlineGrace);
        continue;
      }

      grants[entitlement] = expires;
    }

    return EntitlementSnapshot(grants: grants, refreshedAt: now);
  }

  /// How many days of *free* trial an introductory offer is worth.
  ///
  /// An introductory price is not necessarily a trial — Play also uses it for
  /// a discounted first period, and calling "half price for a month" a free
  /// trial on the paywall would be a false claim about money. Only a price of
  /// zero counts.
  static int freeTrialDays(rc.IntroductoryPrice? intro) {
    if (intro == null || intro.price != 0) return 0;

    final perUnit = switch (intro.periodUnit) {
      rc.PeriodUnit.day => 1,
      rc.PeriodUnit.week => 7,
      rc.PeriodUnit.month => 30,
      rc.PeriodUnit.year => 365,
      rc.PeriodUnit.unknown => 0,
    };

    // cycles matters: Play allows a trial to repeat, and a paywall that says
    // "3 days" when the store gives two lots of three is underselling.
    final days = perUnit * intro.periodNumberOfUnits * intro.cycles;
    return days > 0 ? days : 0;
  }

  /// Whether this is a RevenueCat Test Store key rather than a real one.
  ///
  /// Test Store keys are prefixed `test_`. They simulate the whole purchase
  /// flow without Play, which is the only way to exercise this before the
  /// products exist in Play Console — and the only key that must never reach
  /// a production build.
  static bool isTestKey(String publicKey) => publicKey.startsWith('test_');

  /// Maps the SDK's error codes onto the outcomes the UI has words for.
  static PurchaseOutcome outcomeFor(
    rc.PurchasesErrorCode code,
  ) => switch (code) {
    rc.PurchasesErrorCode.purchaseCancelledError => PurchaseOutcome.cancelled,
    rc.PurchasesErrorCode.paymentPendingError => PurchaseOutcome.pending,
    rc.PurchasesErrorCode.productAlreadyPurchasedError =>
      PurchaseOutcome.alreadyOwned,
    rc.PurchasesErrorCode.receiptAlreadyInUseError =>
      PurchaseOutcome.alreadyOwned,
    rc.PurchasesErrorCode.productNotAvailableForPurchaseError =>
      PurchaseOutcome.unavailable,
    rc.PurchasesErrorCode.purchaseNotAllowedError => PurchaseOutcome.notAllowed,
    rc.PurchasesErrorCode.networkError => PurchaseOutcome.network,
    rc.PurchasesErrorCode.offlineConnectionError => PurchaseOutcome.network,
    rc.PurchasesErrorCode.storeProblemError => PurchaseOutcome.network,
    _ => PurchaseOutcome.failed,
  };
}
