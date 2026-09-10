import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import '../../../core/astro/models.dart';
import '../../../core/config/chart_style.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/semantic_colors.dart';
import '../../../core/ui/info_notice.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../chart/presentation/north_indian_chart.dart';
import '../../chart/presentation/rasi_chart.dart';
import '../data/page_renderer.dart';
import '../domain/report_content.dart';

/// The pages of the PDF report (KAN-37).
///
/// Ordinary widgets, drawn by the same engine as the app. That is the whole
/// point — the rāśi chart in the report is literally [RasiChart], so it cannot
/// drift from the one on screen, and its Sinhala and Tamil are shaped by
/// HarfBuzz rather than by a PDF library that does not shape at all.
abstract final class ReportPages {
  /// Every page, in order. Length is the page count in the footer.
  static List<Widget Function(int page, int total)> of(ReportContent content) {
    final pages = <Widget Function(int, int)>[
      (p, t) =>
          _Page(content: content, page: p, total: t, child: _Cover(content)),
      (p, t) => _Page(
        content: content,
        page: p,
        total: t,
        title: (l) => l.reportSectionRasi,
        child: _ChartPage(content: content, chart: content.chart),
      ),
      (p, t) => _Page(
        content: content,
        page: p,
        total: t,
        title: (l) => l.reportSectionNavamsa,
        child: _ChartPage(
          content: content,
          chart: content.navamsa,
          note: (l) => l.reportNavamsaNote,
        ),
      ),
      (p, t) => _Page(
        content: content,
        page: p,
        total: t,
        title: (l) => l.chartPositions,
        child: _Positions(content),
      ),
    ];

    // The daśā table is the only section whose length depends on the chart:
    // a life spans a different number of mahādaśā depending on where the Moon
    // was, so it is paginated rather than assumed to fit.
    final rows = content.dasha.length;
    for (var start = 0; start < rows; start += _Dasha.rowsPerPage) {
      pages.add(
        (p, t) => _Page(
          content: content,
          page: p,
          total: t,
          title: (l) => l.reportSectionDasha,
          child: _Dasha(content: content, from: start),
        ),
      );
    }

    pages.add(
      (p, t) => _Page(
        content: content,
        page: p,
        total: t,
        title: (l) => l.reportSectionMethod,
        child: _Method(content),
      ),
    );
    return pages;
  }

  /// Builds one page, wrapped in everything it needs to stand alone.
  ///
  /// The wrapper is here rather than in the renderer because it is what makes
  /// `L10n.of(context)` work inside the reused chart widgets. Rendering off
  /// screen means there is no MaterialApp above them, so the localizations and
  /// the theme have to be provided explicitly — miss this and the report comes
  /// out in English whatever the user chose.
  static Widget build(ReportContent content, int index, {ThemeData? theme}) {
    final builders = of(content);
    return Localizations(
      locale: Locale(content.locale.code),
      delegates: L10n.localizationsDelegates,
      child: Theme(
        // Always the light theme. A report is printed and forwarded; a dark
        // one would arrive as a black rectangle in a chat and cost a fortune
        // in toner.
        //
        // [theme] is overridden by the sample exporter and by nothing else.
        // An English report leaves the font family unset, the same as the app,
        // so it draws in whatever face the device uses — which under
        // `flutter test` is a placeholder that renders every Latin letter as a
        // solid box. A sample generated that way is not wrong, but it is
        // useless as evidence, which is exactly what a sample is for.
        data: theme ?? AppTheme.light(content.locale),
        child: Builder(
          builder: (context) => builders[index](index + 1, builders.length),
        ),
      ),
    );
  }

  static int count(ReportContent content) => of(content).length;
}

/// The frame every page shares: margins, header, footer.
class _Page extends StatelessWidget {
  const _Page({
    required this.content,
    required this.page,
    required this.total,
    required this.child,
    this.title,
  });

  final ReportContent content;
  final int page;
  final int total;
  final Widget child;
  final String Function(L10n)? title;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final theme = Theme.of(context);

    return ColoredBox(
      // Painted explicitly. A RepaintBoundary captures anything unpainted as
      // transparent, which a PDF viewer renders as black.
      color: Colors.white,
      child: SizedBox.fromSize(
        size: PageRenderer.a4,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(40, 36, 40, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title case final heading?) ...[
                Text(heading(l), style: theme.textTheme.titleLarge),
                const Divider(height: 20),
              ],
              Expanded(child: child),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    // Brand, deliberately not localised — it is what the app
                    // is called in Play and on the receipt.
                    'Nakshatra · HeloCode Labs',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    l.reportPageOf(page, total),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover(this.content);

  final ReportContent content;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final theme = Theme.of(context);
    final profile = content.profile;
    final dates = DateFormat.yMMMMd(content.locale.code);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.star_border, size: 56, color: context.semantic.accent),
        const SizedBox(height: AppSpacing.lg),
        Text(l.reportTitle, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 28),
        Text(
          profile.name,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: context.semantic.accent,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          // The time is omitted rather than shown as sunrise. Printing "06:00"
          // for somebody who said they did not know would turn an assumption
          // into a fact the moment it left the app.
          profile.birthTimeKnown
              ? l.reportBornOn(
                  dates.format(profile.birthDate),
                  _formatTime(context, profile.birthTime),
                )
              : l.reportBornOnDateOnly(dates.format(profile.birthDate)),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          profile.place.label(content.locale),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 40),
        Text(
          l.reportPreparedOn(dates.format(content.generatedAt)),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (content.housesApproximate) ...[
          const SizedBox(height: 28),
          InfoNotice(text: l.chartApproximate),
        ],
      ],
    );
  }

  static String _formatTime(BuildContext context, Duration time) =>
      MaterialLocalizations.of(context).formatTimeOfDay(
        TimeOfDay(hour: time.inHours, minute: time.inMinutes % 60),
      );
}

class _ChartPage extends StatelessWidget {
  const _ChartPage({required this.content, required this.chart, this.note});

  final ReportContent content;
  final BirthChart chart;
  final String Function(L10n)? note;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Square, and centred in whatever height is left. Both chart widgets
        // are built for a square and stretch badly out of one.
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: switch (content.style) {
                ChartStyle.southIndian => RasiChart(
                  chart: chart,
                  approximateHouses: content.housesApproximate,
                ),
                ChartStyle.northIndian => NorthIndianChart(
                  chart: chart,
                  approximateHouses: content.housesApproximate,
                ),
              },
            ),
          ),
        ),
        if (note case final body?) ...[
          const SizedBox(height: AppSpacing.lg),
          InfoNotice(text: body(l)),
        ],
      ],
    );
  }
}

class _Positions extends StatelessWidget {
  const _Positions(this.content);

  final ReportContent content;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final theme = Theme.of(context);
    final locale = content.locale;

    final header = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w700,
    );
    final cell = theme.textTheme.bodySmall;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Table(
          columnWidths: const {
            0: FlexColumnWidth(2.2),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(1.4),
            3: FlexColumnWidth(2.8),
            4: FlexColumnWidth(1),
            5: FlexColumnWidth(1.1),
          },
          border: TableBorder(
            horizontalInside: BorderSide(
              color: theme.colorScheme.outlineVariant,
              width: 0.5,
            ),
          ),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              children: [
                _cell(l.chartColumnGraha, header),
                _cell(l.chartColumnRasi, header),
                _cell(l.chartColumnDegree, header),
                _cell(l.chartColumnNakshatra, header),
                _cell(l.chartColumnPada, header),
                _cell(l.chartColumnHouse, header),
              ],
            ),
            for (final graha in Graha.values)
              if (chartPosition(graha) case final position?)
                TableRow(
                  children: [
                    _cell(
                      // The retrograde mark is part of the name here, the same
                      // as on screen: a report that quietly dropped it would
                      // disagree with the app about the same chart.
                      position.isRetrograde
                          ? '${graha.label(locale)} ${l.chartRetrogradeMark}'
                          : graha.label(locale),
                      cell,
                    ),
                    _cell(position.rasi.label(locale), cell),
                    _cell(_degrees(position.degreeInRasi), cell),
                    _cell(position.nakshatra.label(locale), cell),
                    _cell('${position.pada}', cell),
                    _cell('${position.house}', cell),
                  ],
                ),
          ],
        ),
        const Spacer(),
        if (content.housesApproximate)
          InfoNotice(text: L10n.of(context).chartApproximate),
      ],
    );
  }

  GrahaPosition? chartPosition(Graha graha) => content.chart.positions[graha];

  static String _degrees(double value) {
    final degrees = value.floor();
    final minutes = ((value - degrees) * 60).floor();
    return "$degrees° ${minutes.toString().padLeft(2, '0')}'";
  }

  static Widget _cell(String text, TextStyle? style) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
    child: Text(text, style: style),
  );
}

class _Dasha extends StatelessWidget {
  const _Dasha({required this.content, required this.from});

  final ReportContent content;
  final int from;

  /// Sized so a page never overflows. Vimśottarī runs 120 years, so a chart
  /// has nine mahādaśā at most and this is one page in practice — the split
  /// exists so that stays true rather than being assumed.
  static const int rowsPerPage = 14;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final theme = Theme.of(context);
    final dates = DateFormat.yMMM(content.locale.code);
    final now = content.generatedAt;

    final slice = content.dasha.skip(from).take(rowsPerPage).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final period in slice)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    period.lord.label(content.locale),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: period.contains(now)
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: period.contains(now)
                          ? context.semantic.accent
                          : null,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    '${dates.format(period.start.toLocal())} — '
                    '${dates.format(period.end.toLocal())}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    period.contains(now) ? l.dashaRunningNow : '',
                    textAlign: TextAlign.end,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: context.semantic.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const Spacer(),
        if (content.housesApproximate) InfoNotice(text: l.dashaBalanceNote),
      ],
    );
  }
}

class _Method extends StatelessWidget {
  const _Method(this.content);

  final ReportContent content;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.reportMethodBody, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l.chartAyanamsa(content.chart.ayanamsa.toStringAsFixed(4)),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          l.entertainmentOnly,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l.reportRegenerateNote,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
