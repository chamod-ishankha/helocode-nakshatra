import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/purchases/entitlements.dart';
import '../../../core/purchases/pro_usage.dart';
import '../../../core/purchases/products.dart';
import '../../../core/purchases/purchase_controller.dart';
import '../../../core/theme/semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/ui/brand_card.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'paywall.dart';
import 'purchase_messages.dart';

/// The purchase rows in Settings (KAN-35).
///
/// What the user holds, a way to get their purchases back, and — while a
/// subscription is running — a link to Google's own subscription management.
/// That last one is not a nicety: Play requires an app selling subscriptions
/// to point at where they can be cancelled.
class ProTiles extends ConsumerStatefulWidget {
  const ProTiles({super.key});

  @override
  ConsumerState<ProTiles> createState() => _ProTilesState();
}

class _ProTilesState extends ConsumerState<ProTiles> {
  bool _restoring = false;

  /// Google's subscription centre. Deliberately not deep-linked to a product:
  /// the generic page works whichever tier is held, and a link built from the
  /// wrong sku lands on an error page.
  static const _manageUrl =
      'https://play.google.com/store/account/subscriptions';

  Future<void> _restore() async {
    setState(() => _restoring = true);
    final l = L10n.of(context);

    final outcome = await ref.read(entitlementsProvider.notifier).restore();

    if (!mounted) return;
    setState(() => _restoring = false);
    showPurchaseMessage(context, outcome.message(l));
  }

  Future<void> _manage() async {
    try {
      await launchUrl(
        Uri.parse(_manageUrl),
        mode: LaunchMode.externalApplication,
      );
    } on Object catch (e, s) {
      AppLogger.warn('Could not open subscription management', e, s);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final entitlements = ref.watch(entitlementsProvider);
    final now = ref.watch(purchaseClockProvider)();

    final proUntil = entitlements.isActive(Entitlement.pro, now)
        ? entitlements.grants[Entitlement.pro]
        : null;
    final isPro = entitlements.isActive(Entitlement.pro, now);
    final adFree = entitlements.has(PaidFeature.removeAds, now);
    final ownsReport = entitlements.has(PaidFeature.birthChartPdf, now);

    // Anything still worth buying. Somebody who owns everything should not be
    // shown a chevron into a sheet with nothing in it.
    final canUpgrade =
        ref.watch(purchasesAvailableProvider) &&
        PurchaseProduct.onSale.any((p) => !p.isRedundantFor(entitlements, now));

    final palette = BrandPalette.of(context);
    final semantic = context.semantic;

    final status = ListTile(
      contentPadding: const EdgeInsets.fromLTRB(16, 6, 12, 6),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: semantic.accent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          adFree ? Icons.workspace_premium : Icons.workspace_premium_outlined,
          color: palette.background,
        ),
      ),
      title: Text(
        switch ((isPro, proUntil, adFree)) {
          // A running subscription is the only case with a date to show;
          // Pro bought outright would have none.
          (true, final DateTime until, _) => l.purchaseStatusProUntil(until),
          (true, _, _) => l.purchaseSectionTitle,
          (_, _, true) => l.purchaseStatusAdFree,
          _ => l.purchaseStatusFree,
        },
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: palette.text,
        ),
      ),
      // The headline can only say one thing, and the report is not part of
      // Pro — so somebody who had bought it was reading "Free". Owned one-time
      // extras get named underneath.
      subtitle: Text(
        ownsReport
            ? l.purchaseOwnedReport
            : (adFree ? l.purchaseStatusAdFree : l.purchaseUpgradeHint),
        style: TextStyle(fontSize: 13, height: 1.45, color: palette.muted),
      ),
      // Tappable only while there is something left to buy, and only in a
      // build that can sell it. A chevron that opens an empty sheet reads as a
      // broken app rather than as a missing key.
      trailing: canUpgrade
          ? Icon(Icons.chevron_right, color: palette.muted)
          : null,
      onTap: canUpgrade ? () => showPaywall(context, ref) : null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The status as the screen's first card, in gold (KAN-90).
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(BrandCard.radius),
            border: Border.all(color: semantic.accent),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              // Composited onto the card colour so both stops share its
              // transparency (see the chart's centre panel).
              colors: [
                Color.alphaBlend(
                  semantic.accent.withValues(alpha: 0.20),
                  palette.surface,
                ),
                Color.alphaBlend(
                  palette.violet.withValues(alpha: 0.10),
                  palette.surface,
                ),
              ],
            ),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              children: [
                status,
                // What the subscription has been used for. Subscribers only —
                // for a lapsed one this goes back to the offer above, and the
                // meter does not linger as a reminder of what they stopped
                // paying for (KAN-77).
                if (isPro) const _ProMeter(),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        BrandCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: ListTileTheme(
            data: ListTileThemeData(
              iconColor: palette.muted,
              textColor: palette.text,
              // From the theme, as in Settings' groups: a bare style would drop
              // the locale's font and fallbacks.
              subtitleTextStyle: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontSize: 13, color: palette.muted),
            ),
            child: Column(
              children: [
                if (proUntil != null) ...[
                  ListTile(
                    leading: const Icon(Icons.open_in_new, size: 20),
                    title: Text(l.purchaseManage),
                    onTap: _manage,
                  ),
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: palette.line,
                  ),
                ],
                ListTile(
                  leading: const Icon(Icons.restore),
                  title: Text(l.purchaseRestore),
                  subtitle: Text(l.purchaseRestoreHint),
                  trailing: _restoring
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  // Disabled while it runs. Two restores at once is not
                  // harmful, but the second finishes first often enough to
                  // show the wrong message.
                  onTap: _restoring ? null : _restore,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// This month's use of Pro, in real numbers (KAN-77).
///
/// Every line is a count that actually went up while Pro was active; a line
/// whose count is zero is left out rather than shown as a zero that reads like
/// a failure. The last line is not a count at all: for an active subscriber it
/// is simply true, and it is the one that lands.
class _ProMeter extends ConsumerWidget {
  const _ProMeter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context);
    final theme = Theme.of(context);
    final usage = ref.watch(proUsageStoreProvider);

    final lines = [
      for (final (u, icon, text) in [
        (ProUsage.chartAdded, Icons.group_outlined, l.proMeterCharts),
        (ProUsage.compatibilityCheck, Icons.favorite_outline, l.proMeterCompat),
        (ProUsage.dashaExplored, Icons.timeline, l.proMeterDasha),
      ])
        if (usage.count(u) case final n when n > 0) (icon, text(n)),
      (Icons.block, l.proMeterNoAds),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(76, 0, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.proMeterTitle,
            style: theme.textTheme.labelLarge?.copyWith(
              color: context.semantic.accent,
            ),
          ),
          const SizedBox(height: 6),
          for (final (icon, text) in lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
