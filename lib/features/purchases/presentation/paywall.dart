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
import '../../../core/theme/semantic_colors.dart';
import '../../../core/ui/info_notice.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'purchase_messages.dart';

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

  final bought = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
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
    final theme = Theme.of(context);
    final config = ref.watch(paywallConfigProvider);
    final prices = ref.watch(storePricesProvider);
    final held = ref.watch(entitlementsProvider);
    final now = ref.watch(purchaseClockProvider)();
    final hasPro = held.isActive(Entitlement.pro, now);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (reason.headline(l) case final contextual?) ...[
                        Text(
                          contextual,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: context.semantic.accent,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                      ],
                      Text(switch (config.variant) {
                        PaywallVariant.value => l.paywallHeadlineValue,
                        PaywallVariant.support => l.paywallHeadlineSupport,
                      }, style: theme.textTheme.headlineSmall),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              switch (config.variant) {
                PaywallVariant.value => l.paywallBodyValue,
                PaywallVariant.support => l.paywallBodySupport,
              },
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
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
              const _Features(),
              const SizedBox(height: AppSpacing.lg),
            ],

            prices.when(
              loading: () => QuietNotice(text: l.paywallPricesLoading),
              // A store that will not answer must not leave a row that looks
              // buyable. No price means no button — never a number written
              // into the app, which would be a price it cannot honour.
              error: (_, _) => QuietNotice(text: l.paywallPricesUnavailable),
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
                return QuietNotice(
                  text: forThisReason.isEmpty
                      ? l.paywallPricesUnavailable
                      : l.paywallNothingLeft,
                );
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
          ],
        ),
      ),
    );
  }
}

class _Features extends StatelessWidget {
  const _Features();

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
      (Icons.block, l.paywallOutcomeNoAds, l.paywallFeatureNoAds),
      (Icons.grid_view, l.paywallOutcomeCharts, l.paywallFeatureCharts),
      (Icons.timeline, l.paywallOutcomeDasha, l.paywallFeatureDasha),
      (Icons.favorite_outline, l.paywallOutcomeCompat, l.paywallFeatureCompat),
      (
        Icons.group_outlined,
        l.paywallOutcomeProfiles,
        l.paywallFeatureProfiles,
      ),
    ];
    final theme = Theme.of(context);

    return Column(
      children: [
        for (final (icon, outcome, feature) in lines)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(icon, size: 18, color: context.semantic.accent),
                ),
                const SizedBox(width: 10),
                // Sinhala and Tamil run longer than English here, and these
                // are full sentences rather than labels — they must wrap, not
                // ellipsize.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(outcome, style: theme.textTheme.titleSmall),
                      Text(
                        feature,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
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
    final theme = Theme.of(context);
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
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
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
              onPressed: () => onBuy(price.product),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    Text('${_title(l, price.product)} — ${price.formatted}'),
                    if (_body(l, price.product) case final hint?) ...[
                      const SizedBox(height: 2),
                      Text(
                        hint,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
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
    final theme = Theme.of(context);

    final term = switch (price.product.term) {
      PurchaseTerm.monthly => l.paywallPerMonth,
      PurchaseTerm.yearly => l.paywallPerYear,
      PurchaseTerm.oneTime => l.paywallOneTime,
    };

    return Card(
      margin: EdgeInsets.zero,
      color: recommended ? context.semantic.accentSurface : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: recommended
              ? context.semantic.accent
              : theme.colorScheme.outlineVariant,
          width: recommended ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              price.formatted,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              term,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Only when the store itself reports one. Nothing here
                      // invents a trial.
                      if (price.hasFreeTrial)
                        Text(
                          l.paywallFreeTrial(
                            price.freeTrialDays,
                            price.formatted,
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: context.semantic.accent,
                          ),
                        ),
                    ],
                  ),
                ),
                if (saving != null)
                  _Badge(text: l.paywallSave(saving!))
                else if (recommended)
                  _Badge(text: l.paywallBestValue),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // A button, not a tappable card (KAN-71). The whole card used to
            // buy on any touch, so a user reaching to read the price could
            // start a purchase flow. Play's own sheet still stands between a
            // tap and a charge, but the control that starts it should be
            // unmistakable — and its label names the billing period, so what
            // is being bought is on the button itself.
            if (recommended)
              FilledButton(onPressed: onTap, child: Text(_label(l)))
            else
              OutlinedButton(onPressed: onTap, child: Text(_label(l))),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: context.semantic.accent,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.labelSmall?.copyWith(color: Colors.black),
    ),
  );
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
          Text(l.paywallWatchTitle),
          Text(
            l.paywallWatchBody,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
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
    final theme = Theme.of(context);

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
                    child: Text(line, style: theme.textTheme.titleSmall),
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
        child: Text(L10n.of(context).purchaseRestore),
      ),
    );
  }
}
