import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/db/app_database.dart';
import 'package:nakshatra/core/db/profile_store.dart';
import 'package:nakshatra/core/router/app_router.dart';
import 'package:nakshatra/features/onboarding/data/profile_repository.dart';
import 'package:nakshatra/features/onboarding/domain/birth_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Several saved charts, and switching between them (KAN-19).
///
/// The store's own rules — exactly one selected, handing over on delete — are
/// tested next door. What is new here is the repository on top of it: keeping
/// the synchronous [ProfileRepository.load] and the preferences mirror in step
/// with whoever is selected, because both are read before the first frame and
/// getting either wrong shows somebody else's chart.
void main() {
  late AppDatabase db;
  late ProfileStore store;
  late SharedPreferences prefs;
  late ProfileRepository repository;

  const colombo = Place(
    en: 'Colombo',
    si: 'කොළඹ',
    ta: 'கொழும்பு',
    latitude: 6.927,
    longitude: 79.861,
    district: 'Colombo',
  );

  BirthProfile profile(String name) => BirthProfile(
    name: name,
    birthDate: DateTime(2000, 7, 23),
    birthTime: const Duration(minutes: 665),
    birthTimeKnown: true,
    place: colombo,
  );

  /// The name in the preferences mirror, which is the fallback if the database
  /// is ever lost.
  String? mirroredName() {
    final raw = prefs.getString('birth_profile_v1');
    if (raw == null) return null;
    return (jsonDecode(raw) as Map<String, dynamic>)['name'] as String?;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase(NativeDatabase.memory());
    store = ProfileStore(db);
    repository = ProfileRepository(prefs, store: store);
  });

  tearDown(() => db.close());

  group('adding another chart', () {
    test('the new one becomes the one being shown', () async {
      // What the user just did was type somebody's birth details, so the next
      // screen should be that person's chart rather than the previous one's.
      await repository.add(profile('Amma'));
      await repository.add(profile('Thaththa'));

      expect(repository.load()?.name, 'Thaththa');
      expect((await store.selected())?.profile.name, 'Thaththa');
    });

    test(
      'the mirror follows, so a lost database restores the right one',
      () async {
        await repository.add(profile('Amma'));
        expect(mirroredName(), 'Amma');

        await repository.add(profile('Thaththa'));
        expect(mirroredName(), 'Thaththa');
      },
    );

    test('every added chart is kept, not replaced', () async {
      await repository.add(profile('Amma'));
      await repository.add(profile('Thaththa'));
      await repository.add(profile('Malli'));

      final all = await repository.all();
      expect(all.map((s) => s.profile.name), ['Amma', 'Thaththa', 'Malli']);
    });
  });

  group('switching', () {
    test('load() answers with the newly selected chart', () async {
      // load() is synchronous and the router reads it before the first frame.
      // If it kept answering with the previous person, every screen would
      // disagree with the switcher that had just been used.
      final amma = await store.add(profile('Amma'), select: true);
      await repository.add(profile('Thaththa'));

      expect(repository.load()?.name, 'Thaththa');

      final switched = await repository.select(amma);

      expect(switched?.name, 'Amma');
      expect(repository.load()?.name, 'Amma');
      expect(mirroredName(), 'Amma');
    });

    test('exactly one chart is ever marked as showing', () async {
      final amma = await store.add(profile('Amma'));
      await repository.add(profile('Thaththa'));
      await repository.select(amma);

      final all = await repository.all();
      expect(all.where((s) => s.isSelected).map((s) => s.profile.name), [
        'Amma',
      ]);
    });

    test('an id that is gone changes nothing', () async {
      await repository.add(profile('Amma'));

      expect(await repository.select(9999), isNull);
      expect(repository.load()?.name, 'Amma');
    });
  });

  group('removing', () {
    test('hands over to a survivor rather than leaving nobody', () async {
      final amma = await store.add(profile('Amma'), select: true);
      await store.add(profile('Thaththa'));

      final remaining = await repository.remove(amma);

      expect(remaining?.name, 'Thaththa');
      expect(repository.load()?.name, 'Thaththa');
      expect(mirroredName(), 'Thaththa');
    });

    test('removing someone else leaves the shown chart alone', () async {
      await store.add(profile('Amma'), select: true);
      final thaththa = await store.add(profile('Thaththa'));

      final remaining = await repository.remove(thaththa);

      expect(remaining?.name, 'Amma');
      expect(await repository.all(), hasLength(1));
    });

    test('removing the last one clears the mirror too', () async {
      // Otherwise the next launch would restore a chart the user deleted,
      // which is the one thing a delete has to be trusted about.
      final only = await store.add(profile('Amma'), select: true);
      await repository.remove(only);

      expect(repository.load(), isNull);
      expect(mirroredName(), isNull);
    });
  });

  group('a build with no database', () {
    test('reports no saved charts rather than a list of one', () async {
      // Falling back to preferences means exactly one profile and nothing to
      // switch between. A list of one would offer a switcher that cannot
      // switch.
      final withoutStore = ProfileRepository(prefs);
      await withoutStore.save(profile('Alone'));

      expect(await withoutStore.all(), isEmpty);
      expect(withoutStore.load()?.name, 'Alone');
    });

    test('switching and removing are no-ops rather than crashes', () async {
      final withoutStore = ProfileRepository(prefs);
      await withoutStore.save(profile('Alone'));

      expect(await withoutStore.select(1), isNull);
      expect(await withoutStore.remove(1), isNull);
      expect(withoutStore.load()?.name, 'Alone');
    });
  });

  group('the route that collects a second chart', () {
    test('a user with a profile is let into the wizard to add one', () {
      // The redirect exists to keep somebody who already has a profile out of
      // onboarding. It has to make an exception for adding, exactly as it
      // already does for editing (KAN-61), or "Add another chart" bounces
      // straight back to home.
      expect(
        redirectFor(location: Routes.addProfile, hasProfile: true),
        isNull,
      );
      expect(
        redirectFor(location: Routes.editProfile, hasProfile: true),
        isNull,
      );
    });

    test('and is still turned away from a plain onboarding link', () {
      expect(
        redirectFor(location: Routes.onboarding, hasProfile: true),
        Routes.home,
      );
    });
  });
}
