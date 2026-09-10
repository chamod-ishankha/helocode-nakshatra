import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// What the daily reading is not allowed to say (KAN-40).
///
/// Play's policy bars an app from giving medical, financial or legal advice,
/// and it does not care that this one is astrology — the Health and Money
/// sections are exactly where a reviewer looks. The disclaimer on every screen
/// helps, but it is not a licence to write "see a doctor" or "buy shares".
///
/// This reads the shipped assets rather than the generator, because the assets
/// are what the app loads. Only English is scanned: si and ta are translations
/// of the same fragment ids, so a claim has to exist in the source first — and
/// the last test here is what keeps that assumption true.
void main() {
  /// Patterns that would put a claim in front of a reviewer.
  ///
  /// Deliberately blunt. A false positive costs one reworded sentence; a false
  /// negative costs a rejected release, and possibly a pulled app.
  const barred = <String, List<String>>{
    'medical': [
      r'\bdoctor\b',
      r'\bmedic',
      r'\bdiagnos',
      r'\bcure[sd]?\b',
      r'\bdisease\b',
      r'\bsymptom',
      r'\btreatment\b',
      r'\bpills?\b',
      r'\bsurgery\b',
      r'\bpregnan',
    ],
    'financial': [
      r'\binvest',
      r'\bshares?\b',
      r'\bstock',
      r'\bloan\b',
      r'\bmortgage\b',
      r'\bgambl',
      r'\blottery\b',
      r'\bcrypto',
    ],
    'legal': [r'\blawyer\b', r'\bsue\b', r'\blawsuit\b', r'\bcourt case\b'],
  };

  /// Every string in a content file, wherever it sits in the structure.
  List<String> stringsIn(Object? node) {
    final out = <String>[];
    void walk(Object? n) {
      if (n is Map) {
        for (final v in n.values) {
          walk(v);
        }
      } else if (n is List) {
        for (final v in n) {
          walk(v);
        }
      } else if (n is String) {
        out.add(n);
      }
    }

    walk(node);
    return out;
  }

  Object? load(String lang) => jsonDecode(
    File('assets/content/horoscope_$lang.json').readAsStringSync(),
  );

  test('the corpus is not empty, so the rest of this means something', () {
    // Without this, a missing or renamed asset would make every check below
    // pass on nothing at all.
    expect(stringsIn(load('en')).length, greaterThan(400));
  });

  for (final entry in barred.entries) {
    test('no ${entry.key} claims in the daily reading', () {
      final offenders = <String>[];

      for (final text in stringsIn(load('en'))) {
        for (final pattern in entry.value) {
          if (RegExp(pattern, caseSensitive: false).hasMatch(text)) {
            offenders.add('[$pattern] $text');
            break;
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'These read as ${entry.key} advice, which Play does not allow '
            'however the app is disclaimed:\n${offenders.join('\n')}',
      );
    });
  }

  test('all three languages carry the same fragment ids', () {
    // What lets the English-only scan above stand for all three. A Sinhala
    // fragment with no English counterpart would never be read by this file.
    Set<String> idsIn(String lang) => RegExp(r'"id"\s*:\s*"([^"]+)"')
        .allMatches(
          File('assets/content/horoscope_$lang.json').readAsStringSync(),
        )
        .map((m) => m.group(1)!)
        .toSet();

    final en = idsIn('en');
    expect(en, isNotEmpty);
    expect(idsIn('si'), en, reason: 'Sinhala has drifted from English');
    expect(idsIn('ta'), en, reason: 'Tamil has drifted from English');
  });
}
