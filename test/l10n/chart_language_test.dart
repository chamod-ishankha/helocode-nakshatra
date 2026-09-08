import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/astro/models.dart';
import 'package:nakshatra/core/config/app_locale.dart';
import 'package:nakshatra/core/config/chart_style.dart';
import 'package:nakshatra/core/theme/app_theme.dart';
import 'package:nakshatra/features/chart/presentation/graha_label.dart';
import 'package:nakshatra/features/chart/presentation/north_indian_chart.dart';
import 'package:nakshatra/features/chart/presentation/rasi_chart.dart';
import 'package:nakshatra/l10n/generated/app_localizations.dart';

import '../support/fonts.dart';

/// The chart drawn in Sinhala or Tamil must contain no English.
///
/// This is the bug KAN-58 was raised for, and it is a bug the person who
/// reports it cannot re-check: the chart holds a dozen short strings pulled
/// from four different places — rāśi names, graha abbreviations, the lagna
/// marker, the retrograde mark, the centre caption — and any one of them can
/// fall back to English without the other eleven noticing. Reading the widget
/// tree is how it stayed broken; rendering it and looking at the characters is
/// how it gets caught.
///
/// The check is on the characters rather than on specific strings on purpose.
/// Asserting `find.text('රාහු')` only proves the string I happened to think of
/// is translated. Asserting that no Latin letter is drawn at all proves there
/// is nothing left to find.
///
/// Deliberately out of scope: nakṣatra, tithi, yoga and karaṇa names, which are
/// English until KAN-52 — none of them are drawn by these two widgets.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadAppFonts);

  /// A Latin letter, which no Sinhala or Tamil chart should be drawing.
  ///
  /// Digits are fine — house numbers and degrees are digits in all three
  /// languages — and so is punctuation.
  final latin = RegExp(r'[A-Za-z]');

  BirthChart fixture() {
    GrahaPosition at(Graha graha, double longitude, {double speed = 1}) =>
        GrahaPosition(
          graha: graha,
          longitude: longitude,
          latitude: 0,
          speed: speed,
          house: (longitude ~/ 30) + 1,
        );

    return BirthChart(
      julianDayUt: 2451748.5,
      // Kanyā rising, so the lagna marker lands in a cell with a graha in it.
      ascendant: 155,
      midheaven: 65,
      ayanamsa: 23.85,
      positions: {
        // Spread across signs so most cells have something to draw, and give
        // the nodes their real retrograde motion so the mark is exercised.
        for (final (i, g) in Graha.values.indexed)
          g: at(
            g,
            (i * 37.0) % 360,
            speed: g == Graha.rahu || g == Graha.ketu ? -0.05 : 1,
          ),
      },
    );
  }

  /// Every graha in a single sign, which puts nine labels in one house.
  BirthChart crowded() {
    return BirthChart(
      julianDayUt: 2451748.5,
      ascendant: 155,
      midheaven: 65,
      ayanamsa: 23.85,
      positions: {
        for (final g in Graha.values)
          g: GrahaPosition(
            graha: g,
            // Kaṭaka, which lands in a corner triangle for this lagna.
            longitude: 100,
            latitude: 0,
            speed: g == Graha.rahu || g == Graha.ketu ? -0.05 : 1,
            house: 4,
          ),
      },
    );
  }

  Future<List<String>> pump(
    WidgetTester tester,
    AppLocale locale,
    ChartStyle style,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(locale.code),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        theme: AppTheme.light(locale),
        home: Scaffold(
          body: switch (style) {
            ChartStyle.southIndian => RasiChart(chart: fixture()),
            ChartStyle.northIndian => NorthIndianChart(chart: fixture()),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Text.rich puts the retrograde mark in a child span, so the widget's own
    // `data` is null for those and only the full plain text has everything.
    return tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  for (final locale in [AppLocale.si, AppLocale.ta]) {
    for (final style in ChartStyle.values) {
      testWidgets('the ${style.name} chart draws no English in '
          '${locale.englishName}', (tester) async {
        final drawn = await pump(tester, locale, style);

        expect(drawn, isNotEmpty, reason: 'the chart drew nothing at all');

        final english = drawn.where((s) => latin.hasMatch(s)).toList();
        expect(
          english,
          isEmpty,
          reason:
              'these are still in English in ${locale.englishName}: $english',
        );
      });
    }
  }

  testWidgets('no house label box reaches outside the chart', (tester) async {
    // Each house's label sits in a box far wider than its region, so that a
    // graha in a narrow corner triangle is not clipped. That box used to be
    // centred on the region's centroid with nothing stopping it, and the
    // corner centroids are close enough to the frame that the box hung over
    // the edge — so a house with several grahas wrote the last of them outside
    // the square. It showed up in Sinhala, whose abbreviations are wider than
    // English's, but the geometry was wrong in every language.
    //
    // Checking the boxes rather than the text is deliberate: which house a
    // graha lands in depends on the lagna, so a fixture that happens to fill a
    // corner today can quietly stop covering one. The boxes are all twelve
    // houses, every time.
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    const key = Key('chart-under-test');
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('si'),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        theme: AppTheme.light(AppLocale.si),
        home: Scaffold(
          body: Center(
            child: NorthIndianChart(key: key, chart: crowded()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final frame = tester.getRect(find.byKey(key));
    final boxes = find.descendant(
      of: find.byKey(key),
      matching: find.byType(GestureDetector),
    );
    expect(boxes, findsNWidgets(12), reason: 'one tappable box per house');

    for (var i = 0; i < 12; i++) {
      final box = tester.getRect(boxes.at(i));
      // Half a logical pixel of slack: the geometry is computed in fractions
      // of the chart's side and lands on non-integer pixels.
      expect(
        frame.inflate(0.5).contains(box.topLeft) &&
            frame.inflate(0.5).contains(box.bottomRight),
        isTrue,
        reason: 'house label box $box reaches outside the chart at $frame',
      );
    }
  });

  for (final locale in AppLocale.values) {
    testWidgets('the retrograde mark stands off the abbreviation in '
        '${locale.englishName}', (tester) async {
      // KAN-57: it used to be `℞` concatenated onto the abbreviation, which
      // read as a rendering fault rather than notation. The mark has to be
      // there — colour alone says nothing to a reader who cannot separate the
      // reds, and nothing at all in a screenshot printed in grey — but it must
      // not join the name.
      //
      // Asserting on the whitespace rather than on a particular space
      // character is the point. It started as a hair space, which is enough
      // between Latin letters and in Sinhala, and closed up in Tamil: ராகு
      // and வ ran together into ராகுவ, which reads as an inflected form of
      // the name. A test pinned to U+200A would have gone on passing.
      final drawn = await pump(tester, locale, ChartStyle.southIndian);

      final l10n = await L10n.delegate.load(Locale(locale.code));
      final rahu = Graha.rahu.shortLabel(locale);
      final mark = l10n.chartRetrogradeMark;

      final label = drawn.firstWhere(
        (s) => s.startsWith(rahu) && s.endsWith(mark) && s != rahu,
        orElse: () => '',
      );
      expect(
        label,
        isNotEmpty,
        reason: 'Rāhu was drawn without a retrograde mark in $drawn',
      );

      final between = label.substring(rahu.length, label.length - mark.length);
      expect(
        between.trim(),
        isEmpty,
        reason: 'expected only spacing between "$rahu" and "$mark"',
      );
      expect(
        between,
        isNotEmpty,
        reason: 'the mark is jammed onto the abbreviation: "$label"',
      );

      expect(
        drawn.every((s) => !s.contains('℞')),
        isTrue,
        reason: 'the ℞ ligature is what made it unreadable',
      );
    });
  }

  testWidgets('the positions table uses the same notation as the chart', (
    tester,
  ) async {
    // The table drew its own bare `℞` long after both charts had stopped. It
    // is a third caller that nobody remembered when KAN-57 was fixed "in both
    // chart styles" — so it now renders through the same widget, and this
    // checks the full-name mode the table needs.
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ta'),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        theme: AppTheme.light(AppLocale.ta),
        home: Scaffold(
          body: GrahaLabel(
            abbreviated: false,
            position: const GrahaPosition(
              graha: Graha.rahu,
              longitude: 100,
              latitude: 0,
              speed: -0.05,
              house: 4,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = await L10n.delegate.load(const Locale('ta'));
    final drawn = tester
        .widget<Text>(find.byType(Text))
        .textSpan!
        .toPlainText();

    expect(drawn, startsWith(Graha.rahu.label(AppLocale.ta)));
    expect(drawn, endsWith(l10n.chartRetrogradeMark));
    expect(drawn, isNot(contains('℞')));
  });

  test('nothing in the app draws the ℞ ligature any more', () {
    // A grep as a test, because the fault was never one bad expression — it
    // was the same expression copied to a third place and left behind. This
    // fails on the copy, wherever someone puts it next.
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        // Comments may name it — graha_label's own documentation explains why
        // it is gone. Only code that draws it is a fault.
        if (lines[i].trimLeft().startsWith('//')) continue;
        if (lines[i].contains('℞')) {
          offenders.add('${entity.path}:${i + 1}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'these still hardcode ℞ instead of going through GrahaLabel: '
          '$offenders',
    );
  });

  testWidgets('the lagna marker is a word, not a transliteration', (
    tester,
  ) async {
    // The tempting fix for "La" in a Sinhala chart is to spell "La" in Sinhala
    // letters, which produces a sound that means nothing to the reader. It has
    // to be the language's own word for the lagna, shortened.
    final si = L10n.delegate.load(const Locale('si'));
    final ta = L10n.delegate.load(const Locale('ta'));

    expect((await si).chartLagnaMark, 'ලග්');
    expect((await ta).chartLagnaMark, 'லக்');
    expect((await si).chartRetrogradeMark, 'ව');
    expect((await ta).chartRetrogradeMark, 'வ');
  });
}
