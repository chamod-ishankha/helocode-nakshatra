import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The translation files themselves, checked as data.
///
/// gen_l10n warns about a missing key but is happy with an English string
/// sitting in the Sinhala file, which is the failure that actually happens:
/// a key gets added, the template is updated, and the other two are filled in
/// "later". This app's whole premise is that a Sri Lankan user reads it in
/// their own language, so an untranslated string is a product defect, not a
/// cosmetic one.
void main() {
  Map<String, String> load(String code) {
    final file = File('lib/l10n/app_$code.arb');
    expect(file.existsSync(), isTrue, reason: '${file.path} is missing');

    final raw = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    return {
      // @-prefixed entries are metadata (descriptions, placeholders), not text.
      for (final e in raw.entries)
        if (!e.key.startsWith('@')) e.key: e.value as String,
    };
  }

  late Map<String, String> en;
  late Map<String, String> si;
  late Map<String, String> ta;

  setUpAll(() {
    en = load('en');
    si = load('si');
    ta = load('ta');
  });

  test('the template has something to translate', () {
    expect(en, isNotEmpty);
  });

  test('every language defines exactly the template keys', () {
    for (final entry in {'si': si, 'ta': ta}.entries) {
      expect(
        entry.value.keys.toSet(),
        en.keys.toSet(),
        reason: 'app_${entry.key}.arb does not match app_en.arb',
      );
    }
  });

  test('no string was left in English', () {
    // Proper nouns that are the same in every language. Anything else
    // matching English means it was never translated.
    const sameEverywhere = {
      'appTitle',
      'accountContinueWithGoogle',
      'accountSavedToEmail',
      'chartAyanamsa',
    };

    final untranslated = <String>[];
    for (final key in en.keys) {
      if (sameEverywhere.contains(key)) continue;
      if (si[key] == en[key]) untranslated.add('si/$key');
      if (ta[key] == en[key]) untranslated.add('ta/$key');
    }

    expect(untranslated, isEmpty, reason: 'still in English: $untranslated');
  });

  test('nothing is blank', () {
    for (final entry in {'en': en, 'si': si, 'ta': ta}.entries) {
      for (final pair in entry.value.entries) {
        expect(
          pair.value.trim(),
          isNotEmpty,
          reason: '${entry.key}/${pair.key} is empty',
        );
      }
    }
  });

  test('placeholders survive translation', () {
    // A dropped {name} does not fail to compile — it renders a sentence with
    // a hole in it, in one language only.
    final pattern = RegExp(r'\{(\w+)\}');

    for (final key in en.keys) {
      final expected = pattern
          .allMatches(en[key]!)
          .map((m) => m.group(1)!)
          .toSet();
      if (expected.isEmpty) continue;

      for (final entry in {'si': si, 'ta': ta}.entries) {
        final actual = pattern
            .allMatches(entry.value[key]!)
            .map((m) => m.group(1)!)
            .toSet();
        expect(
          actual,
          expected,
          reason: '${entry.key}/$key has the wrong placeholders',
        );
      }
    }
  });

  test('the scripts are actually the right scripts', () {
    // Catches a file filled in with the wrong language, which every other
    // check here would pass.
    final sinhala = RegExp(r'[඀-෿]');
    final tamil = RegExp(r'[஀-௿]');

    expect(
      si.values.where(sinhala.hasMatch).length,
      greaterThan(si.length ~/ 2),
      reason: 'app_si.arb is mostly not in Sinhala script',
    );
    expect(
      ta.values.where(tamil.hasMatch).length,
      greaterThan(ta.length ~/ 2),
      reason: 'app_ta.arb is mostly not in Tamil script',
    );
  });
}
