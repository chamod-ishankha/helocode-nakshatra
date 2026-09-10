import '../../../core/astro/dasha.dart';
import '../../../core/astro/models.dart';
import '../../../core/astro/varga.dart';
import '../../../core/config/app_locale.dart';
import '../../../core/config/chart_style.dart';
import '../../onboarding/domain/birth_profile.dart';

/// Everything the PDF report shows, gathered once (KAN-37).
///
/// Assembled before any page is drawn, for two reasons. The pages render off
/// screen with no providers above them, so nothing can be fetched from a
/// context; and every page has to describe the *same* chart — computing the
/// navāṁśa separately per page would be wasted work and an opportunity for two
/// pages to disagree.
///
/// ## What is deliberately not here
///
/// No interpretation. Everything in this report is either computed by the
/// ephemeris or copied from what the user entered, and every sentence in it is
/// a definition rather than a reading. Natal interpretation is authored
/// content — it needs an astrologer and three translators, the same as the
/// poya notes in KAN-62 — and inventing it in code would put made-up claims
/// about somebody's life in a document they paid LKR 1,500 for.
class ReportContent {
  ReportContent({
    required this.profile,
    required this.chart,
    required this.dasha,
    required this.locale,
    required this.style,
    required this.generatedAt,
  }) : navamsa = Varga.navamsa(chart);

  factory ReportContent.of({
    required BirthProfile profile,
    required BirthChart chart,
    required AppLocale locale,
    required ChartStyle style,
    DateTime? generatedAt,
  }) => ReportContent(
    profile: profile,
    chart: chart,
    // Mahādaśā only. A report is a fixed number of pages and the sub-periods
    // of a full life run to hundreds of rows; the app is where somebody drills
    // into those.
    dasha: Vimshottari.forChart(chart, depth: 1),
    locale: locale,
    style: style,
    generatedAt: generatedAt ?? DateTime.now(),
  );

  final BirthProfile profile;

  /// The rāśi (D1) chart.
  final BirthChart chart;

  /// The navāṁśa (D9) chart, derived from [chart].
  final BirthChart navamsa;

  final List<DashaPeriod> dasha;

  /// The language the whole document is written in. Chosen at generation time
  /// and fixed in the file — a PDF cannot change language later, so a user who
  /// switches the app afterwards keeps the report they asked for.
  final AppLocale locale;

  final ChartStyle style;

  final DateTime generatedAt;

  /// True when the birth time was unknown, so the lagna and the houses are a
  /// convention rather than a computation. Every page that shows either has to
  /// say so — a printed document outlives the screen that explained it.
  bool get housesApproximate => !profile.birthTimeKnown;

  /// A filename that says whose report it is without leaking anything.
  ///
  /// The name is the user's own and they chose to share the file, but the date
  /// is what makes two reports distinguishable in a downloads folder.
  String get fileStem {
    final safe = profile.name
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final stamp =
        '${generatedAt.year}'
        '${generatedAt.month.toString().padLeft(2, '0')}'
        '${generatedAt.day.toString().padLeft(2, '0')}';

    // Non-Latin names reduce to nothing after that filter, which is most of
    // them here. A generic stem beats a file called "--.pdf".
    return safe.isEmpty ? 'nakshatra-report-$stamp' : 'nakshatra-$safe-$stamp';
  }
}
