import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/config/app_locale.dart';
import 'package:nakshatra/features/onboarding/data/place_repository.dart';
import 'package:nakshatra/features/onboarding/domain/birth_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final repo = PlaceRepository(rootBundle);

  group('bundled place data', () {
    test('loads and every entry is complete', () async {
      final places = await repo.all();
      expect(places, isNotEmpty);

      for (final p in places) {
        expect(p.en, isNotEmpty);
        expect(p.si, isNotEmpty, reason: '${p.en} has no Sinhala name');
        expect(p.ta, isNotEmpty, reason: '${p.en} has no Tamil name');
        expect(p.district, isNotEmpty, reason: p.en);
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
      for (final p in await repo.all()) {
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
      final byDistrict = {for (final p in await repo.all()) p.district: p};
      expect(byDistrict['Kandy']?.districtLabel(AppLocale.si), 'මහනුවර');
      expect(byDistrict['Jaffna']?.districtLabel(AppLocale.ta), 'யாழ்ப்பாணம்');
      expect(byDistrict['Colombo']?.districtLabel(AppLocale.si), 'කොළඹ');
    });

    test('a profile saved before the translations existed still opens', () {
      // Shipped builds wrote a place with no districtSi/districtTa. Reading
      // one back must not throw and must not leave the subtitle blank.
      final old = Place.fromJson({
        'en': 'Panadura',
        'si': 'පානදුර',
        'ta': 'பாணந்துறை',
        'lat': 6.713,
        'lon': 79.903,
        'district': 'Kalutara',
      });

      expect(old.districtLabel(AppLocale.si), 'Kalutara');
      expect(old.districtLabel(AppLocale.en), 'Kalutara');
      expect(old.toJson().containsKey('districtSi'), isFalse);
    });

    test('a place round-trips through JSON with its districts', () async {
      final original = (await repo.all()).first;
      final copy = Place.fromJson(original.toJson());

      for (final locale in AppLocale.values) {
        expect(copy.label(locale), original.label(locale));
        expect(copy.districtLabel(locale), original.districtLabel(locale));
      }
    });

    test('coordinates fall inside Sri Lanka', () async {
      // A transposed or mistyped coordinate produces a chart that is subtly
      // wrong rather than obviously broken, so bound-check the data itself.
      for (final p in await repo.all()) {
        expect(
          p.latitude,
          inInclusiveRange(5.8, 10.0),
          reason: '${p.en} latitude looks wrong',
        );
        expect(
          p.longitude,
          inInclusiveRange(79.4, 82.0),
          reason: '${p.en} longitude looks wrong',
        );
      }
    });

    test('no duplicate place names', () async {
      final names = (await repo.all()).map((p) => p.en).toList();
      expect(names.toSet().length, names.length);
    });
  });

  group('search', () {
    test('empty query returns everything', () async {
      expect((await repo.search('')).length, (await repo.all()).length);
    });

    test('finds a city by English name', () async {
      final r = await repo.search('Kandy');
      expect(r.first.en, 'Kandy');
    });

    test('finds the same city typed in Sinhala', () async {
      final r = await repo.search('මහනුවර');
      expect(r.first.en, 'Kandy');
    });

    test('finds the same city typed in Tamil', () async {
      final r = await repo.search('யாழ்ப்பாணம்');
      expect(r.first.en, 'Jaffna');
    });

    test('is case insensitive', () async {
      expect((await repo.search('COLOMBO')).first.en, 'Colombo');
    });

    test('matches district as well as town', () async {
      final r = await repo.search('Ampara');
      expect(r.map((p) => p.en), contains('Kalmunai'));
    });

    test('prefix matches rank above substring matches', () async {
      final r = await repo.search('Gampaha');
      expect(r.first.en, 'Gampaha');
    });

    test('unknown query returns nothing', () async {
      expect(await repo.search('zzzz'), isEmpty);
    });
  });

  group('BirthProfile', () {
    final place = Place(
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
      expect(restored.birthTimeKnown, isTrue);
      expect(restored.place.latitude, closeTo(place.latitude, 1e-9));
      expect(restored.place.longitude, closeTo(place.longitude, 1e-9));
      expect(restored.place.timezone, 'Asia/Colombo');
    });

    test('an unknown birth time survives the round trip', () {
      // If this flag were lost, an assumed sunrise would be presented as a
      // real birth time and the approximate-houses warning would vanish.
      final original = BirthProfile(
        name: 'Test',
        birthDate: DateTime(1990, 6, 15),
        birthTime: BirthProfile.defaultUnknownTime,
        place: place,
        birthTimeKnown: false,
      );

      final restored = BirthProfile.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
      );

      expect(restored.birthTimeKnown, isFalse);
    });

    test('localWallClock combines date and time', () {
      final p = BirthProfile(
        name: 'Test',
        birthDate: DateTime(1990, 6, 15),
        birthTime: const Duration(hours: 14, minutes: 30),
        place: place,
        birthTimeKnown: true,
      );

      expect(p.localWallClock, DateTime(1990, 6, 15, 14, 30));
    });
  });
}
