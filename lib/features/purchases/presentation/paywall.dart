import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ads/ad_gate.dart';
import '../../../core/ads/rewarded_unlock.dart';
import '../../../core/logging/analytics_service.dart';
import '../../../core/purchases/entitlements.dart';
import '../../../core/purchases/paywall_config.dart';
import '../../../core/purchases/products.dart';
import '../../../core/purchases/purchase_controller.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/ui/brand_card.dart';
import '../../../core/ui/round_icon_button.dart';
import '../../../core/theme/semantic_colors.dart';
import '../../../core/ui/info_notice.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'purchase_messages.dart';

/// One line in the paywall's list of what Pro gives (KAN-71).
///
/// A type rather than a list of strings so the order can be decided, and
/// tested, without a [BuildContext].
enum PaywallBenefit { noAds, charts, dasha, compat, profiles }

/// Why the paywall opened (KAN-36).
///
/// Contextual, not a generic wall. Somebody who just tried to see the daśā
/// timeline is a different prospect from somebody browsing settings, and the
/// sheet should open on the thing they were reaching for.
enum PaywallReason {
  /// Opened deliberately, from Settings.
  general(null),

  compatibilityDetail(RewardedUnlock.compatibilityDetail),

  futureDay(RewardedUnlock.futureDay),

  navamsaChart(RewardedUnlock.navamsaChart),

  dashaDetail(RewardedUnlock.dashaDetail),

  /// The paid PDF report (KAN-37), which no subscription grants.
  birthChartPdf(null, product: PurchaseProduct.birthChartPdf),

  /// Adding a second saved chart (KAN-19). Pro grants this, so the sheet
  /// shows the full ladder rather than a single product.
  multipleProfiles(null);

  const PaywallReason(this.rewarded, {this.product});

  /// The rewarded unlock that opens the same content free, if there is one.
  ///
  /// From KAN-36: the video path stays visible beside the paid one. Somebody
  /// who will never pay still earns money by watching, and hiding that option
  /// to push the purchase loses more than it wins in this market.
  final RewardedUnlock? rewarded;

  /// The one product that opens this, when only one does.
  ///
  /// The sheet then offers that alone and hides the Pro tiers. It has to:
  /// [PaidFeature.birthChartPdf] is satisfied by `birth_chart_pdf` and by
  /// nothing else, so somebody who came here for the report and left having
  /// bought a yearly subscription would still not have it. Showing a tier that
  /// does not unlock what the user is looking at is a mis-sale, whatever it
  /// does for the month's revenue.
  final PurchaseProduct? product;

  /// The paywall that belongs beside a given rewarded unlock.
  static PaywallReason forUnlock(RewardedUnlock unlock) => switch (unlock) {
    RewardedUnlock.compatibilityDetail => PaywallReason.compatibilityDetail,
    RewardedUnlock.futureDay => PaywallReason.futureDay,
    RewardedUnlock.navamsaChart => PaywallReason.navamsaChart,
    RewardedUnlock.dashaDetail => PaywallReason.dashaDetail,
  };

  /// The benefit that matches why the sheet opened, if one does.
  ///
  /// Someone who tapped "Add a family member" should read about family charts
  /// first, not fifth (KAN-74). Future days has no line of its own — it rides
  /// on the rewarded unlock, not on a Pro gate — so it leaves the order alone.
  PaywallBenefit? get leads => switch (this) {
    PaywallReason.navamsaChart => PaywallBenefit.charts,
    PaywallReason.dashaDetail => PaywallBenefit.dasha,
    PaywallReason.compatibilityDetail => PaywallBenefit.compat,
    PaywallReason.multipleProfiles => PaywallBenefit.profiles,
    PaywallReason.general ||
    PaywallReason.futureDay ||
    PaywallReason.birthChartPdf => null,
  };

  /// The benefits in the order this sheet shows them: the one the user came
  /// for first, the rest in their usual order behind it.
  List<PaywallBenefit> get benefitOrder => [
    ?leads,
    for (final b in PaywallBenefit.values)
      if (b != leads) b,
  ];

  String? headline(L10n l) => switch (this) {
    PaywallReason.general => null,
    PaywallReason.compatibilityDetail => l.paywallReasonCompat,
    PaywallReason.futureDay => l.paywallReasonFuture,
    PaywallReason.navamsaChart => l.paywallFeatureCharts,
    PaywallReason.dashaDetail => l.paywallFeatureDasha,
    PaywallReason.birthChartPdf => l.reportGenerate,
    PaywallReason.multipleProfiles => l.paywallFeatureProfiles,
  };
}

/// Opens the paywall, and reports what the user did with it.
///
/// A sheet rather than a route: the content they were reaching for stays
/// visible behind it, dismissing is a swipe, and nothing about the navigation
/// stack changes — which matters because this can open from anywhere.
Future<void> showPaywall(
  BuildContext context,
  WidgetRef ref, {
  PaywallReason reason = PaywallReason.general,
}) async {
  final variant = ref.read(paywallConfigProvider).variant;

  AnalyticsService.log('paywall_impression', {
    'reason': reason.name,
    'variant': variant.name,
  });

  // The whole screen, on the night sky, as the mock draws it (KAN-91): this
  // is the one screen whose job is to be read in full and acted on, and a
  // half-height sheet over the screen behind it read as an interruption. Still
  // a modal sheet underneath, so it dismisses with a swipe and leaves the
  // navigation stack alone.
  final bought = await showModalBottomSheet<bool>(
    context: context,
    // Over the tab bar, not under it (KAN-92).
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(),
    builder: (context) => _PaywallSheet(reason: reason),
  );

  // Distinguished from a purchase, because the dismissal rate is the number
  // that says whether the copy is working.
  if (bought != true) {
    AnalyticsService.log('paywall_dismissed', {'reason': reason.name});
  }
}

class _PaywallSheet extends ConsumerWidget {
  const _PaywallSheet({required this.reason});

  final PaywallReason reason;

  Future<void> _buy(
    BuildContext context,
    WidgetRef ref,
    PurchaseProduct product,
  ) async {
    final l = L10n.of(context);
    AnalyticsService.log('paywall_tier_tapped', {'product': product.id});

    final attempt = await ref.read(entitlementsProvider.notifier).buy(product);

    if (!context.mounted) return;
    // Closed before the message, so the snackbar is not dismissed along with
    // the sheet it was shown on.
    if (attempt.isSuccess) Navigator.of(context).pop(true);
    showPurchaseMessage(context, attempt.outcome.message(l));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context);
    final palette = BrandPalette.of(context);
    final semantic = context.semantic;
    final config = ref.watch(paywallConfigProvider);
    final prices = ref.watch(storePricesProvider);
    final held = ref.watch(entitlementsProvider);
    final now = ref.watch(purchaseClockProvider)();
    final hasPro = held.isActive(Entitlement.pro, now);

    // Fills the screen whatever is on it. With prices unavailable the
    // content is short, and a sheet sized to it stopped halfway with the
    // screen behind still showing; the mock is a whole page in every state.
    return SizedBox.expand(
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: palette.backdrop),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // A visible way out, not only a drag handle and the back button.
                // Play flags purchase sheets whose dismissal is hard to find, and
                // a user who cannot see how to leave is a user who feels trapped
                // (KAN-71).
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: switch (reason.headline(l)) {
                          // Why the sheet opened, as a chip: the thing they were
                          // reaching for, named before anything is sold.
                          final contextual? => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: semantic.accentSurface,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              contextual,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: semantic.accent,
                              ),
                            ),
                          ),
                          null => const SizedBox.shrink(),
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    RoundIconButton(
                      icon: Icons.close,
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).closeButtonTooltip,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  switch (config.variant) {
                    PaywallVariant.value => l.paywallHeadlineValue,
                    PaywallVariant.support => l.paywallHeadlineSupport,
                  },
                  style: BrandFonts.displayStyle(
                    context,
                    size: 30,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  switch (config.variant) {
                    PaywallVariant.value => l.paywallBodyValue,
                    PaywallVariant.support => l.paywallBodySupport,
                  },
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: palette.muted,
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // What they already have, stated before anything is offered. A
                // subscriber who reopens this should read "you have Pro", not a
                // list of reasons to buy the thing they are paying for (KAN-71).
                _Owned(held: held, now: now),

                // The Pro feature list only belongs on a sheet that sells Pro, and
                // not to somebody who already holds it.
                if (reason.product == null && !hasPro) ...[
                  _Features(order: reason.benefitOrder),
                  const SizedBox(height: AppSpacing.lg),
                ],

                prices.when(
                  // Two placeholder plans where the plans will be, as the mock draws it:
                  // the sheet keeps its shape while the store answers, and
                  // nothing in the placeholder looks like a price.
                  loading: () => _LoadingTiers(text: l.paywallPricesLoading),
                  // A store that will not answer must not leave a row that looks
                  // buyable. No price means no button — never a number written
                  // into the app, which would be a price it cannot honour.
                  // Said as a caution, with its icon: a reader should notice it.
                  error: (_, _) => InfoNotice(
                    text: l.paywallPricesUnavailable,
                    tone: NoticeTone.caution,
                  ),
                  data: (list) {
                    final forThisReason = reason.product == null
                        ? list
                        : list.where((p) => p.product == reason.product);

                    // Anything already paid for comes off the sheet. Play refuses
                    // a second purchase of a one-time product anyway — the app
                    // would show "you already own this" after the user had gone
                    // through a payment sheet, which is a worse way to learn it.
                    final offered = forThisReason
                        .where((p) => !p.product.isRedundantFor(held, now))
                        .toList();

                    if (offered.isNotEmpty) {
                      return _Tiers(
                        prices: offered,
                        highlight: config.highlight,
                        onBuy: (p) => _buy(context, ref, p),
                      );
                    }

                    // Nothing left is a different message from nothing available:
                    // one is a happy customer, the other is a store that did not
                    // answer.
                    return forThisReason.isEmpty
                        ? InfoNotice(
                            text: l.paywallPricesUnavailable,
                            tone: NoticeTone.caution,
                          )
                        : InfoNotice(text: l.paywallNothingLeft);
                  },
                ),

                if (reason.rewarded case final unlock?) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _WatchInstead(unlock: unlock),
                ],

                // On the sheet itself, not only in Settings. Somebody who paid on
                // another phone meets the paywall first, and sending them hunting
                // through Settings to prove it is how refund requests start.
                const _RestoreButton(),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l.entertainmentOnly,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: palette.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Features extends StatelessWidget {
  const _Features({required this.order});

  final List<PaywallBenefit> order;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);

    // Every line here is a promise, and each one is kept by a named gate. The
    // list is short because it is only allowed to hold things the app really
    // withholds — it used to carry six, of which four were gated by nothing
    // at all, so buying Pro changed nothing for a user who came for them.
    //
    //   No ads             PaidFeature.removeAds        ad_gate.dart
    //   Navāṁśa (D9)       PaidFeature.divisionalCharts chart_screen.dart
    //   Full daśā          PaidFeature.fullDashaTimeline dasha_timeline.dart
    //   Compatibility      RewardedUnlock.compatibilityDetail — not a
    //                      PaidFeature: the gate is the rewarded unlock, and
    //                      Pro opens it by way of adFreeEntitlementProvider.
    //   Family charts      PaidFeature.multipleProfiles profiles_screen.dart
    //
    // test/core/purchases/gates_test.dart fails if a line is added without
    // one.
    //
    // Each benefit leads with what it does for the reader and names the
    // feature underneath (KAN-71). The feature line is the promise — it is
    // the same string Play shows as the subscription benefit — and the
    // outcome above it is the reason to want it. Neither may claim more than
    // the gate delivers: "understand your deeper chart" is the navāṁśa, not a
    // reading of anyone's future.
    final lines = [
      for (final benefit in order)
        switch (benefit) {
          PaywallBenefit.noAds => (
            Icons.block,
            l.paywallOutcomeNoAds,
            l.paywallFeatureNoAds,
          ),
          PaywallBenefit.charts => (
            Icons.grid_view,
            l.paywallOutcomeCharts,
            l.paywallFeatureCharts,
          ),
          PaywallBenefit.dasha => (
            Icons.timeline,
            l.paywallOutcomeDasha,
            l.paywallFeatureDasha,
          ),
          PaywallBenefit.compat => (
            Icons.favorite_outline,
            l.paywallOutcomeCompat,
            l.paywallFeatureCompat,
          ),
          PaywallBenefit.profiles => (
            Icons.group_outlined,
            l.paywallOutcomeProfiles,
            l.paywallFeatureProfiles,
          ),
        },
    ];
    final palette = BrandPalette.of(context);
    final semantic = context.semantic;

    return BrandCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          for (final (icon, outcome, feature) in lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: semantic.accentSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 19, color: semantic.accent),
                  ),
                  const SizedBox(width: 12),
                  // Sinhala and Tamil run longer than English here, and these
                  // are full sentences rather than labels — they must wrap,
                  // not ellipsize.
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          outcome,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: palette.text,
                          ),
                        ),
                        Text(
                          feature,
                          style: TextStyle(fontSize: 13, color: palette.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Tiers extends StatelessWidget {
  const _Tiers({
    required this.prices,
    required this.highlight,
    required this.onBuy,
  });

  final List<StorePrice> prices;
  final PurchaseProduct highlight;
  final void Function(PurchaseProduct) onBuy;

  StorePrice? _find(PurchaseProduct product) {
    for (final p in prices) {
      if (p.product == product) return p;
    }
    return null;
  }

  /// The Pro tiers in the order the sheet shows them: the highlighted one
  /// first, then the rest.
  ///
  /// Yearly is the highlight by default, so it leads (KAN-71) — the plan most
  /// people are better off on is the one they read first, and the monthly
  /// plan is still one short scroll-free glance below it. Remote Config can
  /// move the highlight; whatever it names goes to the top with it, so the
  /// badge and the position can never disagree.
  static List<PurchaseProduct> tierOrder(PurchaseProduct highlight) => [
    if (PurchaseProduct.proTiers.contains(highlight)) highlight,
    for (final tier in PurchaseProduct.proTiers)
      if (tier != highlight) tier,
  ];

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final monthly = _find(PurchaseProduct.proMonthly);
    final yearly = _find(PurchaseProduct.proYearly);
    final sellsSubscription = prices.any((p) => p.product.isSubscription);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final tier in tierOrder(highlight))
          if (_find(tier) case final price?) ...[
            _TierCard(
              price: price,
              recommended: tier == highlight,
              // Only ever between two subscriptions in the same currency, and
              // null whenever that is not true — a percentage worked out from
              // two countries' prices would be a confident, meaningless
              // number.
              saving: tier == PurchaseProduct.proYearly && monthly != null
                  ? yearly?.savingAgainst(monthly)
                  : null,
              onTap: () => onBuy(tier),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

        // The renewal terms sit directly under the subscription buttons, not
        // at the foot of the sheet below the one-time products and the video
        // offer. Play requires them to be clear before the purchase, and a
        // line the user has to scroll past everything else to find is not
        // that (KAN-71). Only where a subscription is actually offered: on a
        // sheet selling the PDF alone it would describe nothing on screen.
        if (sellsSubscription) ...[
          Text(
            l.paywallLegal,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: BrandPalette.of(context).muted,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // Every one-time product the store offered on this sheet, rather than
        // remove_ads alone. A contextual paywall for the PDF report offers the
        // report and nothing else, and it reaches this loop the same way.
        for (final price in prices)
          if (!price.product.isSubscription) ...[
            const SizedBox(height: AppSpacing.xs),
            OutlinedButton(
              style: paywallOutlineStyle(context),
              onPressed: () => onBuy(price.product),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Text(
                      '${_title(l, price.product)} — ${price.formatted}',
                      textAlign: TextAlign.center,
                    ),
                    if (_body(l, price.product) case final hint?) ...[
                      const SizedBox(height: 2),
                      Text(
                        hint,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: BrandPalette.of(context).muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
      ],
    );
  }

  /// Falls back to the store's own product name rather than to a blank button.
  /// A product that reaches the paywall before it has copy is a mistake, but
  /// an unlabelled button is a worse one.
  static String _title(L10n l, PurchaseProduct product) => switch (product) {
    PurchaseProduct.removeAds => l.paywallRemoveAdsTitle,
    PurchaseProduct.birthChartPdf => l.reportGenerate,
    _ => product.id,
  };

  static String? _body(L10n l, PurchaseProduct product) => switch (product) {
    PurchaseProduct.removeAds => l.paywallRemoveAdsBody,
    PurchaseProduct.birthChartPdf => l.reportGenerateHint,
    _ => null,
  };
}

class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.price,
    required this.recommended,
    required this.saving,
    required this.onTap,
  });

  final StorePrice price;
  final bool recommended;
  final int? saving;
  final VoidCallback onTap;

  String _label(L10n l) => switch (price.product.term) {
    PurchaseTerm.yearly => l.paywallChooseYearly,
    PurchaseTerm.monthly => l.paywallChooseMonthly,
    // Tier cards only ever carry subscriptions; the one-time products are
    // drawn as their own buttons below. Named rather than blank regardless.
    PurchaseTerm.oneTime => l.paywallOneTime,
  };

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);

    final term = switch (price.product.term) {
      PurchaseTerm.monthly => l.paywallPerMonth,
      PurchaseTerm.yearly => l.paywallPerYear,
      PurchaseTerm.oneTime => l.paywallOneTime,
    };

    final palette = BrandPalette.of(context);
    final semantic = context.semantic;

    // Still a Card: the paywall tests measure the tier rows by it, so the
    // squeezed-row check (KAN-60) keeps finding them.
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: recommended ? semantic.accentSurface : palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: recommended ? semantic.accent : palette.line,
          width: recommended ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The plan named first, with its badge; then the store's price
            // and its period. As the mock lays it out.
            Row(
              children: [
                Expanded(
                  child: Text(
                    switch (price.product.term) {
                      PurchaseTerm.yearly => l.paywallTierYearly,
                      PurchaseTerm.monthly => l.paywallTierMonthly,
                      PurchaseTerm.oneTime => l.paywallOneTime,
                    },
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: palette.text,
                    ),
                  ),
                ),
                if (saving != null)
                  _Badge(text: l.paywallSave(saving!))
                else if (recommended)
                  _Badge(text: l.paywallBestValue),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                // The store's own formatted price, in the buyer's currency.
                // Never a number written into the app.
                // The body face, bold, not the display face: Fraunces draws a
                // flat-topped 3 and an open 4, and on the device "LKR 3,900"
                // read as 5,900 and "490" as 190. A price must not be misread.
                Expanded(
                  child: Text(
                    price.formatted,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: recommended ? semantic.accent : palette.text,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  term,
                  style: TextStyle(fontSize: 13, color: palette.muted),
                ),
              ],
            ),
            // Only when the store itself reports one. Nothing here invents a
            // trial.
            if (price.hasFreeTrial)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  l.paywallFreeTrial(price.freeTrialDays, price.formatted),
                  style: TextStyle(fontSize: 13, color: semantic.accent),
                ),
              ),
            const SizedBox(height: AppSpacing.md),

            // A button, not a tappable card (KAN-71). The whole card used to
            // buy on any touch, so a user reaching to read the price could
            // start a purchase flow. Play's own sheet still stands between a
            // tap and a charge, but the control that starts it should be
            // unmistakable — and its label names the billing period, so what
            // is being bought is on the button itself.
            if (recommended)
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD6A537),
                  foregroundColor: const Color(0xFF241A05),
                  minimumSize: const Size.fromHeight(52),
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: onTap,
                child: Text(_label(l), textAlign: TextAlign.center),
              )
            else
              OutlinedButton(
                style: paywallOutlineStyle(context),
                onPressed: onTap,
                child: Text(_label(l), textAlign: TextAlign.center),
              ),
          ],
        ),
      ),
    );
  }
}

/// Two placeholder plan cards and a line saying prices are on their way.
///
/// Not [Card]s: the paywall tests count Cards as real plans, and a placeholder
/// is not one.
class _LoadingTiers extends StatefulWidget {
  const _LoadingTiers({required this.text});

  final String text;

  @override
  State<_LoadingTiers> createState() => _LoadingTiersState();
}

class _LoadingTiersState extends State<_LoadingTiers>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.value = 0.5;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = BrandPalette.of(context);
    Widget block() => FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(_pulse),
      child: Container(
        height: 132,
        decoration: BoxDecoration(
          color: palette.surfaceHigh,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: palette.line),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(child: block()),
        const SizedBox(height: AppSpacing.sm),
        ExcludeSemantics(child: block()),
        const SizedBox(height: AppSpacing.sm),
        Text(
          widget.text,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: palette.muted),
        ),
      ],
    );
  }
}

/// The paywall's quieter buttons: an outline pill on the card colour.
ButtonStyle paywallOutlineStyle(BuildContext context) {
  final palette = BrandPalette.of(context);
  // A solid pill on the card colour, not a hairline: the mock's second plan
  // reads as a real button, and an outline on a dark card nearly vanished.
  return OutlinedButton.styleFrom(
    foregroundColor: palette.text,
    backgroundColor: palette.surfaceHigh,
    minimumSize: const Size.fromHeight(52),
    shape: const StadiumBorder(),
    side: BorderSide(color: palette.line.withValues(alpha: 0.6)),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    // Not black on gold: the light theme's gold is a deep ochre, and black on
    // it was hard to read. Each theme gets the ink its own gold needs.
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.semantic.accent,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: dark ? const Color(0xFF241A05) : Colors.white,
        ),
      ),
    );
  }
}

/// The free path, kept beside the paid one.
class _WatchInstead extends ConsumerWidget {
  const _WatchInstead({required this.unlock});

  final RewardedUnlock unlock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context);

    // A build with no ad unit ids cannot play the video, so offering it would
    // be a button that can never work.
    if (!AdUnits.isConfigured) return const SizedBox.shrink();

    return TextButton(
      onPressed: () async {
        final earned = await ref
            .read(unlockRevisionProvider.notifier)
            .earn(unlock);
        if (earned && context.mounted) Navigator.of(context).pop(false);
      },
      child: Column(
        children: [
          Text(
            l.paywallWatchTitle,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: BrandPalette.of(context).text,
            ),
          ),
          Text(
            l.paywallWatchBody,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: BrandPalette.of(context).muted,
            ),
          ),
        ],
      ),
    );
  }
}

/// What this user already holds, at the top of the sheet (KAN-71).
///
/// Nothing at all for somebody who holds nothing. For anybody else, one line
/// per thing they own, in the words Settings already uses for it — so a
/// subscriber who opens the paywall reads that they have Pro before they read
/// anything offered to them, and never mistakes the sheet for a second bill.
class _Owned extends StatelessWidget {
  const _Owned({required this.held, required this.now});

  final EntitlementSnapshot held;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);

    final isPro = held.isActive(Entitlement.pro, now);
    final proUntil = isPro ? held.grants[Entitlement.pro] : null;
    final adFree = held.has(PaidFeature.removeAds, now);
    final ownsReport = held.has(PaidFeature.birthChartPdf, now);

    final lines = [
      if (isPro)
        proUntil == null
            ? l.purchaseSectionTitle
            : l.purchaseStatusProUntil(proUntil)
      // Pro already removes ads, so saying both would list one fact twice.
      else if (adFree)
        l.purchaseStatusAdFree,
      if (ownsReport) l.purchaseOwnedReport,
    ];
    if (lines.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 18,
                    color: context.semantic.accent,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      line,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: BrandPalette.of(context).text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Restore purchases, reachable from the paywall itself (KAN-71).
///
/// Hidden in a build that cannot sell, for the same reason every purchase
/// control is: a restore button that can never reach a store is a button that
/// looks broken.
class _RestoreButton extends ConsumerStatefulWidget {
  const _RestoreButton();

  @override
  ConsumerState<_RestoreButton> createState() => _RestoreButtonState();
}

class _RestoreButtonState extends ConsumerState<_RestoreButton> {
  bool _restoring = false;

  Future<void> _restore() async {
    final l = L10n.of(context);
    setState(() => _restoring = true);

    final outcome = await ref.read(entitlementsProvider.notifier).restore();

    if (!mounted) return;
    setState(() => _restoring = false);
    // The sheet stays open. Whatever came back is already reflected above it —
    // restored Pro moves to the owned list and its tiers drop away — so the
    // user sees the result where they asked for it rather than on a screen
    // they did not choose to go to.
    showPurchaseMessage(context, outcome.message(l));
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(purchasesAvailableProvider)) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: TextButton(
        onPressed: _restoring ? null : _restore,
        child: Text(
          L10n.of(context).purchaseRestore,
          style: TextStyle(color: BrandPalette.of(context).text),
        ),
      ),
    );
  }
}
