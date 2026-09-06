import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/astro/models.dart';
import 'package:nakshatra/features/horoscope/domain/fragment.dart';
import 'package:nakshatra/features/horoscope/domain/horoscope_engine.dart';
import 'package:nakshatra/features/horoscope/domain/horoscope_signals.dart';

/// The bundled copy (KAN-31 seed set, expanded by KAN-32).
///
/// Read from disk rather than through the asset bundle so a malformed file
/// fails here rather than at runtime on someone's phone. KAN-32 edits this by
/// hand in three scripts, so it will be wrong at some point.
void main() {
  final file = File('assets/content/horoscope_en.json');

  late List<Fragment> fragments;

  setUpAll(() {
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    fragments = [
      for (final f in json['fragments'] as List)
        Fragment.fromJson(f as Map<String, dynamic>),
    ];
  });

  test('the file exists and every fragment parses', () {
    expect(file.existsSync(), isTrue);
    expect(fragments, isNotEmpty);
  });

  test('ids are unique', () {
    // A duplicate id would make a reading untraceable, and would break the
    // promise that the same id means the same sentence in every language.
    final ids = fragments.map((f) => f.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('every category has at least one unconditional fragment', () {
    // Without a fallback, a category silently disappears on an ordinary day.
    for (final c in HoroscopeCategory.values) {
      final always = fragments.where(
        (f) => f.category == c && f.requires.isEmpty && f.excludes.isEmpty,
      );
      expect(always, isNotEmpty, reason: 'no fallback copy for ${c.name}');
    }
  });

  test('every required tag is one the engine can actually produce', () {
    // A typo like "saturn.sadesati" would make a fragment simply never
    // appear, with nothing to notice it by.
    final produced = <String>{};
    for (final rasi in Rasi.values) {
      for (final saturn in Rasi.values) {
        for (final moon in Rasi.values) {
          produced.addAll(
            HoroscopeSignals.from(
              rasi: rasi,
              date: DateTime(2026, 9, 7),
              transiting: {
                Graha.sun: Rasi.mesha,
                Graha.moon: moon,
                Graha.mars: Rasi.vrishabha,
                Graha.mercury: Rasi.mesha,
                Graha.jupiter: Rasi.mithuna,
                Graha.venus: Rasi.meena,
                Graha.saturn: saturn,
                Graha.rahu: Rasi.tula,
                Graha.ketu: Rasi.mesha,
              },
            ).tags,
          );
        }
      }
    }

    for (final f in fragments) {
      for (final tag in {...f.requires, ...f.excludes}) {
        expect(produced, contains(tag), reason: '${f.id} requires "$tag"');
      }
    }
  });

  test('a real reading comes out of the bundled copy', () {
    final h = HoroscopeEngine.build(
      signals: HoroscopeSignals.from(
        rasi: Rasi.karka,
        date: DateTime(2026, 9, 7),
        transiting: {
          Graha.sun: Rasi.simha,
          Graha.moon: Rasi.tula,
          Graha.mars: Rasi.kanya,
          Graha.mercury: Rasi.simha,
          Graha.jupiter: Rasi.karka,
          Graha.venus: Rasi.kanya,
          Graha.saturn: Rasi.meena,
          Graha.rahu: Rasi.kumbha,
          Graha.ketu: Rasi.simha,
        },
      ),
      fragments: fragments,
    );

    expect(h.sections, isNotEmpty);
    expect(h.sections[HoroscopeCategory.general], isNotNull);
    for (final text in h.sections.values) {
      expect(text.trim(), isNotEmpty);
    }
  });

  test('every sign gets a reading on an ordinary day', () {
    // The seed set must not leave a sign with a blank screen.
    for (final rasi in Rasi.values) {
      final h = HoroscopeEngine.build(
        signals: HoroscopeSignals.from(
          rasi: rasi,
          date: DateTime(2026, 9, 7),
          transiting: {
            Graha.sun: Rasi.simha,
            Graha.moon: Rasi.tula,
            Graha.mars: Rasi.kanya,
            Graha.mercury: Rasi.simha,
            Graha.jupiter: Rasi.karka,
            Graha.venus: Rasi.kanya,
            Graha.saturn: Rasi.meena,
            Graha.rahu: Rasi.kumbha,
            Graha.ketu: Rasi.simha,
          },
        ),
        fragments: fragments,
      );
      expect(
        h.sections.length,
        HoroscopeCategory.values.length,
        reason: 'a section was empty for ${rasi.en}',
      );
    }
  });
}
