@Tags(['sample'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nakshatra/core/astro/models.dart';
import 'package:nakshatra/core/config/app_locale.dart';
import 'package:nakshatra/core/config/chart_style.dart';
import 'package:nakshatra/core/theme/app_theme.dart';
import 'package:nakshatra/features/onboarding/domain/birth_profile.dart';
import 'package:nakshatra/features/report/data/report_pdf.dart';
import 'package:nakshatra/features/report/domain/report_content.dart';

import '../../support/fonts.dart';

/// Writes real report PDFs to disk, at the resolution the app ships (KAN-37).
///
/// Not a test — nothing here can fail — and tagged so the ordinary suite skips
/// it. It exists because the acceptance on KAN-37 is that the file opens
/// correctly in Adobe Reader, Google Drive and WhatsApp, and no assertion can
/// stand in for opening it. Run it, then open what it writes:
///
///     flutter test test/features/report/sample_export_test.dart \
///       --tags sample --run-skipped
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Whether a real Latin face was found. See the note in [setUpAll].
  var hasLatin = false;

  setUpAll(() async {
    await loadAppFonts();

    // Loaded here and not in the body, and that ordering is load-bearing.
    // FontLoader tells every live render object that the system fonts
    // changed, which leaves a callback pending on each; tearing down an
    // off-screen render tree while one is outstanding trips an assertion
    // inside RenderObject.dispose. Loading before anything has been rendered
    // leaves nothing to notify.
    hasLatin = await loadLatinFont();

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

  BirthChart chart() {
    var longitude = 12.0;
    final positions = <Graha, GrahaPosition>{};
    for (final graha in Graha.values) {
      longitude = (longitude + 37.4) % 360;
      positions[graha] = GrahaPosition(
        graha: graha,
        longitude: longitude,
        latitude: 0,
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

  testWidgets('write one sample per language', (tester) async {
    await tester.runAsync(() async {
      final out = Directory('build/report-samples')
        ..createSync(recursive: true);

      // Without a real Latin face every letter in the English sample is a
      // solid black box. Not a fault in the report — an English page leaves the
      // font family unset, exactly as the app does, and under `flutter test` an
      // unset family is the placeholder face. On a device it is the phone's own
      // font.
      //
      // It has to be named explicitly: the placeholder claims every glyph, so
      // registering a real face and relying on fallback changes nothing. The
      // first samples were exported without this and went out unreadable.
      if (!hasLatin) {
        // ignore: avoid_print
        print(
          'WARNING no Roboto found in the SDK — the English sample will be '
          'boxes. Do not send it out.',
        );
      }

      for (final locale in AppLocale.values) {
        final base = AppTheme.light(locale);
        final bytes = await ReportPdf.build(
          theme: hasLatin
              ? base.copyWith(
                  textTheme: base.textTheme.apply(
                    // Only where the app itself leaves it unset. Sinhala and
                    // Tamil already name a real bundled face, and overriding
                    // those would make the sample a picture of something the
                    // app never draws.
                    fontFamily: AppTheme.fontFor(locale) ?? testLatinFont,
                    fontFamilyFallback: const [
                      AppTheme.sinhalaFont,
                      AppTheme.tamilFont,
                      testLatinFont,
                    ],
                  ),
                )
              : null,
          ReportContent.of(
            profile: BirthProfile(
              name: switch (locale) {
                AppLocale.si => 'චමොද් ඉශංක',
                AppLocale.ta => 'சாமோத் இஷங்க',
                AppLocale.en => 'Chamod Ishankha',
              },
              birthDate: DateTime(2000, 7, 23),
              birthTime: const Duration(hours: 11, minutes: 5),
              birthTimeKnown: true,
              place: colombo,
            ),
            chart: chart(),
            locale: locale,
            style: ChartStyle.southIndian,
          ),
        );

        final file = File('${out.path}/nakshatra-report-${locale.code}.pdf')
          ..writeAsBytesSync(bytes);
        // ignore: avoid_print
        print('WROTE ${file.path} — ${(bytes.length / 1024).round()} KB');
      }
    });
  });
}
