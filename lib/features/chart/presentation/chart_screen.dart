import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/generated/app_localizations.dart';
import 'chart_sharing.dart';
import 'dasha_timeline.dart';
import 'detail_sheets.dart';

import '../../../core/astro/ephemeris.dart';
import '../../../core/astro/models.dart';
import '../../../core/config/chart_style.dart';
import '../../../core/error/result.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../onboarding/data/profile_repository.dart';
import 'north_indian_chart.dart';
import 'rasi_chart.dart';

/// The computed chart for the saved profile.
///
/// Recomputes whenever the profile changes. Cheap enough to do synchronously —
/// a full chart is a handful of ephemeris calls — so there is no cache yet;
/// KAN-19 adds persistence when multiple profiles arrive.
final chartProvider = Provider<Result<BirthChart>?>((ref) {
  final profile = ref.watch(profileProvider);
  if (profile == null) return null;

  return Ephemeris.computeChart(
    localWallClock: profile.localWallClock,
    zoneName: profile.place.timezone,
    latitude: profile.place.latitude,
    longitude: profile.place.longitude,
  );
});

class ChartScreen extends ConsumerStatefulWidget {
  const ChartScreen({super.key});

  @override
  ConsumerState<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends ConsumerState<ChartScreen> {
  /// Marks the region that gets rendered to PNG when the user shares.
  final _shareBoundary = GlobalKey();

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
                profile.place.en,
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
            if (!profile.birthTimeKnown) const _ApproximateBanner(),
            _StyleSwitcher(style: style),
            const SizedBox(height: 12),
            // Keyed by style so Flutter rebuilds rather than trying to reuse
            // the previous layout's element tree, which shares no structure.
            ShareableChart(
              boundaryKey: _shareBoundary,
              caption: L10n.of(context).chartShareCaption(
                profile.name,
                DateFormat.yMMMd().format(profile.birthDate),
                profile.place.en,
              ),
              child: switch (style) {
                ChartStyle.southIndian => RasiChart(
                  key: const ValueKey('south'),
                  chart: chart,
                  approximateHouses: !profile.birthTimeKnown,
                ),
                ChartStyle.northIndian => NorthIndianChart(
                  key: const ValueKey('north'),
                  chart: chart,
                  approximateHouses: !profile.birthTimeKnown,
                ),
              },
            ),
            const SizedBox(height: 24),
            _SummaryCard(chart: chart),
            const SizedBox(height: 16),
            Text(
              L10n.of(context).chartPositions,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _PositionsTable(chart: chart),
            const SizedBox(height: 24),
            DashaTimeline(birthTimeKnown: profile.birthTimeKnown),
            const SizedBox(height: 24),
            Text(
              L10n.of(context).chartAyanamsa(chart.ayanamsa.toStringAsFixed(4)),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
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
          ButtonSegment(value: s, label: Text(s.label)),
      ],
      selected: {style},
      showSelectedIcon: false,
      onSelectionChanged: (selection) =>
          ref.read(chartStyleProvider.notifier).set(selection.first),
    );
  }
}

class _ApproximateBanner extends StatelessWidget {
  const _ApproximateBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.10),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              L10n.of(context).chartApproximate,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
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
            _row(context, L10n.of(context).chartLagna, chart.lagnaRasi.en),
            _row(context, L10n.of(context).chartMoonSign, moon.rasi.en),
            _row(
              context,
              L10n.of(context).chartBirthNakshatra,
              '${chart.birthNakshatra.en} — pada ${moon.pada}',
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
            color: AppColors.accent,
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
                    DataCell(
                      Row(
                        children: [
                          Text(p.graha.en),
                          if (p.isRetrograde)
                            Text(
                              ' ℞',
                              style: TextStyle(color: AppColors.inauspicious),
                            ),
                        ],
                      ),
                    ),
                    DataCell(Text(p.rasi.en)),
                    DataCell(Text('${p.degreeInRasi.toStringAsFixed(2)}°')),
                    DataCell(Text(p.nakshatra.en)),
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
            const SizedBox(height: 16),
            Text(
              L10n.of(context).chartCalculationFailed,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
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
