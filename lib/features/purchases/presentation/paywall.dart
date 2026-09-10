import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ads/ad_gate.dart';
import '../../../core/ads/rewarded_unlock.dart';
import '../../../core/logging/analytics_service.dart';
import '../../../core/purchases/paywall_config.dart';
import '../../../core/purchases/products.dart';
import '../../../core/purchases/purchase_controller.dart';
import '../../../core/theme/app_theme.dart';
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

  futureDay(RewardedUnlock.futureDay);

  const PaywallReason(this.rewarded);

  /// The rewarded unlock that opens the same content free, if there is one.
  ///
  /// From KAN-36: the video path stays visible beside the paid one. Somebody
  /// who will never pay still earns money by watching, and hiding that option
  /// to push the purchase loses more than it wins in this market.
  final RewardedUnlock? rewarded;

  /// The paywall that belongs beside a given rewarded unlock.
  static PaywallReason forUnlock(RewardedUnlock unlock) => switch (unlock) {
    RewardedUnlock.compatibilityDetail => PaywallReason.compatibilityDetail,
    RewardedUnlock.futureDay => PaywallReason.futureDay,
  };

  String? headline(L10n l) => switch (this) {
    PaywallReason.general => null,
    PaywallReason.compatibilityDetail => l.paywallReasonCompat,
    PaywallReason.futureDay => l.paywallReasonFuture,
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

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (reason.headline(l) case final contextual?) ...[
              Text(
                contextual,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 4),
            ],

            Text(
              switch (config.variant) {
                PaywallVariant.value => l.paywallHeadlineValue,
                PaywallVariant.support => l.paywallHeadlineSupport,
              },
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              switch (config.variant) {
                PaywallVariant.value => l.paywallBodyValue,
                PaywallVariant.support => l.paywallBodySupport,
              },
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 16),
            const _Features(),
            const SizedBox(height: 16),

            prices.when(
              loading: () => _Notice(text: l.paywallPricesLoading),
              // A store that will not answer must not leave a row that looks
              // buyable. No price means no button — never a number written
              // into the app, which would be a price it cannot honour.
              error: (_, _) => _Notice(text: l.paywallPricesUnavailable),
              data: (list) => list.isEmpty
                  ? _Notice(text: l.paywallPricesUnavailable)
                  : _Tiers(
                      prices: list,
                      highlight: config.highlight,
                      onBuy: (p) => _buy(context, ref, p),
                    ),
            ),

            if (reason.rewarded case final unlock?) ...[
              const SizedBox(height: 8),
              _WatchInstead(unlock: unlock),
            ],

            const SizedBox(height: 16),
            Text(
              l.paywallLegal,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
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
    final lines = [
      (Icons.block, l.paywallFeatureNoAds),
      (Icons.grid_view, l.paywallFeatureCharts),
      (Icons.timeline, l.paywallFeatureDasha),
      (Icons.favorite_outline, l.paywallFeatureCompat),
      (Icons.group_outlined, l.paywallFeatureProfiles),
      (Icons.notifications_active_outlined, l.paywallFeatureTransits),
    ];

    return Column(
      children: [
        for (final (icon, text) in lines)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.accent),
                const SizedBox(width: 10),
                // Sinhala and Tamil run longer than English here, and these
                // are full sentences rather than labels — they must wrap, not
                // ellipsize.
                Expanded(child: Text(text)),
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

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final monthly = _find(PurchaseProduct.proMonthly);
    final yearly = _find(PurchaseProduct.proYearly);
    final removeAds = _find(PurchaseProduct.removeAds);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final tier in PurchaseProduct.proTiers)
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
            const SizedBox(height: 8),
          ],

        if (removeAds != null) ...[
          const SizedBox(height: 4),
          OutlinedButton(
            onPressed: () => onBuy(PurchaseProduct.removeAds),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  Text('${l.paywallRemoveAdsTitle} — ${removeAds.formatted}'),
                  const SizedBox(height: 2),
                  Text(
                    l.paywallRemoveAdsBody,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
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
      color: recommended ? AppColors.accent.withValues(alpha: 0.08) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: recommended
              ? AppColors.accent
              : theme.colorScheme.outlineVariant,
          width: recommended ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
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
                          color: AppColors.accent,
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
      color: AppColors.accent,
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

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}
