import 'package:characters/characters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/astro/models.dart';
import 'package:nakshatra/core/config/app_locale.dart';

/// Localised graha names and their chart abbreviations (KAN-58).
///
/// The chart used to slice two letters off the English name, which is English
/// wherever the app is set. The repair that looks obvious - transliterating
/// "Su" into Sinhala letter by letter - is worse than the bug, because it
/// spells an English word in a script whose readers do not use it. These are
/// the forms printed Sri Lankan charts use, and they are pinned here because
/// nothing else would notice them being wrong.
void main() {
  group('every graha is named in every language', () {
    test('no name or abbreviation is empty', () {
      for (final g in Graha.values) {
        for (final locale in AppLocale.values) {
          expect(g.label(locale).trim(), isNotEmpty, reason: '${g.en} $locale');
          expect(
            g.shortLabel(locale).trim(),
            isNotEmpty,
            reason: '${g.en} $locale',
          );
        }
      }
    });

    test('Sinhala and Tamil are not the English left in place', () {
      // The failure mode of "localised" data that never was.
      final latin = RegExp(r'^[\x00-\x7F]+$');
      for (final g in Graha.values) {
        for (final locale in [AppLocale.si, AppLocale.ta]) {
          expect(latin.hasMatch(g.label(locale)), isFalse, reason: g.en);
          expect(latin.hasMatch(g.shortLabel(locale)), isFalse, reason: g.en);
        }
      }
    });
  });

  group('abbreviations stay usable in a chart cell', () {
    test('no two grahas share an abbreviation in any language', () {
      // Two grahas reading the same in one cell is unreadable, and Sinhala and
      // Tamil both have near-collisions - Saturn and Venus in Sinhala, Moon and
      // Saturn in Tamil - so this is a real risk, not a theoretical one.
      for (final locale in AppLocale.values) {
        final shorts = [for (final g in Graha.values) g.shortLabel(locale)];
        expect(
          shorts.toSet().length,
          shorts.length,
          reason: '$locale has a duplicate: $shorts',
        );
      }
    });

    test('abbreviations stay short enough for the cell', () {
      // A rasi cell is about 70px wide and may hold several grahas at once.
      for (final g in Graha.values) {
        for (final locale in AppLocale.values) {
          expect(
            g.shortLabel(locale).characters.length,
            lessThanOrEqualTo(4),
            reason: '${g.en} in $locale is "${g.shortLabel(locale)}"',
          );
        }
      }
    });

    test('an abbreviation is not longer than the full name', () {
      for (final g in Graha.values) {
        for (final locale in AppLocale.values) {
          expect(
            g.shortLabel(locale).characters.length,
            lessThanOrEqualTo(g.label(locale).characters.length),
            reason: '${g.en} in $locale',
          );
        }
      }
    });
  });

  group('rasi names', () {
    test('are translated, not transliterated', () {
      final latin = RegExp(r'^[\x00-\x7F]+$');
      for (final r in Rasi.values) {
        for (final locale in [AppLocale.si, AppLocale.ta]) {
          expect(latin.hasMatch(r.label(locale)), isFalse, reason: r.en);
        }
      }
    });

    test('all twelve are distinct in each language', () {
      for (final locale in AppLocale.values) {
        final names = [for (final r in Rasi.values) r.label(locale)];
        expect(names.toSet().length, 12, reason: '$locale');
      }
    });
  });
}
