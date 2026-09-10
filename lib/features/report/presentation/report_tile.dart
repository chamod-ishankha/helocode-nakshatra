import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/astro/models.dart';
import '../../../core/config/app_locale.dart';
import '../../../core/purchases/entitlements.dart';
import '../../../core/purchases/purchase_controller.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/semantic_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../onboarding/data/profile_repository.dart';
import '../../purchases/presentation/paywall.dart';
import '../data/report_pdf.dart';
import '../domain/report_content.dart';

/// The offer, and the progress, for the paid PDF report (KAN-37).
///
/// Sits on the chart screen under everything it will contain, so what is being
/// sold is directly above the button that sells it.
class ReportTile extends ConsumerStatefulWidget {
  const ReportTile({required this.chart, super.key});

  final BirthChart chart;

  @override
  ConsumerState<ReportTile> createState() => _ReportTileState();
}

class _ReportTileState extends ConsumerState<ReportTile> {
  int _done = 0;
  int _total = 0;
  bool _busy = false;

  Future<void> _tap() async {
    // Checked at the moment of the tap rather than only at build. A purchase
    // that settled while this screen was open should work without the user
    // having to go back and come in again.
    if (!ref.read(featureProvider(PaidFeature.birthChartPdf))) {
      await showPaywall(context, ref, reason: PaywallReason.birthChartPdf);
      return;
    }
    await _generate();
  }

  Future<void> _generate() async {
    final l = L10n.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final profile = ref.read(profileProvider);
    if (profile == null) return;

    setState(() {
      _busy = true;
      _done = 0;
      _total = 0;
    });

    final result = await ReportPdf.shareReport(
      ReportContent.of(
        profile: profile,
        chart: widget.chart,
        locale: AppLocale.of(context),
        style: ref.read(chartStyleProvider),
      ),
      shareText: l.reportShareText,
      onProgress: (done, total) {
        if (!mounted) return;
        setState(() {
          _done = done;
          _total = total;
        });
      },
    );

    if (!mounted) return;
    setState(() => _busy = false);
    if (!result.isSuccess) {
      messenger.showSnackBar(SnackBar(content: Text(l.reportFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final theme = Theme.of(context);
    final owned = ref.watch(featureProvider(PaidFeature.birthChartPdf));

    // Nothing to offer in a build with no store, unless the report is already
    // owned — in which case it stays generatable, because a purchase must not
    // stop working when a key goes missing.
    if (!owned && !ref.watch(purchasesAvailableProvider)) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.semantic.accent.withValues(alpha: 0.4)),
      ),
      color: context.semantic.accentSurface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.picture_as_pdf_outlined,
                  color: context.semantic.accent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l.reportGenerate,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              owned ? l.reportRegenerateNote : l.reportGenerateHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: _busy ? null : _tap,
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(owned ? Icons.ios_share : Icons.lock_open),
              // Counted rather than spun. Building six A4 pages takes a few
              // seconds on a cheap phone, and a bare spinner for that long
              // reads as a hang — which is when people kill the app halfway
              // through the thing they just paid for.
              label: Text(
                _busy
                    ? (_total == 0
                          ? l.reportPreparing
                          : l.reportPageOf(_done, _total))
                    : (owned ? l.reportGenerate : l.purchaseUpgrade),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
