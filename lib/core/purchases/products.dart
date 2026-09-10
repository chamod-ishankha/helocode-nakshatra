import 'entitlements.dart';

/// How long a purchase lasts, and how it is billed.
enum PurchaseTerm { oneTime, monthly, yearly }

/// The five things that can be bought (KAN-35).
///
/// [id] is the product id in Play Console. RevenueCat is configured to attach
/// each of these to the entitlement in [grants]; this table exists so the app
/// can talk about a product before the store has loaded — to lay out a paywall,
/// to name a purchase in a log — without inventing anything the store will
/// later contradict.
///
/// ## Prices are deliberately absent
///
/// KAN-35 lists intended prices (LKR 750 for remove_ads, LKR 490 and LKR 3,900
/// for the Pro tiers, LKR 1,500 and LKR 990 for the two reports), and none of
/// them belong in code. The store returns a formatted price in the user's own
/// currency, already carrying whatever regional pricing and local tax Play
/// applies. A hardcoded "LKR 750" shown to a user whose account will be
/// charged USD 2.49 is not a cosmetic bug — it is a price the app quoted and
/// did not honour. Until [StorePrice] arrives from the store, a paywall shows
/// that it is loading, never a number.
enum PurchaseProduct {
  removeAds('remove_ads', Entitlement.adFree, PurchaseTerm.oneTime),
  proMonthly('pro_monthly', Entitlement.pro, PurchaseTerm.monthly),
  proYearly('pro_yearly', Entitlement.pro, PurchaseTerm.yearly),
  birthChartPdf('birth_chart_pdf', Entitlement.pdfReport, PurchaseTerm.oneTime),

  /// Not on sale yet — see [sellable].
  compatibilityReport(
    'compatibility_report',
    Entitlement.compatibilityReport,
    PurchaseTerm.oneTime,
    sellable: false,
  );

  const PurchaseProduct(
    this.id,
    this.grants,
    this.term, {
    this.sellable = true,
  });

  /// The Play Console product id.
  final String id;

  /// What owning it entitles the user to.
  final Entitlement grants;

  final PurchaseTerm term;

  /// Whether this may be offered to a user yet.
  ///
  /// `compatibility_report` is false because nothing checks the entitlement it
  /// grants: there is no screen gated on [PaidFeature.compatibilityReport], so
  /// buying it would take money and change nothing. It stays in this table
  /// because the id and the entitlement are already configured in RevenueCat
  /// and Play, and because the day the feature exists this is one word.
  ///
  /// Found by running the sandbox end to end — it appeared on the paywall at
  /// US$3.99, under its raw product id, next to four things that do work.
  final bool sellable;

  bool get isSubscription => term != PurchaseTerm.oneTime;

  /// The products a paywall may show.
  static List<PurchaseProduct> get onSale =>
      values.where((p) => p.sellable).toList(growable: false);

  static PurchaseProduct? byId(String id) {
    for (final p in PurchaseProduct.values) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// The two Pro tiers, cheapest first.
  static const List<PurchaseProduct> proTiers = [proMonthly, proYearly];
}

/// A product as the store priced it, for this user, in their currency.
class StorePrice {
  const StorePrice({
    required this.product,
    required this.formatted,
    required this.currencyCode,
    required this.amount,
    this.freeTrialDays = 0,
  });

  final PurchaseProduct product;

  /// Ready to display — Play has already formatted it for the locale. Never
  /// reformat this; the grouping and the symbol placement differ by country
  /// and Play knows the right answer.
  final String formatted;

  final String currencyCode;

  /// The numeric price, for comparing tiers rather than for display.
  final double amount;

  /// Days of free trial the store will actually give, or 0 for none.
  ///
  /// Read from the store rather than from Remote Config, and that is the whole
  /// point: a trial is configured in Play Console, and a paywall that promises
  /// seven free days because a config value said so — while Play charges on
  /// day one — is an app that lied about money. If the store says nothing, the
  /// paywall says nothing.
  final int freeTrialDays;

  bool get hasFreeTrial => freeTrialDays > 0;

  /// What a year of this costs, so tiers on different terms can be compared.
  ///
  /// Only meaningful between subscriptions. Returns null for a one-time
  /// purchase, because "per year" is not a thing it has.
  double? get annualised => switch (product.term) {
    PurchaseTerm.monthly => amount * 12,
    PurchaseTerm.yearly => amount,
    PurchaseTerm.oneTime => null,
  };

  /// How much cheaper a year of this is than a year of [monthly], as a
  /// percentage, or null when the comparison is meaningless.
  ///
  /// This is the "save 33%" badge on the yearly tier. It is computed from the
  /// store's real numbers rather than written into the copy, so it cannot go
  /// stale when a price changes in Play Console — a stale discount claim is
  /// the kind of thing that gets an app pulled.
  int? savingAgainst(StorePrice monthly) {
    final mine = annualised;
    final theirs = monthly.annualised;
    if (mine == null || theirs == null || theirs <= 0) return null;
    if (currencyCode != monthly.currencyCode) return null;

    final saving = ((theirs - mine) / theirs * 100).round();
    return saving > 0 ? saving : null;
  }
}
