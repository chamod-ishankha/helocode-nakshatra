import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/astro/calendar_models.dart';
import 'package:nakshatra/core/astro/models.dart';
import 'package:nakshatra/core/astro/panchanga_models.dart';
import 'package:nakshatra/core/config/app_locale.dart';

/// The almanac vocabulary, checked as data.
///
/// About 190 terms went in at once (KAN-52). Reading them back one by one is
/// exactly the review that does not happen, and the failure mode is quiet: a
/// term left in English, a row pasted twice, a name that drifted a column and
/// now sits against the wrong sign. None of that shows on screen — it shows as
/// the wrong word on one day of the year.
///
/// These checks are about *shape*, and they are worth being clear about what
/// they cannot do. They prove every term is present, distinct, and in the
/// right script. They cannot prove අස්ලිස is what a Sri Lankan litha prints
/// against Āśleṣā. Only a reader with a litha can settle that, and the ticket
/// says so.
void main() {
  /// Latin letters, which no Sinhala or Tamil almanac term should contain.
  final latin = RegExp(r'[A-Za-z]');
  final sinhala = RegExp(r'[඀-෿]');
  final tamil = RegExp(r'[஀-௿]');

  /// Every translated set, as (what it is, English, Sinhala, Tamil) rows.
  final sets = <String, List<(String, String, String)>>{
    'nakṣatra': [for (final n in Nakshatra.values) (n.en, n.si, n.ta)],
    'tithi': [for (final t in Tithi.values) (t.en, t.si, t.ta)],
    'yoga': [for (final y in Yoga.values) (y.en, y.si, y.ta)],
    'karaṇa': [for (final k in Karana.values) (k.en, k.si, k.ta)],
    'vāra': [for (final v in Vara.values) (v.en, v.si, v.ta)],
    'paksha': [for (final p in Paksha.values) (p.en, p.si, p.ta)],
    'poya month': [for (final p in PoyaMonth.values) (p.en, p.si, p.ta)],
    'window': [for (final w in WindowKind.values) (w.en, w.si, w.ta)],
  };

  test('the counts are the traditional ones', () {
    // A pasted or dropped row is easiest to catch here, where the number is
    // fixed by the tradition rather than by anything in this code.
    expect(Nakshatra.values, hasLength(27));
    expect(Yoga.values, hasLength(27));
    expect(Tithi.values, hasLength(15), reason: '15 per pakṣa, 30 per month');
    expect(Karana.values, hasLength(11));
    expect(Vara.values, hasLength(7));
    expect(PoyaMonth.values, hasLength(12));
  });

  group('every term is translated', () {
    for (final entry in sets.entries) {
      test('${entry.key}: nothing left in English', () {
        for (final (en, si, ta) in entry.value) {
          expect(si, isNotEmpty, reason: '$en has no Sinhala');
          expect(ta, isNotEmpty, reason: '$en has no Tamil');
          expect(
            si,
            isNot(equals(en)),
            reason: '$en was copied rather than translated into Sinhala',
          );
          expect(
            ta,
            isNot(equals(en)),
            reason: '$en was copied rather than translated into Tamil',
          );
        }
      });

      test('${entry.key}: written in the right script', () {
        // Catches a row that slipped a column — a Tamil name in the Sinhala
        // slot reads as a translation until someone opens the app.
        for (final (en, si, ta) in entry.value) {
          expect(latin.hasMatch(si), isFalse, reason: '$en: Latin in Sinhala');
          expect(latin.hasMatch(ta), isFalse, reason: '$en: Latin in Tamil');
          expect(sinhala.hasMatch(si), isTrue, reason: '$en: not Sinhala');
          expect(tamil.hasMatch(ta), isTrue, reason: '$en: not Tamil');
          expect(tamil.hasMatch(si), isFalse, reason: '$en: Tamil in Sinhala');
          expect(
            sinhala.hasMatch(ta),
            isFalse,
            reason: '$en: Sinhala in Tamil',
          );
        }
      });

      test('${entry.key}: no two terms share a name', () {
        // A duplicate means one real term is missing and another is doubled,
        // which is invisible on screen and wrong on some day of the year.
        for (final (name, forms) in [
          ('English', entry.value.map((r) => r.$1)),
          ('Sinhala', entry.value.map((r) => r.$2)),
          ('Tamil', entry.value.map((r) => r.$3)),
        ]) {
          final list = forms.toList();
          expect(
            list.toSet(),
            hasLength(list.length),
            reason: '${entry.key} has a repeated $name name in $list',
          );
        }
      });
    }
  });

  test('label() returns the form for the language asked for', () {
    // The switch is written out by hand in eight enums; a copy-paste that
    // returns si for ta is the obvious way to get it wrong.
    expect(Nakshatra.revati.label(AppLocale.si), Nakshatra.revati.si);
    expect(Nakshatra.revati.label(AppLocale.ta), Nakshatra.revati.ta);
    expect(Nakshatra.revati.label(AppLocale.en), Nakshatra.revati.en);

    for (final locale in AppLocale.values) {
      expect(Tithi.pratipada.label(locale), isNotEmpty);
      expect(Yoga.shubha.label(locale), isNotEmpty);
      expect(Karana.vanija.label(locale), isNotEmpty);
      expect(Vara.budha.label(locale), isNotEmpty);
      expect(Paksha.krishna.label(locale), isNotEmpty);
      expect(Paksha.krishna.describe(locale), isNotEmpty);
      expect(PoyaMonth.vesak.label(locale), isNotEmpty);
      expect(WindowKind.rahu.label(locale), isNotEmpty);
    }
  });

  test('a few terms are the ones a reader would recognise', () {
    // Spot checks, not a second copy of the table: these are the terms most
    // likely to be recognised on sight by someone holding a litha, so if the
    // table were shifted by a row this is where it would show.
    expect(Nakshatra.ashwini.si, 'අස්විද');
    expect(Nakshatra.revati.ta, 'ரேவதி');
    expect(Nakshatra.krittika.ta, 'கார்த்திகை');
    expect(PoyaMonth.vesak.si, 'වෙසක්');
    expect(Vara.ravi.si, 'ඉරිදා');
    expect(Paksha.shukla.si, 'පුර');
    expect(Paksha.krishna.si, 'අව');
  });
}
