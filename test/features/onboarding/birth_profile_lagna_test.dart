import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/astro/models.dart';
import 'package:nakshatra/features/onboarding/domain/birth_profile.dart';

/// The lagna a reader gives when they do not know their birth time, and what
/// it does to which parts of the chart can be shown as fact.
void main() {
  const colombo = Place(
    en: 'Colombo',
    latitude: 6.9271,
    longitude: 79.8612,
    district: 'Colombo',
    timezone: 'Asia/Colombo',
  );
  BirthProfile profile({bool timeKnown = false, Rasi? lagna}) => BirthProfile(
    name: 'Reader',
    birthDate: DateTime(1990, 5, 6),
    birthTime: const Duration(hours: 9, minutes: 12),
    place: colombo,
    birthTimeKnown: timeKnown,
    givenLagna: lagna,
  );

  group('the houses can be shown as fact', () {
    test('with a known time', () {
      expect(profile(timeKnown: true).housesKnown, isTrue);
    });
    test('with the reader\'s own lagna', () {
      expect(profile(lagna: Rasi.simha).housesKnown, isTrue);
    });
    test('not with sunrise standing in for both', () {
      expect(profile().housesKnown, isFalse);
    });
  });

  group('stored', () {
    test('the lagna survives a round trip', () {
      final back = BirthProfile.fromJson(
        profile(lagna: Rasi.vrischika).toJson(),
      );
      expect(back.givenLagna, Rasi.vrischika);
      expect(back.birthTimeKnown, isFalse);
      expect(back.birthTime, const Duration(hours: 9, minutes: 12));
    });

    test('a profile written before it existed has none', () {
      final json = profile().toJson();
      expect(json.containsKey('givenLagna'), isFalse);
      expect(BirthProfile.fromJson(json).givenLagna, isNull);
    });

    test(
      'a name this build does not know drops the lagna, not the profile',
      () {
        final json = profile().toJson()..['givenLagna'] = 'ophiuchus';
        final back = BirthProfile.fromJson(json);
        expect(back.givenLagna, isNull);
        expect(back.name, 'Reader');
      },
    );
  });

  test('copyWith can clear the lagna as well as keep it', () {
    final p = profile(lagna: Rasi.mesha);
    expect(p.copyWith(name: 'X').givenLagna, Rasi.mesha);
    expect(p.copyWith(givenLagna: () => null).givenLagna, isNull);
  });
}
