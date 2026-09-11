import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/config/app_locale.dart';
import 'package:nakshatra/features/onboarding/data/place_repository.dart';
import 'package:nakshatra/features/onboarding/domain/birth_profile.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final repo = PlaceRepository(rootBundle);

  /// Every place in the bundle, across every country.
  ///
  /// Slow by design — it decodes all 244 files — so the data-wide invariants
  /// share one pass rather than paying for it each.
  Future<List<Place>> everywhere() async {
    final out = <Place>[];
    for (final c in await repo.countries()) {
      out.addAll(await repo.inCountry(c.code));
    }
    return out;
  }

  group('the country index', () {
    test('every listed country has a file, with the count it claims', () async {
      final countries = await repo.countries();
      expect(countries, isNotEmpty);

      for (final c in countries) {
        final places = await repo.inCountry(c.code);
        expect(
          places.length,
          c.placeCount,
          reason: '${c.code} index says ${c.placeCount}, file has '
              '${places.length} — the index and the files were built '
              'from different runs',
        );
        expect(c.code, matches(RegExp(r'^[A-Z]{2}$')));
        expect(c.en, isNotEmpty);
      }
    });

    test('Sri Lanka and India are named in script, and sort findably', () async {
      final byCode = {for (final c in await repo.countries()) c.code: c};

      expect(byCode['LK']!.label(true, false), 'ශ්‍රී ලංකාව');
      expect(byCode['LK']!.label(false, true), 'இலங்கை');
      expect(byCode['IN']!.label(false, true), 'இந்தியா');

      // No Sinhala for India, so a Sinhala reader gets English rather than
      // nothing — the same fallback the place list uses.
      expect(byCode['IN']!.label(true, false), 'India');

      // Searchable by code as well as name: someone who knows "AE" should not
      // have to remember "United Arab Emirates".
      expect(byCode['AE']!.searchable, contains('ae'));
    });
  });

  group('timezones', () {
    // The reason this whole data set exists, and the one failure that would
    // reach a user as a crash rather than a wrong row.
    test('every zone in the bundle resolves in the tz database', () async {
      tzdata.initializeTimeZones();

      final zones = <String>{};
      for (final p in await everywhere()) {
        expect(p.timezone, isNotEmpty, reason: '${p.en} has no timezone');
        zones.add(p.timezone);
      }
      expect(zones.length, greaterThan(300));

      for (final zone in zones) {
        // `tz.getLocation` throws on an unknown name. That throw would happen
        // on the chart screen, after onboarding had already been completed
        // successfully — so a zone GeoNames knows and the bundled tz database
        // does not must fail here, in CI, and not there.
        expect(
          () => tz.getLocation(zone),
          returnsNormally,
          reason: '$zone is in the place data but not in the tz database',
        );
      }
    });

    test('a place outside Sri Lanka keeps its own zone', () async {
      final chennai =
          (await repo.inCountry('IN')).firstWhere((p) => p.en == 'Chennai');
      final london =
          (await repo.inCountry('GB')).firstWhere((p) => p.en == 'London');

      expect(chennai.timezone, 'Asia/Kolkata');
      expect(london.timezone, 'Europe/London');
    });

    test('the same wall clock in two zones is a different instant', () {
      tzdata.initializeTimeZones();

      // This is what the bug behind this data set looked like: a birth in
      // London read as if it had happened in Colombo. The gap is the whole
      // point — five and a half hours in January, four and a half in July,
      // which is why a fixed offset cannot stand in for a zone.
      const wall = [1990, 6, 15, 14, 30];
      final inLondon = tz.TZDateTime(
        tz.getLocation('Europe/London'),
        wall[0], wall[1], wall[2], wall[3], wall[4],
      );
      final inColombo = tz.TZDateTime(
        tz.getLocation('Asia/Colombo'),
        wall[0], wall[1], wall[2], wall[3], wall[4],
      );

      final gap = inLondon.toUtc().difference(inColombo.toUtc());
      expect(gap, const Duration(hours: 4, minutes: 30));

      // The Earth turns 15 degrees an hour, so that gap moves the ascendant
      // by about 67 degrees — more than two whole rāśi.
      final degrees = gap.inMinutes / 60.0 * 15.0;
      expect(degrees, closeTo(67.5, 0.01));
      expect(degrees / 30.0, greaterThan(2.0));
    });
  });

  group('worldwide data', () {
    test('coordinates are on the planet and not transposed', () async {
      for (final p in await everywhere()) {
        expect(p.en, isNotEmpty);
        expect(p.district, isNotEmpty, reason: p.en);
        expect(
          p.latitude,
          inInclusiveRange(-90.0, 90.0),
          reason: '${p.en} latitude',
        );
        expect(
          p.longitude,
          inInclusiveRange(-180.0, 180.0),
          reason: '${p.en} longitude',
        );
        // 0,0 is in the Atlantic and is what a failed parse looks like.
        expect(
          p.latitude == 0 && p.longitude == 0,
          isFalse,
          reason: '${p.en} sits at null island',
        );
      }
    });

    test('a name is never filled in with its English form', () async {
      // The fallback belongs at display time, not in the data: storing
      // "the Tamil for Berlin is Berlin" would be indistinguishable from a
      // real translation in every later release.
      for (final p in await everywhere()) {
        if (p.siOrNull != null) {
          expect(p.siOrNull, isNot(p.en), reason: '${p.en} si is its English');
        }
        if (p.taOrNull != null) {
          expect(p.taOrNull, isNot(p.en), reason: '${p.en} ta is its English');
        }
      }
    });

    test('only Sri Lanka and India carry translated names', () async {
      for (final c in await repo.countries()) {
        final places = await repo.inCountry(c.code);
        final translated =
            places.where((p) => p.siOrNull != null || p.taOrNull != null);
        if (c.code == 'LK' || c.code == 'IN') continue;
        expect(
          translated,
          isEmpty,
          reason: '${c.code} carries translations it was not meant to',
        );
      }
    });
  });

  group('Sri Lankan data', () {
    test('coordinates fall inside Sri Lanka', () async {
      // A transposed or mistyped coordinate produces a chart that is subtly
      // wrong rather than obviously broken, so bound-check the data itself.
      for (final p in await repo.inCountry('LK')) {
        expect(p.latitude, inInclusiveRange(5.8, 10.0), reason: p.en);
        expect(p.longitude, inInclusiveRange(79.4, 82.0), reason: p.en);
        expect(p.timezone, 'Asia/Colombo');
      }
    });

    test('every district is translated, and not just copied', () async {
      // The place names were in three scripts from the start but the district
      // under them was English-only, so a Sinhala user picking a birth place
      // read a Sinhala town over an English district (KAN-58). A missing
      // translation falls back to English silently by design, which is right
      // for an old saved profile and wrong for the bundled data — so the data
      // has to be checked here rather than left to show up on a phone.
      //
      // This also guards the merge: GeoNames adds Sri Lankan towns that have
      // no Sinhala district of their own, and they must pick one up from the
      // curated list rather than appearing subtitled in English.
      for (final p in await repo.inCountry('LK')) {
        for (final locale in AppLocale.values) {
          expect(
            p.districtLabel(locale),
            isNotEmpty,
            reason: '${p.en}: no district in ${locale.englishName}',
          );
        }
        expect(
          p.districtLabel(AppLocale.si),
          isNot(p.district),
          reason: '${p.district} was left in English in Sinhala',
        );
        expect(
          p.districtLabel(AppLocale.ta),
          isNot(p.district),
          reason: '${p.district} was left in English in Tamil',
        );
      }
    });

    test('a district translation is a name, not a transliteration', () async {
      // Kandy is මහනුවර and Jaffna is யாழ்ப்பாணம் — different words, not the
      // English sounds respelled. Spot-checking the two that a transliteration
      // would most obviously mangle is enough to catch a bulk mistake.
      final byDistrict = {
        for (final p in await repo.inCountry('LK')) p.district: p,
      };
      expect(byDistrict['Kandy']?.districtLabel(AppLocale.si), 'මහනුවර');
      expect(byDistrict['Jaffna']?.districtLabel(AppLocale.ta), 'யாழ்ப்பாணம்');
      expect(byDistrict['Colombo']?.districtLabel(AppLocale.si), 'කොළඹ');
    });

    test('the curated towns GeoNames omits are still here', () async {
      // GeoNames' Sri Lankan population figures are municipal-council numbers,
      // so its population-15000 cut drops towns this size. If a future rebuild
      // ever leans on GeoNames alone, these disappear silently.
      final names = (await repo.inCountry('LK')).map((p) => p.en).toSet();
      for (final town in ['Gampaha', 'Polonnaruwa', 'Bandarawela', 'Tangalle']) {
        expect(names, contains(town));
      }
    });

    test('no duplicate place names', () async {
      final names = (await repo.inCountry('LK')).map((p) => p.en).toList();
      expect(names.toSet().length, names.length);
    });
  });

  group('search', () {
    test('empty query returns everything in that country', () async {
      expect(
        (await repo.search('LK', '')).length,
        (await repo.inCountry('LK')).length,
      );
    });

    test('finds a city by English name', () async {
      expect((await repo.search('LK', 'Kandy')).first.en, 'Kandy');
    });

    test('finds the same city typed in Sinhala', () async {
      expect((await repo.search('LK', 'මහනුවර')).first.en, 'Kandy');
    });

    test('finds the same city typed in Tamil', () async {
      expect((await repo.search('LK', 'யாழ்ப்பாணம்')).first.en, 'Jaffna');
    });

    test('is case insensitive', () async {
      expect((await repo.search('LK', 'COLOMBO')).first.en, 'Colombo');
    });

    test('matches district as well as town', () async {
      final r = await repo.search('LK', 'Ampara');
      expect(r.map((p) => p.en), contains('Kalmunai'));
    });

    test('prefix matches rank above substring matches', () async {
      expect((await repo.search('LK', 'Gampaha')).first.en, 'Gampaha');
    });

    test('unknown query returns nothing', () async {
      expect(await repo.search('LK', 'zzzz'), isEmpty);
    });

    test('search is scoped to one country', () async {
      // Two places in this data are called Colombo. Searching Sri Lanka must
      // not surface the Brazilian one, and vice versa — which is the whole
      // reason the picker asks for a country first.
      final lk = await repo.search('LK', 'Colombo');
      final br = await repo.search('BR', 'Colombo');

      expect(lk.map((p) => p.en), contains('Colombo'));
      expect(br.map((p) => p.en), contains('Colombo'));
      expect(lk.first.timezone, 'Asia/Colombo');
      expect(br.first.timezone, startsWith('America/'));
      expect(lk.first.latitude, isNot(br.first.latitude));
    });

    test('a Tamil speaker can find an Indian city in Tamil', () async {
      final r = await repo.search('IN', 'சென்னை');
      expect(r.map((p) => p.en), contains('Chennai'));
    });
  });

  group('Place serialisation', () {
    test('a timezone survives the round trip', () {
      // KAN-67: `toJson` wrote this key and `fromJson` never read it, so the
      // zone silently reset to Asia/Colombo on every app restart and every
      // sync. Invisible while every place was Sri Lankan, and a chart hours
      // wrong the moment one was not.
      const melbourne = Place(
        en: 'Melbourne',
        latitude: -37.814,
        longitude: 144.963,
        district: 'Melbourne',
        countryCode: 'AU',
        timezone: 'Australia/Melbourne',
      );

      final restored = Place.fromJson(melbourne.toJson());
      expect(restored.timezone, 'Australia/Melbourne');
      expect(restored.countryCode, 'AU');
    });

    test('a profile saved before timezones were read back still opens', () {
      // Shipped builds wrote the key but never read it. Those profiles are all
      // Sri Lankan, so Colombo is the correct answer for them and the only
      // case where this default is right.
      final old = Place.fromJson({
        'en': 'Panadura',
        'si': 'පානදුර',
        'ta': 'பாணந்துறை',
        'lat': 6.713,
        'lon': 79.903,
        'district': 'Kalutara',
      });

      expect(old.timezone, 'Asia/Colombo');
      expect(old.districtLabel(AppLocale.si), 'Kalutara');
      expect(old.countryCode, isNull);
      expect(old.toJson().containsKey('districtSi'), isFalse);
    });

    test('an untranslated place falls back to English on screen', () {
      const berlin = Place(
        en: 'Berlin',
        latitude: 52.524,
        longitude: 13.411,
        district: 'Berlin',
        countryCode: 'DE',
        timezone: 'Europe/Berlin',
      );

      for (final locale in AppLocale.values) {
        expect(berlin.label(locale), 'Berlin');
      }
      // Absent, not empty: nothing may later mistake this for a translation.
      expect(berlin.toJson().containsKey('si'), isFalse);
      expect(berlin.toJson().containsKey('ta'), isFalse);
    });

    test('a place round-trips through JSON with every field', () async {
      final original = (await repo.inCountry('LK')).first;
      final copy = Place.fromJson(original.toJson());

      for (final locale in AppLocale.values) {
        expect(copy.label(locale), original.label(locale));
        expect(copy.districtLabel(locale), original.districtLabel(locale));
      }
      expect(copy.timezone, original.timezone);
      expect(copy.latitude, original.latitude);
      expect(copy.longitude, original.longitude);
    });
  });

  group('BirthProfile', () {
    const place = Place(
      timezone: 'Asia/Colombo',
      en: 'Colombo',
      si: 'කොළඹ',
      ta: 'கொழும்பு',
      latitude: 6.9271,
      longitude: 79.8612,
      district: 'Colombo',
    );

    test('round-trips through JSON', () {
      final original = BirthProfile(
        name: 'Test',
        birthDate: DateTime(1990, 6, 15),
        birthTime: const Duration(hours: 14, minutes: 30),
        place: place,
        birthTimeKnown: true,
      );

      final restored = BirthProfile.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
      );

      expect(restored.name, original.name);
      expect(restored.birthDate, original.birthDate);
      expect(restored.birthTime, original.birthTime);
      expect(restored.place.en, original.place.en);
      expect(restored.place.timezone, original.place.timezone);
      expect(restored.birthTimeKnown, original.birthTimeKnown);
    });
  });
}
