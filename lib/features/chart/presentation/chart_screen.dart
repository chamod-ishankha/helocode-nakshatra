import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/semantic_colors.dart';
import '../../../core/ui/info_notice.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'chart_sharing.dart';
import 'dasha_timeline.dart';
import 'graha_label.dart';
import 'detail_sheets.dart';

import '../../../core/ads/locked_content.dart';
import '../../../core/ads/rewarded_unlock.dart';
import '../../../core/astro/models.dart';
import '../../../core/astro/varga.dart';
import '../../../core/config/app_locale.dart';
import '../../../core/config/chart_style.dart';
import '../../../core/error/result.dart';
import '../../../core/purchases/entitlements.dart';
import '../../../core/router/app_router.dart';
import '../../onboarding/data/profile_repository.dart';
import '../../report/presentation/report_tile.dart';
import '../domain/chart_providers.dart';
import 'north_indian_chart.dart';
import 'rasi_chart.dart';

/// Which chart the screen is drawing (KAN-53).
///
/// Deliberately not persisted, unlike [ChartStyle]. The drawing style is a
/// preference — somebody raised on North Indian charts wants that every time.
/// The varga is a place you navigate to and come back from, and a user who
/// left the app on the D9 last week should not reopen it to a chart they have
/// to pay to read.
enum _Varga {
  rasi,
  navamsa;

  String label(L10n l) => switch (this) {
    _Varga.rasi => l.chartVargaRasi,
    _Varga.navamsa => l.chartVargaNavamsa,
  };
}

class ChartScreen extends ConsumerStatefulWidget {
  const ChartScreen({super.key});

  @override
  ConsumerState<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends ConsumerState<ChartScreen> {
  /// Marks the region that gets rendered to PNG when the user shares.
  final _shareBoundary = GlobalKey();

  _Varga _varga = _Varga.rasi;

  /// One chart, drawn in the user's style.
  ///
  /// Keyed by style *and* varga so Flutter rebuilds rather than trying to
  /// reuse the previous element tree — the two layouts share no structure,
  /// and a D9 is a different chart even when the layout matches.
  Widget _drawn(BirthChart chart, ChartStyle style, bool birthTimeKnown) {
    final key = ValueKey('${style.name}-${_varga.name}');

    return switch (style) {
      ChartStyle.southIndian => RasiChart(
        key: key,
        chart: chart,
        approximateHouses: !birthTimeKnown,
      ),
      ChartStyle.northIndian => NorthIndianChart(
        key: key,
        chart: chart,
        approximateHouses: !birthTimeKnown,
      ),
    };
  }

  Future<void> _share(String caption) async {
    final messenger = ScaffoldMessenger.of(context);
    final failedMessage = L10n.of(context).chartShareFailed;

    final result = await ChartSharing.shareBoundary(
      _shareBoundary,
      fileStem: 'nakshatra-chart',
      text: caption,
    );

    if (!mounted) return;
    if (!result.isSuccess) {
      messenger.showSnackBar(SnackBar(content: Text(failedMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final result = ref.watch(chartProvider);
    final style = ref.watch(chartStyleProvider);
    final theme = Theme.of(context);

    if (profile == null || result == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          profile.name.isEmpty ? L10n.of(context).chartTitle : profile.name,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => popOrHome(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: L10n.of(context).chartShare,
            onPressed: () => _share(
              L10n.of(context).chartShareCaption(
                profile.name,
                DateFormat.yMMMd().format(profile.birthDate),
                profile.place.label(AppLocale.of(context)),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: L10n.of(context).chartStartOver,
            onPressed: () async {
              await ref.read(profileProvider.notifier).clear();
              if (context.mounted) context.go(Routes.onboarding);
            },
          ),
        ],
      ),
      body: result.when(
        failure: (f) => _ChartError(failure: f),
        success: (chart) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!profile.birthTimeKnown) ...[
              InfoNotice(
                text: L10n.of(context).chartApproximate,
                icon: Icons.info_outline,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            _StyleSwitcher(style: style),
            const SizedBox(height: AppSpacing.sm),
            _VargaSwitcher(
              varga: _varga,
              onChanged: (v) => setState(() => _varga = v),
            ),
            const SizedBox(height: AppSpacing.md),
            ShareableChart(
              boundaryKey: _shareBoundary,
              caption: L10n.of(context).chartShareCaption(
                profile.name,
                DateFormat.yMMMd().format(profile.birthDate),
                profile.place.label(AppLocale.of(context)),
              ),
              child: switch (_varga) {
                _Varga.rasi => _drawn(chart, style, profile.birthTimeKnown),
                // Inside the share boundary on purpose: a screenshot of a
                // chart the user has not opened yet should be as blurred as
                // the screen is.
                _Varga.navamsa => LockedContent(
                  unlock: RewardedUnlock.navamsaChart,
                  feature: PaidFeature.divisionalCharts,
                  title: L10n.of(context).unlockNavamsaTitle,
                  body: L10n.of(context).unlockNavamsaBody,
                  child: _drawn(
                    Varga.navamsa(chart),
                    style,
                    profile.birthTimeKnown,
                  ),
                ),
              },
            ),
            if (_varga == _Varga.navamsa) ...[
              const SizedBox(height: AppSpacing.md),
              // The D9 magnifies any error in the birth time: one navāṁśa is
              // 3°20' of the Moon's travel, which is about thirteen minutes.
              // The rāśi chart survives a rough time; this one does not.
              if (!profile.birthTimeKnown) ...[
                InfoNotice(
                  text: L10n.of(context).chartNavamsaApproximate,
                  tone: NoticeTone.caution,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              QuietNotice(text: L10n.of(context).reportNavamsaNote),
            ],
            const SizedBox(height: AppSpacing.xl),
            _SummaryCard(chart: chart),
            const SizedBox(height: AppSpacing.lg),
            Text(
              L10n.of(context).chartPositions,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            _PositionsTable(chart: chart),
            const SizedBox(height: AppSpacing.xl),
            DashaTimeline(birthTimeKnown: profile.birthTimeKnown),
            const SizedBox(height: AppSpacing.xl),
            // Directly under everything the report will contain, so what is
            // being sold is on screen above the button that sells it.
            ReportTile(chart: chart),
            const SizedBox(height: AppSpacing.xl),
            Text(
              L10n.of(context).chartAyanamsa(chart.ayanamsa.toStringAsFixed(4)),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              L10n.of(context).entertainmentOnly,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StyleSwitcher extends ConsumerWidget {
  const _StyleSwitcher({required this.style});

  final ChartStyle style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SegmentedButton<ChartStyle>(
      segments: [
        for (final s in ChartStyle.values)
          ButtonSegment(value: s, label: Text(s.label(L10n.of(context)))),
      ],
      selected: {style},
      showSelectedIcon: false,
      onSelectionChanged: (selection) =>
          ref.read(chartStyleProvider.notifier).set(selection.first),
    );
  }
}

/// Rāśi or navāṁśa.
///
/// Its own row rather than four segments beside the style buttons: the two
/// choices are independent — a North Indian D9 is a normal thing to want — and
/// folding them into one control would imply they are alternatives.
class _VargaSwitcher extends StatelessWidget {
  const _VargaSwitcher({required this.varga, required this.onChanged});

  final _Varga varga;
  final ValueChanged<_Varga> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_Varga>(
      segments: [
        for (final v in _Varga.values)
          ButtonSegment(value: v, label: Text(v.label(L10n.of(context)))),
      ],
      selected: {varga},
      showSelectedIcon: false,
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.chart});
  final BirthChart chart;

  @override
  Widget build(BuildContext context) {
    final moon = chart[Graha.moon];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _row(
              context,
              L10n.of(context).chartLagna,
              chart.lagnaRasi.label(AppLocale.of(context)),
            ),
            _row(
              context,
              L10n.of(context).chartMoonSign,
              moon.rasi.label(AppLocale.of(context)),
            ),
            _row(
              context,
              L10n.of(context).chartBirthNakshatra,
              L10n.of(context).chartNakshatraPada(
                chart.birthNakshatra.label(AppLocale.of(context)),
                moon.pada,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: context.semantic.accent,
          ),
        ),
      ],
    ),
  );
}

class _PositionsTable extends StatelessWidget {
  const _PositionsTable({required this.chart});
  final BirthChart chart;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          // The rows are tappable so a reader can open the detail from the
          // row they are already looking at, but onSelectChanged makes
          // DataTable add a checkbox column, and those checkboxes select
          // nothing — there is no bulk action to perform.
          showCheckboxColumn: false,
          columnSpacing: 18,
          headingRowHeight: 40,
          dataRowMinHeight: 38,
          dataRowMaxHeight: 46,
          columns: [
            DataColumn(label: Text(l.chartColumnGraha)),
            DataColumn(label: Text(l.chartColumnRasi)),
            DataColumn(label: Text(l.chartColumnDegree)),
            DataColumn(label: Text(l.chartColumnNakshatra)),
            DataColumn(label: Text(l.chartColumnPada)),
            DataColumn(label: Text(l.chartColumnHouse)),
          ],
          rows: [
            for (final g in Graha.values)
              if (chart.positions[g] case final p?)
                DataRow(
                  // The same detail as tapping the chart. Someone reading the
                  // table is already looking at the row they want, and
                  // sending them back to a 70 px cell to open it would be
                  // perverse.
                  onSelectChanged: (_) => showGrahaDetail(context, p),
                  cells: [
                    DataCell(GrahaLabel(position: p, abbreviated: false)),
                    DataCell(Text(p.rasi.label(AppLocale.of(context)))),
                    DataCell(Text('${p.degreeInRasi.toStringAsFixed(2)}°')),
                    DataCell(Text(p.nakshatra.label(AppLocale.of(context)))),
                    DataCell(Text('${p.pada}')),
                    DataCell(Text('${p.house}')),
                  ],
                ),
          ],
        ),
      ),
    );
  }
}

class _ChartError extends StatelessWidget {
  const _ChartError({required this.failure});
  final Failure failure;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: AppSpacing.lg),
            Text(
              L10n.of(context).chartCalculationFailed,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              failure.message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
