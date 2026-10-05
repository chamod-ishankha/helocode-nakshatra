import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import '../../../core/astro/dasha.dart';
import '../../../core/astro/models.dart';
import '../../../core/config/chart_style.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/ui/nakshatra_star.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../chart/presentation/north_indian_chart.dart';
import '../../chart/presentation/rasi_chart.dart';
import '../data/page_renderer.dart';
import '../domain/report_content.dart';

/// The pages of the PDF report (KAN-37, redrawn in KAN-94).
///
/// Ordinary widgets, drawn by the same engine as the app. That is the whole
/// point — the rāśi chart in the report is literally [RasiChart], so it cannot
/// drift from the one on screen, and its Sinhala and Tamil are shaped by
/// HarfBuzz rather than by a PDF library that does not shape at all.
///
/// A print artefact first: parchment and ink, a gold rule, no gradients and
/// nothing that needs colour to be read. It is printed at home on mono
/// printers and forwarded as a photo of the page, so the running period is
/// marked with a ▶ as well as a shade.
abstract final class ReportPages {
  /// Every page, in order. Length is the page count in the footer.
  static List<Widget Function(int page, int total)> of(ReportContent content) {
    final pages = <Widget Function(int, int)>[
      (p, t) => _Page(
        content: content,
        page: p,
        total: t,
        centred: true,
        child: _Cover(content),
      ),
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
          // The centre of the grid names the chart. Without this the navāṁśa
          // printed "Rāśi chart" in its middle, the same as page two.
          caption: (l) => l.chartVargaNavamsa,
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

    // The sub-periods of the running mahādaśā: the part of the timeline a
    // reader is living in, and the one they ask about. Left out for a report
    // made outside the life the chart covers, where nothing is running.
    if (content.runningDasha case final running?
        when running.children.isNotEmpty) {
      pages.add(
        (p, t) => _Page(
          content: content,
          page: p,
          total: t,
          title: (l) => l.reportSectionAntardasha,
          child: _Antardasha(content: content, running: running),
        ),
      );
    }

    // The mahādaśā table is the only section whose length depends on the
    // chart: a life spans a different number of them depending on where the
    // Moon was, so it is paginated rather than assumed to fit.
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

/// The report's colours. Fixed, not themed: paper does not have a dark mode,
/// and every one of these holds its contrast printed in grey.
abstract final class _Ink {
  static const paper = Color(0xFFFFFDF8);
  static const text = Color(0xFF241C3A);
  static const gold = Color(0xFF8C6521);
  static const rule = Color(0xFFD9CFB8);
  static const muted = Color(0xFF6F6785);

  /// The running row, and the lagna. Light enough that black text on it still
  /// reads on a cheap laser printer, dark enough to survive one.
  static const shade = Color(0xFFF4E9D3);
}

/// The mock is drawn on a 420-point page; the report is A4 at 595. Every size
/// below is the mock's, multiplied by this.
const double _k = 595 / 420;

class _Page extends StatelessWidget {
  const _Page({
    required this.content,
    required this.page,
    required this.total,
    required this.child,
    this.title,
    this.centred = false,
  });

  final ReportContent content;
  final int page;
  final int total;

  /// A column of natural height: no [Spacer], no [Expanded].
  final Widget child;
  final String Function(L10n)? title;

  /// Middle of the page rather than the top: the cover.
  final bool centred;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final footer = TextStyle(fontSize: 10 * _k, color: _Ink.muted);

    // The theme's body style under everything, so each plain TextStyle below
    // keeps the language's face — Noto Sinhala, Noto Tamil — and its
    // fallbacks. Off screen there is no Material to supply one, and without
    // it a Sinhala report came out in whatever the device falls back to.
    return DefaultTextStyle(
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: _Ink.text),
      child: ColoredBox(
        // Painted explicitly. A RepaintBoundary captures anything unpainted as
        // transparent, which a PDF viewer renders as black.
        color: _Ink.paper,
        child: SizedBox.fromSize(
          size: PageRenderer.a4,
          child: Stack(
            children: [
              // The inset rule that frames every page.
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(14 * _k),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: _Ink.rule),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(34 * _k),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (title case final heading?) ...[
                      Text(heading(l), style: _heading(context)),
                      const SizedBox(height: 10 * _k),
                    ],
                    // Shrunk to fit, never cut. Each section is laid out at
                    // full width and natural height; one that comes out taller
                    // than the page — a Tamil table wraps where an English one
                    // does not — is scaled down whole rather than running
                    // under the footer. A printed page has no scroll.
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, box) => FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: centred
                              ? Alignment.center
                              : Alignment.topCenter,
                          child: SizedBox(width: box.maxWidth, child: child),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // On every page, not only the last: a page is printed
                        // and passed around on its own.
                        Expanded(
                          child: Text(l.entertainmentOnly, style: footer),
                        ),
                        Text(l.reportPageOf(page, total), style: footer),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

TextStyle _heading(BuildContext context) =>
    BrandFonts.displayStyle(context, size: 20 * _k, color: _Ink.gold);

class _Cover extends StatelessWidget {
  const _Cover(this.content);

  final ReportContent content;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final profile = content.profile;
    final dates = DateFormat.yMMMMd(content.locale.code);

    Widget star() => SizedBox.square(
      dimension: 11 * _k,
      child: CustomPaint(
        painter: NakshatraStarPainter(progress: 1, color: _Ink.gold),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            star(),
            const SizedBox(width: 8),
            // The brand, deliberately not localised — it is what the app is
            // called in Play and on the receipt.
            Text(
              'Nakshatra',
              style: TextStyle(
                fontFamily: BrandFonts.display,
                fontSize: 12 * _k,
                fontWeight: FontWeight.w600,
                color: _Ink.gold,
              ),
            ),
            const SizedBox(width: 8),
            star(),
          ],
        ),
        const SizedBox(height: 12 * _k),
        Text(
          l.reportTitle,
          textAlign: TextAlign.center,
          style: BrandFonts.displayStyle(
            context,
            size: 30 * _k,
            color: _Ink.text,
          ),
        ),
        const SizedBox(height: 20 * _k),
        Text(
          profile.name,
          textAlign: TextAlign.center,
          style: BrandFonts.displayStyle(
            context,
            size: 22 * _k,
            color: _Ink.text,
          ),
        ),
        const SizedBox(height: 6 * _k),
        Text(
          // The time is omitted rather than shown as sunrise. Printing "06:00"
          // for somebody who said they did not know would turn an assumption
          // into a fact the moment it left the app.
          [
            profile.birthTimeKnown
                ? l.reportBornOn(
                    dates.format(profile.birthDate),
                    _formatTime(context, profile.birthTime),
                  )
                : l.reportBornOnDateOnly(dates.format(profile.birthDate)),
            profile.place.label(content.locale),
          ].join(' · '),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13 * _k, color: _Ink.text),
        ),
        const SizedBox(height: 40 * _k),
        Text(
          l.reportPreparedOn(dates.format(content.generatedAt)),
          style: TextStyle(fontSize: 11 * _k, color: _Ink.muted),
        ),
        if (content.housesApproximate) ...[
          const SizedBox(height: 28),
          _Note(text: l.chartApproximate, warning: true),
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
  const _ChartPage({
    required this.content,
    required this.chart,
    this.caption,
    this.note,
  });

  final ReportContent content;
  final BirthChart chart;
  final String Function(L10n)? caption;
  final String Function(L10n)? note;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The chart the app draws, at the top of the page under its heading,
        // square. Both chart widgets are built for a square and stretch badly
        // out of one.
        AspectRatio(
          aspectRatio: 1,
          child: switch (content.style) {
            ChartStyle.southIndian => RasiChart(
              chart: chart,
              approximateHouses: content.housesApproximate,
              caption: caption?.call(l),
            ),
            ChartStyle.northIndian => NorthIndianChart(
              chart: chart,
              approximateHouses: content.housesApproximate,
            ),
          },
        ),
        if (note case final body?) ...[
          const SizedBox(height: 14 * _k),
          Text(body(l), style: _body),
        ],
        if (content.housesApproximate) ...[
          const SizedBox(height: 14 * _k),
          _Note(text: l.chartApproximate, warning: true),
        ],
      ],
    );
  }
}

const _body = TextStyle(fontSize: 11 * _k, height: 1.6, color: _Ink.text);

class _Positions extends StatelessWidget {
  const _Positions(this.content);

  final ReportContent content;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final locale = content.locale;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Table(
          widths: const [2.2, 2, 1.5, 2.8, 1.1, 1.2],
          header: [
            l.chartColumnGraha,
            l.chartColumnRasi,
            l.chartColumnDegree,
            l.chartColumnNakshatra,
            l.chartColumnPada,
            l.chartColumnHouse,
          ],
          rows: [
            for (final graha in Graha.values)
              if (content.chart.positions[graha] case final position?)
                _Row([
                  // The retrograde mark is part of the name here, the same as
                  // on screen: a report that quietly dropped it would disagree
                  // with the app about the same chart.
                  position.isRetrograde
                      ? '${graha.label(locale)} ${l.chartRetrogradeMark}'
                      : graha.label(locale),
                  position.rasi.label(locale),
                  _degrees(position.degreeInRasi),
                  position.nakshatra.label(locale),
                  '${position.pada}',
                  '${position.house}',
                ]),
          ],
        ),
        const SizedBox(height: 14 * _k),
        if (content.housesApproximate)
          _Note(text: l.chartApproximate, warning: true),
      ],
    );
  }

  static String _degrees(double value) {
    final degrees = value.floor();
    final minutes = ((value - degrees) * 60).floor();
    return "$degrees° ${minutes.toString().padLeft(2, '0')}'";
  }
}

/// The antardaśā of the running mahādaśā, the running one marked.
class _Antardasha extends StatelessWidget {
  const _Antardasha({required this.content, required this.running});

  final ReportContent content;
  final DashaPeriod running;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final dates = DateFormat.yMMM(content.locale.code);
    final now = content.generatedAt;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${running.lord.label(content.locale)} · '
          '${dates.format(running.start.toLocal())} — '
          '${dates.format(running.end.toLocal())}',
          style: TextStyle(fontSize: 12 * _k, color: _Ink.muted),
        ),
        const SizedBox(height: 6 * _k),
        _Table(
          widths: const [3, 2, 2],
          header: [
            l.reportColumnSubPeriod,
            l.reportColumnFrom,
            l.reportColumnTo,
          ],
          rows: [
            for (final sub in running.children)
              _Row([
                sub.lord.label(content.locale),
                dates.format(sub.start.toLocal()),
                dates.format(sub.end.toLocal()),
              ], running: sub.contains(now)),
          ],
        ),
        const SizedBox(height: 14 * _k),
        Text(l.reportDashaDatesNote, style: _body),
        const SizedBox(height: 14 * _k),
        if (content.housesApproximate)
          _Note(text: l.chartApproximate, warning: true),
      ],
    );
  }
}

class _Dasha extends StatelessWidget {
  const _Dasha({required this.content, required this.from});

  final ReportContent content;
  final int from;

  /// Sized so a page never overflows. Vimśottarī runs 120 years, so a chart
  /// has ten mahādaśā at most and this is one page in practice — the split
  /// exists so that stays true rather than being assumed.
  static const int rowsPerPage = 14;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final dates = DateFormat.yMMM(content.locale.code);
    final now = content.generatedAt;
    final slice = content.dasha.skip(from).take(rowsPerPage).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Table(
          widths: const [3, 2, 2],
          header: [l.reportColumnLord, l.reportColumnFrom, l.reportColumnTo],
          rows: [
            for (final period in slice)
              _Row([
                period.lord.label(content.locale),
                dates.format(period.start.toLocal()),
                dates.format(period.end.toLocal()),
              ], running: period.contains(now)),
          ],
        ),
        if (content.housesApproximate) ...[
          const SizedBox(height: 14 * _k),
          _Note(text: l.dashaBalanceNote, warning: true),
        ],
      ],
    );
  }
}

/// How the report was worked out. A page of its own: under the positions or
/// the mahādaśā table it ran off the page in Tamil, and a printed report has
/// no scroll.
class _Method extends StatelessWidget {
  const _Method(this.content);

  final ReportContent content;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.reportMethodBody, style: _body),
        const SizedBox(height: 6 * _k),
        Text(
          l.chartAyanamsa(content.chart.ayanamsa.toStringAsFixed(4)),
          style: _body.copyWith(color: _Ink.muted),
        ),
        const SizedBox(height: 14 * _k),
        Text(
          l.reportRegenerateNote,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10 * _k, color: _Ink.muted),
        ),
      ],
    );
  }
}

class _Row {
  const _Row(this.cells, {this.running = false});

  final List<String> cells;

  /// Shaded, bold and marked ▶: the period the reader is in. The mark is what
  /// survives a grey print; the shade is what finds it at a glance.
  final bool running;
}

/// A ruled table: gold header, hairlines between rows.
class _Table extends StatelessWidget {
  const _Table({
    required this.widths,
    required this.header,
    required this.rows,
  });

  final List<double> widths;
  final List<String> header;
  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    const rule = BorderSide(color: _Ink.rule, width: 0.75);
    final head = TextStyle(
      fontSize: 12 * _k,
      fontWeight: FontWeight.w600,
      color: _Ink.gold,
    );
    TextStyle cell(bool running) => TextStyle(
      fontSize: 12 * _k,
      fontWeight: running ? FontWeight.w700 : FontWeight.w400,
      color: _Ink.text,
    );

    Widget pad(Widget child) => Padding(
      // Tighter than the mock's 7: a Tamil row wraps to two lines where the
      // English one does not, and the mock's spacing ran the positions page
      // and its method paragraph off the bottom.
      padding: const EdgeInsets.symmetric(vertical: 5 * _k, horizontal: 4),
      child: child,
    );

    return Table(
      columnWidths: {
        for (final (i, w) in widths.indexed) i: FlexColumnWidth(w),
      },
      border: const TableBorder(bottom: rule, horizontalInside: rule),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          children: [
            for (final h in header)
              // Scaled down rather than broken: "Pada" came out as "Pad / a"
              // in a column sized for one digit.
              pad(
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(h, maxLines: 1, style: head),
                ),
              ),
          ],
        ),
        for (final row in rows)
          TableRow(
            decoration: row.running
                ? const BoxDecoration(color: _Ink.shade)
                : null,
            children: [
              for (final (i, text) in row.cells.indexed)
                pad(
                  i == 0 && row.running
                      ? Row(
                          children: [
                            // An icon rather than "▶": not every face the
                            // report draws in carries the triangle.
                            Icon(
                              Icons.play_arrow_rounded,
                              size: 12 * _k,
                              color: _Ink.text,
                            ),
                            const SizedBox(width: 2),
                            Flexible(child: Text(text, style: cell(true))),
                          ],
                        )
                      : Text(text, style: cell(row.running)),
                ),
            ],
          ),
      ],
    );
  }
}

/// A boxed caveat. Outlined rather than tinted, so it prints; a warning mark
/// when it is one, so it reads without colour.
class _Note extends StatelessWidget {
  const _Note({required this.text, this.warning = false});

  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10 * _k),
    decoration: BoxDecoration(
      border: Border.all(color: _Ink.rule),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (warning) ...[
          Icon(Icons.warning_amber_rounded, size: 14 * _k, color: _Ink.text),
          const SizedBox(width: 8),
        ],
        Expanded(child: Text(text, style: _body)),
      ],
    ),
  );
}
