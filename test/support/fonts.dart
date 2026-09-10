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
/// Latin still renders in the placeholder face. Registering a real Roboto
/// does **not** help: the placeholder is what an unnamed font family resolves
/// to, it claims every glyph, so `fontFamilyFallback` is never consulted. Only
/// naming a family explicitly escapes it — [robotoFile] is there for the one
/// caller that needs to.
///
/// So English measurements stay pessimistic, which is the safe direction for a
/// layout test — English is the short language here. It is the wrong direction
/// for anything that *exports* what it rendered: a PDF or a screenshot written
/// out of a test has every Latin letter as a solid black box. That is not a
/// bug in what was exported, but it is unusable as evidence.
///
/// Call this from `setUpAll`, once per test file, and **before anything has
/// been rendered**.
///
/// That ordering is not tidiness. `FontLoader.load` tells every live render
/// object that the system fonts changed, which leaves a callback pending on
/// each of them; disposing a render tree while one is outstanding trips
/// `!_hasPendingSystemFontsDidChangeCallBack` inside `RenderObject.dispose`,
/// and the failure surfaces on the *next* thing rendered rather than at the
/// load. Loading before the first frame leaves nothing to notify.
///
/// Not from a pump helper either: FontLoader re-parses the file on every call,
/// which turned a three-second suite into a six-minute one. Not memoised in a
/// top-level Future — that future belongs to whichever test zone created it,
/// and awaiting it from the next test hangs the whole suite with "did not
/// complete".
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

/// The family name [loadLatinFont] registers a real face under.
const String testLatinFont = 'RobotoForTests';

/// Loads a real Latin face, and returns whether it found one.
///
/// For callers that export what they render and need English to be legible
/// rather than a row of boxes. Use it by naming [testLatinFont] as the font
/// family — an unnamed family still resolves to the placeholder however many
/// real fonts are registered.
///
/// The file comes out of the Flutter SDK, which ships Roboto for Material.
/// Found by walking up from the test binary rather than from a configured
/// path, so it works on any machine with any SDK location — and returns false
/// rather than throwing if the layout ever changes, because no test should
/// fail over a font that only makes a sample look nicer.
Future<bool> loadLatinFont() async {
  final file = robotoFile();
  if (file == null) return false;

  final loader = FontLoader(testLatinFont)
    ..addFont(file.readAsBytes().then((b) => ByteData.view(b.buffer)));
  await loader.load();
  return true;
}

/// The SDK's Roboto, or null if it is not where it usually lives.
File? robotoFile() {
  // .../bin/cache/artifacts/engine/<platform>/flutter_tester(.exe)
  var dir = File(Platform.resolvedExecutable).parent;
  for (var up = 0; up < 8; up++) {
    final candidate = File('${dir.path}/material_fonts/roboto-regular.ttf');
    if (candidate.existsSync()) return candidate;
    dir = dir.parent;
  }
  return null;
}
