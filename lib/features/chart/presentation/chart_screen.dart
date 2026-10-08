import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/ui/brand_card.dart';
import '../../../core/ui/pill_segments.dart';
import '../../../core/ui/round_icon_button.dart';
import '../../../core/theme/semantic_colors.dart';
import '../../../core/ui/info_notice.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'chart_sharing.dart';
import 'dasha_timeline.dart';
import 'detail_sheets.dart';

import 'dart:async';

import '../../../core/ads/locked_content.dart';
import '../../../core/ads/rewarded_interstitial.dart';
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
import '../../../core/purchases/nudges.dart';
import '../../purchases/presentation/pro_nudge.dart';
import '../../../core/ui/state_views.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/ui/disclaimer.dart';

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

  @override
  void initState() {
    super.initState();

    // After the first frame rather than during it: showing a full-screen ad
    // from initState fires before the chart has painted, so the user is left
    // looking at an ad over a blank screen with no idea what they opened.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(_offerReward()),
    );
  }

  /// The rewarded interstitial, and paying out if it was watched (KAN-55).
  ///
  /// Everything about whether it may appear at all lives in
  /// [RewardedInterstitialController]; this only pays out and says so. The
  /// snackbar is not decoration: an unexplained ad is an interruption, and an
  /// ad that visibly unlocked two things on the screen behind it is a trade.
  Future<void> _offerReward() async {
    final earned = await ref
        .read(rewardedInterstitialControllerProvider)
        .showIfAllowed(ref.read(unlockStoreProvider));
    if (!earned || !mounted) return;

    await ref
        .read(unlockRevisionProvider.notifier)
        .grant(RewardedInterstitialController.reward);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(L10n.of(context).adRewardUnlocked)));
  }

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
        // Only when it is not the rāśi chart, so the default caption stays
        // the one word people expect on the chart they came for.
        caption: _varga == _Varga.rasi ? null : _varga.label(L10n.of(context)),
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
      background: BrandPalette.of(context).background,
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
    final palette = BrandPalette.of(context);
    final l = L10n.of(context);

    if (profile == null || result == null) {
      return Scaffold(
        backgroundColor: palette.background,
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: palette.backdrop),
          child: const SafeArea(bottom: false, child: PageSkeleton()),
        ),
      );
    }

    final locale = AppLocale.of(context);
    final caption = l.chartShareCaption(
      profile.name,
      DateFormat.yMMMd().format(profile.birthDate),
      profile.place.label(locale),
    );
    // Date, time and place under the name, so the person can check at a
    // glance that the chart is cast for what they entered. No time when it
    // was not known: a printed 6:00 AM would read as a fact.
    final details = [
      DateFormat.yMMMd().format(profile.birthDate),
      if (profile.birthTimeKnown)
        DateFormat('h:mm a').format(DateTime(2000).add(profile.birthTime)),
      profile.place.label(locale),
    ].join(' · ');

    return Scaffold(
      backgroundColor: palette.background,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: palette.backdrop),
        child: SafeArea(
          bottom: false,
          child: result.when(
            failure: (f) => _ChartError(failure: f),
            success: (chart) => ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
              children: [
                _Header(
                  name: profile.name.isEmpty ? l.chartTitle : profile.name,
                  details: details,
                  onShare: () => _share(caption),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (!profile.birthTimeKnown) ...[
                  InfoNotice(
                    text: l.chartApproximate,
                    icon: Icons.info_outline,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                PillSegments<ChartStyle>(
                  segments: [
                    for (final s in ChartStyle.values)
                      (value: s, label: s.label(l)),
                  ],
                  selected: style,
                  onChanged: (s) =>
                      ref.read(chartStyleProvider.notifier).set(s),
                ),
                const SizedBox(height: AppSpacing.sm),
                // Its own row rather than four segments beside the style: the
                // two choices are independent — a North Indian D9 is a normal
                // thing to want — and one control would imply alternatives.
                PillSegments<_Varga>(
                  segments: [
                    for (final v in _Varga.values)
                      (value: v, label: v.label(l)),
                  ],
                  selected: _varga,
                  onChanged: (v) => setState(() => _varga = v),
                ),
                // Above the chart, not on it: the lock underneath works
                // exactly as it would without this (KAN-75). Almost always
                // renders nothing.
                const ProNudge(
                  key: ValueKey('chart-nudge'),
                  triggers: [NudgeTrigger.navamsa, NudgeTrigger.adWatches],
                ),
                const SizedBox(height: AppSpacing.md),
                ShareableChart(
                  boundaryKey: _shareBoundary,
                  caption: caption,
                  child: switch (_varga) {
                    _Varga.rasi => _drawn(chart, style, profile.birthTimeKnown),
                    // Inside the share boundary on purpose: a screenshot of a
                    // chart the user has not opened yet should be as blurred
                    // as the screen is.
                    _Varga.navamsa => LockedContent(
                      unlock: RewardedUnlock.navamsaChart,
                      feature: PaidFeature.divisionalCharts,
                      title: l.unlockNavamsaTitle,
                      body: l.unlockNavamsaBody,
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
                  // The D9 magnifies any error in the birth time: one navāṁśa
                  // is 3°20' of the Moon's travel, which is about thirteen
                  // minutes. The rāśi chart survives a rough time; this one
                  // does not.
                  if (!profile.birthTimeKnown) ...[
                    InfoNotice(
                      text: l.chartNavamsaApproximate,
                      tone: NoticeTone.caution,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  QuietNotice(text: l.reportNavamsaNote),
                ],
                const SizedBox(height: AppSpacing.lg),
                _SummaryCard(
                  chart: chart,
                  approximate: !profile.birthTimeKnown,
                ),
                const SizedBox(height: AppSpacing.xl),
                _SectionTitle(l.chartPositions),
                const SizedBox(height: AppSpacing.md),
                _PositionsList(chart: chart),
                const SizedBox(height: AppSpacing.xl),
                RunningDashaLink(onTap: () => context.push(Routes.dasha)),
                const SizedBox(height: AppSpacing.xl),
                // Directly under everything the report will contain, so what
                // is being sold is on screen above the button that sells it.
                ReportTile(chart: chart),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  l.chartAyanamsa(chart.ayanamsa.toStringAsFixed(4)),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: palette.muted),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Disclaimer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The person's name, what the chart is cast for, and the actions.
class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.details,
    required this.onShare,
  });

  final String name;
  final String details;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final palette = BrandPalette.of(context);
    final l = L10n.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: BrandFonts.displayStyle(
                  context,
                  size: 26,
                  color: palette.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                details,
                style: TextStyle(fontSize: 13, color: palette.muted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        RoundIconButton(
          icon: Icons.ios_share_rounded,
          tooltip: l.chartShare,
          onPressed: onShare,
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: Text(
      text,
      style: BrandFonts.displayStyle(
        context,
        size: 20,
        color: BrandPalette.of(context).text,
      ),
    ),
  );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.chart, required this.approximate});
  final BirthChart chart;

  /// Birth time unknown: the lagna is a convention, and says so here as well
  /// as on the chart.
  final bool approximate;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final locale = AppLocale.of(context);
    final moon = chart[Graha.moon];
    return BrandCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Column(
        children: [
          _row(
            context,
            l.chartLagna,
            approximate
                ? '${chart.lagnaRasi.label(locale)} · ${l.chartApproximateShort}'
                : chart.lagnaRasi.label(locale),
            first: true,
          ),
          _row(context, l.chartMoonSign, moon.rasi.label(locale)),
          _row(
            context,
            l.chartBirthNakshatra,
            l.chartNakshatraPada(chart.birthNakshatra.label(locale), moon.pada),
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    bool first = false,
  }) {
    final palette = BrandPalette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: first ? null : Border(top: BorderSide(color: palette.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(label, style: TextStyle(color: palette.muted)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: context.semantic.accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One row per graha, in place of the old horizontally scrolling table.
///
/// The table had six columns, which on a 360 dp phone meant scrolling sideways
/// to see the house, and in Tamil the headers alone were wider than the screen.
/// A row carries the same six facts: name, sign, degree, nakṣatra and pada on
/// the left, house on the right.
class _PositionsList extends StatelessWidget {
  const _PositionsList({required this.chart});
  final BirthChart chart;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final locale = AppLocale.of(context);
    final palette = BrandPalette.of(context);
    final semantic = context.semantic;
    final rows = [for (final g in Graha.values) ?chart.positions[g]];

    return BrandCard(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            DecoratedBox(
              decoration: BoxDecoration(
                border: i == 0
                    ? null
                    : Border(top: BorderSide(color: palette.line)),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                // The same detail as tapping the chart: someone reading the
                // list is already on the row they want.
                onTap: () => showGrahaDetail(context, rows[i]),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: semantic.accentSurface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text(
                              rows[i].graha.shortLabel(locale),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: semantic.accent,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // The name, then "Retrograde" as a word beside
                            // it: in a list there is room to say it rather
                            // than mark it, and the word survives a reader who
                            // cannot tell the red from the text.
                            Text.rich(
                              TextSpan(
                                text: rows[i].graha.label(locale),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: palette.text,
                                ),
                                children: [
                                  if (rows[i].isRetrograde)
                                    TextSpan(
                                      text: '  ${l.detailRetrograde}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: semantic.inauspicious,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              [
                                rows[i].rasi.label(locale),
                                '${rows[i].degreeInRasi.toStringAsFixed(2)}°',
                                '${rows[i].nakshatra.label(locale)} ${rows[i].pada}',
                              ].join(' · '),
                              style: TextStyle(
                                fontSize: 13,
                                color: palette.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l.detailHouse(rows[i].house),
                        style: TextStyle(fontSize: 12, color: palette.muted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChartError extends ConsumerWidget {
  const _ChartError({required this.failure});
  final Failure failure;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context);
    // The engine's own message goes to the log, not the screen: "swe_calc
    // returned -1" tells the reader nothing, and "Nothing was lost" is what
    // they need to hear (KAN-95).
    AppLogger.error('Chart calculation failed: ${failure.message}');

    return StatusView(
      icon: Icons.warning_amber_rounded,
      warning: true,
      title: l.chartCalculationFailed,
      body: l.chartErrorBody,
      action: (
        label: l.stateTryAgain,
        onPressed: () => ref.invalidate(chartProvider),
      ),
      // A wrong place or a date the ephemeris cannot reach is the likeliest
      // cause the reader can do anything about.
      secondary: (
        label: l.chartCheckDetails,
        onPressed: () => context.push(Routes.editProfile),
      ),
    );
  }
}
