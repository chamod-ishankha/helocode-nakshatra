import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nakshatra/core/astro/models.dart';
import 'package:nakshatra/core/config/app_locale.dart';
import 'package:nakshatra/core/config/chart_style.dart';
import 'package:nakshatra/features/onboarding/domain/birth_profile.dart';
import 'package:nakshatra/features/report/data/page_renderer.dart';
import 'package:nakshatra/features/report/data/report_pdf.dart';
import 'package:nakshatra/features/report/domain/report_content.dart';
import 'package:nakshatra/features/report/presentation/report_pages.dart';

import '../../support/fonts.dart';

/// The paid PDF report (KAN-37).
///
/// The chart itself is built by hand rather than by the ephemeris, which does
/// not load under `flutter test`. That is fine here: this is about the
/// document, not the astronomy — whether every page draws, in every language,
/// and whether what comes out is a PDF with the pages in it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadAppFonts();
    // Sinhala and Tamil month names are not compiled in by default, and the
    // cover formats a birth date. Without this the report silently falls back
    // to English dates in a Sinhala document.
    await initializeDateFormatting();
  });

  const colombo = Place(
    timezone: 'Asia/Colombo',
    en: 'Colombo',
    si: 'කොළඹ',
    ta: 'கொழும்பு',
    latitude: 6.927,
    longitude: 79.861,
    district: 'Colombo',
    districtSi: 'කොළඹ',
    districtTa: 'கொழும்பு',
  );

  /// A plausible chart, close enough in shape for the pages to lay out.
  BirthChart chart() {
    var longitude = 12.0;
    final positions = <Graha, GrahaPosition>{};
    for (final graha in Graha.values) {
      longitude = (longitude + 37.4) % 360;
      positions[graha] = GrahaPosition(
        graha: graha,
        longitude: longitude,
        latitude: 0,
        // Every third one retrograde, so the report's retrograde mark is
        // actually exercised in all three scripts.
        speed: graha.index % 3 == 0 ? -0.4 : 0.9,
        house: (graha.index % 12) + 1,
      );
    }

    return BirthChart(
      julianDayUt: 2451748.5,
      ascendant: 95.3,
      midheaven: 5.1,
      ayanamsa: 23.8654,
      positions: positions,
    );
  }

  BirthProfile profile({bool timeKnown = true, String name = 'Chamod'}) =>
      BirthProfile(
        name: name,
        birthDate: DateTime(2000, 7, 23),
        birthTime: const Duration(hours: 11, minutes: 5),
        birthTimeKnown: timeKnown,
        place: colombo,
      );

  ReportContent content({
    AppLocale locale = AppLocale.en,
    bool timeKnown = true,
    String name = 'Chamod',
    ChartStyle style = ChartStyle.southIndian,
  }) => ReportContent.of(
    profile: profile(timeKnown: timeKnown, name: name),
    chart: chart(),
    locale: locale,
    style: style,
    generatedAt: DateTime(2026, 9, 10),
  );

  group('what goes in the report', () {
    test('the navāṁśa is derived from the same chart', () {
      // Both charts on the same document have to describe one birth. Computing
      // the D9 per page would be wasted work and a chance for two pages to
      // disagree about the same person.
      final report = content();

      expect(report.navamsa.positions.keys, report.chart.positions.keys);
      expect(report.navamsa.ascendant, isNot(report.chart.ascendant));
    });

    test('an unknown birth time is carried through, not papered over', () {
      expect(content(timeKnown: false).housesApproximate, isTrue);
      expect(content().housesApproximate, isFalse);
    });

    test('the filename survives a name in Sinhala', () {
      // Most names here are not Latin, and stripping to ASCII leaves nothing.
      // A file called "--.pdf" in a downloads folder is worse than a generic
      // one with a date on it.
      final sinhala = content(name: 'චමොද්').fileStem;

      expect(sinhala, 'nakshatra-report-20260910');
      expect(content(name: 'Chamod').fileStem, 'nakshatra-Chamod-20260910');
    });

    test('an empty name still produces a usable filename', () {
      expect(content(name: '').fileStem, 'nakshatra-report-20260910');
    });
  });

  group('the pages', () {
    for (final locale in AppLocale.values) {
      testWidgets('every page draws in ${locale.englishName}', (tester) async {
        await tester.runAsync(() async {
          final report = content(locale: locale);
          final total = ReportPages.count(report);

          expect(total, greaterThanOrEqualTo(6));

          for (var i = 0; i < total; i++) {
            final png = await PageRenderer.renderPng(
              ReportPages.build(report, i),
              pixelRatio: 1,
            );

            expect(
              await _inked(png),
              greaterThan(400),
              reason:
                  'page ${i + 1} of the ${locale.englishName} report is blank',
            );
          }
        });
      });
    }

    testWidgets('the report is in the language it was asked for', (
      tester,
    ) async {
      // The trap this guards. Pages render with no MaterialApp above them, so
      // if the Localizations wrapper is ever dropped every page still draws —
      // in English, whatever the user chose, and nothing throws.
      await tester.runAsync(() async {
        final english = await PageRenderer.renderPng(
          ReportPages.build(content(locale: AppLocale.en), 3),
          pixelRatio: 1,
        );
        final sinhala = await PageRenderer.renderPng(
          ReportPages.build(content(locale: AppLocale.si), 3),
          pixelRatio: 1,
        );

        expect(sinhala, isNot(equals(english)));
      });
    });

    testWidgets('the unknown-birth-time notice draws too', (tester) async {
      // Its own case because every other page test uses a known birth time,
      // so the notice path — now the shared InfoNotice — was never rendered.
      // The cover and both chart pages carry it.
      await tester.runAsync(() async {
        final report = content(timeKnown: false);

        for (final page in [0, 1, 2]) {
          final png = await PageRenderer.renderPng(
            ReportPages.build(report, page),
            pixelRatio: 1,
          );
          expect(await _inked(png), greaterThan(400), reason: 'page $page');
        }
      });
    });

    testWidgets('both chart styles draw', (tester) async {
      await tester.runAsync(() async {
        for (final style in ChartStyle.values) {
          final png = await PageRenderer.renderPng(
            ReportPages.build(content(style: style), 1),
            pixelRatio: 1,
          );
          expect(await _inked(png), greaterThan(400), reason: style.name);
        }
      });
    });
  });

  group('the file', () {
    testWidgets('is a PDF with one page per report page', (tester) async {
      await tester.runAsync(() async {
        final report = content();
        final seen = <int>[];

        final bytes = await ReportPdf.build(
          report,
          pixelRatio: 1,
          onProgress: (done, _) => seen.add(done),
        );

        expect(
          String.fromCharCodes(bytes.take(4)),
          '%PDF',
          reason: 'not a PDF at all',
        );

        final pages = ReportPages.count(report);
        expect(
          seen,
          List.generate(pages, (i) => i + 1),
          reason: 'progress must count every page exactly once, in order',
        );
        expect(_countPageObjects(bytes), pages);
      });
    });
  });
}

/// Pixels that were drawn on and are not the white page.
Future<int> _inked(Uint8List png) async {
  final codec = await ui.instantiateImageCodec(png);
  final image = (await codec.getNextFrame()).image;
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();

  var inked = 0;
  for (var i = 0; i < data!.lengthInBytes; i += 4) {
    if (data.getUint8(i + 3) < 255) continue;
    if (data.getUint8(i) < 200 ||
        data.getUint8(i + 1) < 200 ||
        data.getUint8(i + 2) < 200) {
      inked++;
    }
  }
  return inked;
}

/// Counts `/Type /Page` objects, which is how many pages a reader will show.
///
/// Read out of the bytes rather than trusted from the builder: the point is to
/// check what was written to the file, not what we asked for.
int _countPageObjects(Uint8List bytes) {
  final text = String.fromCharCodes(bytes);
  return RegExp(r'/Type\s*/Page[^s]').allMatches(text).length;
}
