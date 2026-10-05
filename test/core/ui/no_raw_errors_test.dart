import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// No screen prints an exception (KAN-95).
///
/// The audit found "Could not load places: FormatException: …" on the
/// onboarding screen and a raw error in the calendar's best-days card. An
/// exception's text is for the log; on screen it frightens and explains
/// nothing. Read from the source, like the banner placement rule, because the
/// failures it guards are the ones a widget test never reaches.
void main() {
  test('presentation code never interpolates a caught error into the UI', () {
    // `'$e'`, `'${e}'`, `'$error'`, `'${error}'`, and `e.toString()` — the
    // shapes an exception takes on its way into a Text.
    final raw = RegExp(
      r"""'\$\{?(e|err|error)\}?'|\b(e|err|error)\.toString\(\)""",
    );
    final offenders = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      final onScreen =
          path.contains('/presentation/') || path.startsWith('lib/core/ui/');
      if (!onScreen) continue;

      final lines = entity.readAsLinesSync();
      for (final (i, line) in lines.indexed) {
        if (raw.hasMatch(line) && !line.contains('AppLogger')) {
          offenders.add('$path:${i + 1}: ${line.trim()}');
        }
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
