import 'package:nakshatra/core/purchases/entitlements.dart';
import 'package:nakshatra/core/purchases/products.dart';
import 'package:nakshatra/core/purchases/purchase_gateway.dart';

/// A store that does what the test tells it to.
///
/// `purchases_flutter` is a method channel, so every real call throws
/// `MissingPluginException` under `flutter test`. This is what lets the rules
/// that decide whether somebody has paid be checked without a device, a Play
/// account or a card.
class FakePurchaseGateway implements PurchaseGateway {
  FakePurchaseGateway({this.isReady = true});

  @override
  bool isReady;

  /// What [refresh] and [restore] return. Null means "could not ask", which
  /// is a different thing from "holds nothing" and the distinction most of
  /// these tests turn on.
  EntitlementSnapshot? answer;

  /// What the next [buy] does.
  PurchaseAttempt nextPurchase = const PurchaseAttempt(
    PurchaseOutcome.cancelled,
  );

  List<StorePrice> catalogue = const [];

  final List<PurchaseProduct> bought = [];
  final List<String> identified = [];

  /// Makes [identify] fail, for the bad-connection case (KAN-64).
  bool throwOnIdentify = false;
  int refreshes = 0;
  int restores = 0;
  int forgets = 0;
  void Function(EntitlementSnapshot)? listener;

  @override
  Future<bool> configure({
    required String publicKey,
    String? appUserId,
  }) async => isReady;

  @override
  Future<EntitlementSnapshot?> refresh() async {
    refreshes++;
    return answer;
  }

  @override
  Future<EntitlementSnapshot?> restore() async {
    restores++;
    return answer;
  }

  @override
  Future<PurchaseAttempt> buy(PurchaseProduct product) async {
    bought.add(product);
    return nextPurchase;
  }

  @override
  Future<void> identify(String appUserId) async {
    if (throwOnIdentify) throw StateError('the store could not be reached');
    identified.add(appUserId);
  }

  @override
  Future<void> forget() async => forgets++;

  @override
  Future<List<StorePrice>> prices() async => catalogue;

  @override
  void listen(void Function(EntitlementSnapshot) onChange) =>
      listener = onChange;

  /// Pretends the store changed its mind — a renewal, a cancellation, or a
  /// pending payment finally settling.
  void pushUpdate(EntitlementSnapshot snapshot) => listener?.call(snapshot);
}
