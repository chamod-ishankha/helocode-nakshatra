import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/features/compatibility/data/partner_repository.dart';
import 'package:nakshatra/features/compatibility/domain/compatibility_providers.dart';
import 'package:nakshatra/features/onboarding/data/profile_repository.dart';
import 'package:nakshatra/features/onboarding/domain/birth_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The partner survives the app being closed, and the form records the time
/// the reader actually saw.
void main() {
  const colombo = Place(
    en: 'Colombo',
    latitude: 6.9271,
    longitude: 79.8612,
    district: 'Colombo',
    timezone: 'Asia/Colombo',
  );
  final partner = BirthProfile(
    name: 'Partner',
    birthDate: DateTime(1992, 3, 4),
    birthTime: const Duration(hours: 14, minutes: 30),
    birthTimeKnown: true,
    place: colombo,
  );

  Future<ProviderContainer> launch(SharedPreferences prefs) async {
    final c = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('the partner is kept', () {
    late SharedPreferences prefs;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('across a restart', () async {
      // The bug: Android reclaims the app in the background, and the partner
      // used to live only in memory.
      final first = await launch(prefs);
      first.read(partnerProvider.notifier).set(partner);
      await Future<void>.delayed(Duration.zero);
      first.dispose();

      final second = await launch(prefs);
      final back = second.read(partnerProvider)!;
      expect(back.name, 'Partner');
      expect(back.birthDate, partner.birthDate);
      expect(back.birthTime, partner.birthTime);
      expect(back.place.en, 'Colombo');
    });

    test('until it is cleared, which removes it from the phone', () async {
      final c = await launch(prefs);
      c.read(partnerProvider.notifier).set(partner);
      await c.read(partnerProvider.notifier).clear();
      expect(c.read(partnerProvider), isNull);
      expect(prefs.getString(PartnerRepository.key), isNull);
    });

    test(
      'a stored partner this build cannot read is dropped, not fatal',
      () async {
        await prefs.setString(PartnerRepository.key, '{"name": 3');
        final c = await launch(prefs);
        expect(c.read(partnerProvider), isNull);
        expect(prefs.getString(PartnerRepository.key), isNull);
      },
    );
  });

  group('the time on the form', () {
    BirthProfile fromForm({Duration? time, bool timeKnown = true}) =>
        partnerFromForm(
          name: '  Partner ',
          date: DateTime(1992, 3, 4),
          time: time,
          timeKnown: timeKnown,
          place: colombo,
        );

    test('an untouched wheel is the 6:00 AM it shows, and known', () {
      final p = fromForm();
      expect(p.birthTime, const Duration(hours: 6));
      expect(p.birthTimeKnown, isTrue);
    });

    test('a chosen time is kept', () {
      final p = fromForm(time: const Duration(hours: 21, minutes: 5));
      expect(p.birthTime, const Duration(hours: 21, minutes: 5));
      expect(p.birthTimeKnown, isTrue);
    });

    test('only the box makes it unknown, and then sunrise is used', () {
      final p = fromForm(time: const Duration(hours: 21), timeKnown: false);
      expect(p.birthTimeKnown, isFalse);
      expect(p.birthTime, BirthProfile.defaultUnknownTime);
    });

    test('the name is trimmed', () {
      expect(fromForm().name, 'Partner');
    });
  });
}
