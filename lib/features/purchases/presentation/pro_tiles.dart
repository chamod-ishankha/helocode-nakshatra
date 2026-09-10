import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/purchases/entitlements.dart';
import '../../../core/purchases/purchase_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
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

    return Column(
      children: [
        ListTile(
          leading: Icon(
            adFree ? Icons.workspace_premium : Icons.workspace_premium_outlined,
            color: adFree ? AppColors.accent : null,
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
          ),
          subtitle: adFree ? null : Text(l.purchaseUpgradeHint),
        ),

        if (proUntil != null)
          ListTile(
            leading: const Icon(Icons.open_in_new, size: 20),
            title: Text(l.purchaseManage),
            onTap: _manage,
          ),

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
          // Disabled while it runs. Two restores at once is not harmful, but
          // the second finishes first often enough to show the wrong message.
          onTap: _restoring ? null : _restore,
        ),
      ],
    );
  }
}
