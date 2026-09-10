import 'entitlements.dart';
import 'products.dart';

/// How an attempt to buy something ended.
///
/// Every one of these needs its own message on screen. Collapsing them into
/// "purchase failed" is how a user who was charged by a slow payment method
/// concludes the app took their money and gave them nothing.
enum PurchaseOutcome {
  /// Paid and entitled. The only case that grants anything.
  purchased,

  /// Play accepted the order but has not taken the money yet.
  ///
  /// Cash at a counter, a wallet, some carrier billing — all common in Sri
  /// Lanka, and all of them return PENDING first and settle minutes to days
  /// later. Nothing is granted now; the entitlement arrives on its own once
  /// Play confirms, which is why the listener in the coordinator matters.
  pending,

  /// The user backed out. Not an error, and must not produce one on screen.
  cancelled,

  /// Play says this account already owns it. Usually a reinstall, so the
  /// answer is to restore rather than to apologise.
  alreadyOwned,

  /// The product is not on sale to this user: wrong country, not yet
  /// published, or a build whose product ids do not exist in Play Console.
  unavailable,

  /// Purchases are blocked on this device — a managed profile, or parental
  /// controls. Retrying will not help.
  notAllowed,

  /// Could not reach the store. Worth another try.
  network,

  /// Anything else.
  failed,
}

/// The result of one purchase attempt, and what the user holds afterwards.
class PurchaseAttempt {
  const PurchaseAttempt(this.outcome, {this.entitlements});

  final PurchaseOutcome outcome;

  /// Fresh entitlements when the store returned some, otherwise null. Null
  /// does **not** mean "holds nothing" — it means we did not learn anything,
  /// and the cached snapshot must be left alone.
  final EntitlementSnapshot? entitlements;

  bool get isSuccess => outcome == PurchaseOutcome.purchased;
}

/// The store, behind an interface.
///
/// ## Why not call the SDK directly
///
/// `purchases_flutter` is a method channel, so every call throws
/// `MissingPluginException` under `flutter test`. Behind this interface the
/// entitlement rules, the cache, the ladder and the feature gates are all
/// testable on the host; only the thin adapter needs a device. That is the
/// same split the ad gate and the notification planner already use, and it is
/// the only reason any of this money-handling logic can be checked at all.
abstract interface class PurchaseGateway {
  /// Whether purchases can actually happen in this build.
  bool get isReady;

  /// Starts the SDK. Returns false when it could not, which is a normal state
  /// — a fresh clone has no RevenueCat key — and never an exception.
  Future<bool> configure({required String publicKey, String? appUserId});

  /// Asks the store what the user holds now. Null when it could not be asked.
  Future<EntitlementSnapshot?> refresh();

  /// Re-reads purchases from the store account. Null when it failed.
  ///
  /// Play already restores non-consumables to the same Play account
  /// automatically, so this is mainly for the case where that has not
  /// happened yet — and for the user who needs a button to press because the
  /// app is showing ads they paid to remove.
  Future<EntitlementSnapshot?> restore();

  Future<PurchaseAttempt> buy(PurchaseProduct product);

  /// Attaches purchases to a signed-in account, so they follow the user to a
  /// new phone rather than only to a new install on the same Play account.
  Future<void> identify(String appUserId);

  /// Detaches, on sign-out. Purchases stay with the account they were made on.
  Future<void> forget();

  /// Store-formatted prices, in the user's currency. Empty when unavailable.
  Future<List<StorePrice>> prices();

  /// Called whenever the store changes its mind: a renewal, a cancellation,
  /// or a pending payment finally settling.
  void listen(void Function(EntitlementSnapshot) onChange);
}

/// A gateway for builds that cannot sell anything.
///
/// Used when there is no RevenueCat key, and in every test that is not about
/// purchasing. It refuses honestly — [PurchaseOutcome.unavailable] rather than
/// a thrown error — so a fresh clone runs as a complete free app instead of
/// crashing on the first paywall.
class DisabledPurchaseGateway implements PurchaseGateway {
  const DisabledPurchaseGateway();

  @override
  bool get isReady => false;

  @override
  Future<bool> configure({
    required String publicKey,
    String? appUserId,
  }) async => false;

  @override
  Future<EntitlementSnapshot?> refresh() async => null;

  @override
  Future<EntitlementSnapshot?> restore() async => null;

  @override
  Future<PurchaseAttempt> buy(PurchaseProduct product) async =>
      const PurchaseAttempt(PurchaseOutcome.unavailable);

  @override
  Future<void> identify(String appUserId) async {}

  @override
  Future<void> forget() async {}

  @override
  Future<List<StorePrice>> prices() async => const [];

  @override
  void listen(void Function(EntitlementSnapshot) onChange) {}
}
