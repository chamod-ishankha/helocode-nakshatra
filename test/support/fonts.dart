import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the Sinhala and Tamil faces the app ships, for tests that measure.
///
/// `flutter_test` replaces every font with a placeholder whose glyphs are all
/// one em square. That is fine for tests that only ask what text is present,
/// and actively misleading for tests that ask whether it fits: the placeholder
/// is far wider than Noto, so a layout that is comfortable on a phone can
/// overflow in a test, and the numbers in a failure message are fiction.
///
/// It misleads in both directions. A Tamil overflow this suite was written to
/// catch sat below the fold passing, while English cases failed on layouts
/// that are perfectly fine on a device — the same placeholder font, read as
/// evidence twice and wrong twice.
///
/// Latin still renders in the placeholder face; there is no real Roboto to
/// load in the test environment. So English measurements stay pessimistic,
/// which is the safe direction — English is the short language here.
/// Call this from `setUpAll`, once per test file.
///
/// Not from a pump helper: FontLoader re-parses the file on every call, which
/// turned a three-second suite into a six-minute one. Not memoised in a
/// top-level Future either — that future belongs to whichever test zone
/// created it, and awaiting it from the next test hangs the whole suite with
/// "did not complete".
Future<void> loadAppFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final family in const ['NotoSansSinhala', 'NotoSansTamil']) {
    final file = File('assets/fonts/$family.ttf');
    if (!file.existsSync()) {
      throw StateError(
        '${file.path} is missing — pubspec declares it, so a layout test '
        'would silently measure the placeholder font instead.',
      );
    }

    final loader = FontLoader(family)
      ..addFont(file.readAsBytes().then((b) => ByteData.view(b.buffer)));
    await loader.load();
  }
}
