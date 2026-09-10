import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/features/report/data/page_renderer.dart';

import '../../support/fonts.dart';

/// The off-screen render pipeline (KAN-37).
///
/// This is the part of the PDF that can silently produce nothing: a blank
/// page, a page at the wrong size, or a page whose text never arrived. All
/// three ship as a file the customer paid for, and none of them throw.
///
/// Every case runs inside [WidgetTester.runAsync]. The renderer yields to the
/// event loop between passes and `toImage` is real engine work, and a widget
/// test drives a fake clock — outside runAsync the first yield simply never
/// completes and the suite hangs rather than failing. That cost a timeout to
/// find.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadAppFonts);

  Widget page(String text, {Color background = Colors.white}) => ColoredBox(
    color: background,
    child: SizedBox.fromSize(
      size: PageRenderer.a4,
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 40, color: Colors.black),
        ),
      ),
    ),
  );

  /// Decodes the PNG so the pixels can be looked at rather than trusted.
  Future<ui.Image> decode(Uint8List png) async {
    final codec = await ui.instantiateImageCodec(png);
    return (await codec.getNextFrame()).image;
  }

  /// How many pixels are neither the page background nor uncovered.
  ///
  /// Alpha is checked first. A pixel the page never painted comes back fully
  /// transparent, and in premultiplied RGBA that reads as black — which is how
  /// an earlier version of this counted a partly-covered edge column as 842
  /// pixels of ink on a deliberately blank page.
  Future<int> inkedPixels(Uint8List png) async {
    final image = await decode(png);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();

    var inked = 0;
    for (var i = 0; i < data!.lengthInBytes; i += 4) {
      if (data.getUint8(i + 3) < 255) continue;
      final r = data.getUint8(i);
      final g = data.getUint8(i + 1);
      final b = data.getUint8(i + 2);
      if (r < 200 || g < 200 || b < 200) inked++;
    }
    return inked;
  }

  testWidgets('a page comes out at exactly the size asked for', (tester) async {
    await tester.runAsync(() async {
      // One logical pixel is one PostScript point, so the image drops onto an A4
      // page 1:1. If this drifts the whole document is scaled and nobody notices
      // until it is printed.
      final png = await PageRenderer.renderPng(
        page('Nakshatra'),
        pixelRatio: 2,
      );
      final image = await decode(png);

      expect(image.width, (PageRenderer.a4.width * 2).round());
      expect(image.height, (PageRenderer.a4.height * 2).round());
      image.dispose();
    });
  });

  testWidgets('the page is actually drawn, not captured empty', (tester) async {
    await tester.runAsync(() async {
      // The failure mode this pipeline has: everything succeeds, the file is
      // valid, and the page is blank.
      final drawn = await PageRenderer.renderPng(
        page('Nakshatra'),
        pixelRatio: 1,
      );
      final blank = await PageRenderer.renderPng(
        const ColoredBox(color: Colors.white, child: SizedBox.expand()),
        pixelRatio: 1,
      );

      expect(await inkedPixels(blank), 0, reason: 'the control must be empty');
      expect(await inkedPixels(drawn), greaterThan(500));
    });
  });

  testWidgets('Sinhala is shaped, not laid out codepoint by codepoint', (
    tester,
  ) async {
    await tester.runAsync(() async {
      // The reason the pages are images at all. ශ්‍රී is one conjunct built by
      // the font's GSUB table from five codepoints; drawn without shaping it
      // spreads into five separate marks and takes far more width.
      //
      // Measured rather than eyeballed: the shaped form is narrower than the
      // same five codepoints drawn with the joiner stripped out, which is as
      // close as a test can get to "the substitution happened".
      Future<int> widthOf(String text) async {
        final png = await PageRenderer.renderPng(
          ColoredBox(
            color: Colors.white,
            child: SizedBox.fromSize(
              size: PageRenderer.a4,
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 60,
                    color: Colors.black,
                    fontFamily: 'NotoSansSinhala',
                  ),
                ),
              ),
            ),
          ),
          pixelRatio: 1,
        );

        final image = await decode(png);
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        image.dispose();

        var rightmost = 0;
        for (var y = 0; y < image.height; y++) {
          for (var x = 0; x < image.width; x++) {
            final i = (y * image.width + x) * 4;
            if (data!.getUint8(i + 3) < 255) continue;
            if (data.getUint8(i) < 200 && x > rightmost) rightmost = x;
          }
        }
        return rightmost;
      }

      // ශ්‍රී — with the zero-width joiner that asks for the conjunct.
      final conjunct = await widthOf('ශ්‍රී');
      // The same letters with the joiner removed, so no conjunct is requested.
      final separate = await widthOf('ශ්රී');

      expect(conjunct, greaterThan(0), reason: 'nothing was drawn at all');
      expect(
        conjunct,
        lessThan(separate),
        reason:
            'the conjunct is no narrower than the unjoined letters, so the '
            'font is not being shaped',
      );
    });
  });

  testWidgets('two different pages really do differ', (tester) async {
    await tester.runAsync(() async {
      // Guards the dullest possible bug: a renderer that caches, or that
      // captures the same boundary twice, and puts page one into every slot of
      // a six-page report.
      //
      // The two strings differ in length on purpose. flutter_test draws Latin
      // in a placeholder font where every glyph is the same square, so 'One'
      // and 'Two' rasterise to byte-identical pages and this passed for the
      // wrong reason until the lengths differed.
      final first = await PageRenderer.renderPng(page('One'), pixelRatio: 1);
      final second = await PageRenderer.renderPng(
        page('Seventeen'),
        pixelRatio: 1,
      );

      expect(first, isNot(equals(second)));
    });
  });

  testWidgets('rendering many pages in a row stays stable', (tester) async {
    await tester.runAsync(() async {
      // Each page builds and tears down its own render tree. If the teardown is
      // wrong this is where it shows: an assertion, a leak, or a page that comes
      // back blank after the first.
      for (var i = 0; i < 6; i++) {
        final png = await PageRenderer.renderPng(
          page('Page $i'),
          pixelRatio: 1,
        );
        expect(
          await inkedPixels(png),
          greaterThan(100),
          reason: 'page $i came back blank',
        );
      }
    });
  });
}
