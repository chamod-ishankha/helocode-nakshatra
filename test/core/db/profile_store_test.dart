import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/db/app_database.dart';
import 'package:nakshatra/core/db/profile_store.dart';
import 'package:nakshatra/features/onboarding/domain/birth_profile.dart';

/// Birth profiles in SQLite (KAN-19).
///
/// This is the most valuable data the app holds. Everything on every screen is
/// computed from these four values, and a user cannot be asked to remember a
/// birth time they were told once — so the parts worth testing hard are the
/// ones where data goes missing quietly: the migration off SharedPreferences,
/// and the rule that exactly one profile is selected.
///
/// Drift runs on the host here, so unlike the ephemeris this is all checkable
/// without a device.
void main() {
  late AppDatabase db;
  late ProfileStore store;

  const colombo = Place(
    en: 'Colombo',
    si: 'කොළඹ',
    ta: 'கொழும்பு',
    latitude: 6.927,
    longitude: 79.861,
    district: 'Colombo',
    districtSi: 'කොළඹ',
    districtTa: 'கொழும்பு',
  );

  /// A place saved by a build that had no district translations yet.
  const older = Place(
    en: 'Panadura',
    si: 'පානදුර',
    ta: 'பாணந்துறை',
    latitude: 6.713,
    longitude: 79.903,
    district: 'Kalutara',
  );

  BirthProfile profile(
    String name, {
    Place place = colombo,
    int minutes = 390,
  }) => BirthProfile(
    name: name,
    birthDate: DateTime(2000, 7, 23),
    birthTime: Duration(minutes: minutes),
    birthTimeKnown: true,
    place: place,
  );

  /// BirthProfile has no value equality, and the repository already compares
  /// through JSON, so the tests do too.
  String shape(BirthProfile p) => jsonEncode(p.toJson());

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    store = ProfileStore(db);
  });

  tearDown(() => db.close());

  group('saving and reading back', () {
    test('a profile survives the round trip intact', () async {
      final original = profile('Chamod');
      await store.add(original);

      final saved = await store.selected();
      expect(saved, isNotNull);
      expect(shape(saved!.profile), shape(original));
    });

    test('an unknown birth time stays unknown', () async {
      // The lagna is a convention rather than a computation when this is
      // false, and every screen says so. Losing the flag would silently turn
      // a guess into a fact.
      await store.add(
        BirthProfile(
          name: 'No time',
          birthDate: DateTime(1990, 1, 1),
          birthTime: BirthProfile.defaultUnknownTime,
          birthTimeKnown: false,
          place: colombo,
        ),
      );

      final saved = await store.selected();
      expect(saved!.profile.birthTimeKnown, isFalse);
      expect(saved.profile.birthTime, BirthProfile.defaultUnknownTime);
    });

    test('a birth time is stored to the minute', () async {
      // 11:39 was a real profile that exposed a formatting bug once already.
      await store.add(profile('Precise', minutes: 11 * 60 + 39));

      final saved = await store.selected();
      expect(saved!.profile.birthTime, const Duration(hours: 11, minutes: 39));
    });

    test('a missing district translation stays missing', () async {
      // districtLabel() falls back to English on screen, which is right there
      // and wrong here: persisting the fallback would record "the Sinhala for
      // Kalutara is Kalutara" permanently, and no later data fix would find
      // it.
      await store.add(profile('Older build', place: older));

      final saved = await store.selected();
      expect(saved!.profile.place.districtSiOrNull, isNull);
      expect(saved.profile.place.districtTaOrNull, isNull);
    });

    test('profiles come back oldest first', () async {
      // Added back to back, so several land in the same millisecond. Ordering
      // by time alone leaves SQLite free to return them in any order, and a
      // list that reshuffles between launches looks broken — the id is the
      // tiebreak.
      for (var i = 0; i < 6; i++) {
        await store.add(profile('P$i'));
      }

      final once = (await store.all()).map((s) => s.profile.name).toList();
      expect(once, ['P0', 'P1', 'P2', 'P3', 'P4', 'P5']);

      final again = (await store.all()).map((s) => s.profile.name).toList();
      expect(again, once, reason: 'the order must not change between reads');
    });
  });

  group('which profile is selected', () {
    test('the first one is selected without being asked', () async {
      // A stored profile nobody is looking at is the same as no profile: the
      // home screen would wait for one forever.
      await store.add(profile('Only'));

      expect((await store.selected())?.profile.name, 'Only');
    });

    test('a second profile does not steal the selection', () async {
      await store.add(profile('First'));
      await store.add(profile('Second'));

      expect((await store.selected())?.profile.name, 'First');
    });

    test('unless it asks to', () async {
      await store.add(profile('First'));
      await store.add(profile('Second'), select: true);

      expect((await store.selected())?.profile.name, 'Second');
    });

    test('exactly one is ever selected', () async {
      // Two selected makes "whose chart is this" unanswerable, and none makes
      // the app look like it has no profile at all.
      final first = await store.add(profile('First'));
      await store.add(profile('Second'));
      await store.add(profile('Third'), select: true);
      await store.select(first);

      final all = await store.all();
      final selected = await db.select(db.profiles).get();
      expect(selected.where((r) => r.isSelected), hasLength(1));
      expect(all, hasLength(3));
      expect((await store.selected())?.profile.name, 'First');
    });

    test(
      'updating a profile keeps its selection and its place in order',
      () async {
        final id = await store.add(profile('Before'));
        await store.add(profile('Other'));

        await store.update(id, profile('After'));

        final all = await store.all();
        expect(all.first.profile.name, 'After', reason: 'still oldest');
        expect((await store.selected())?.id, id);
      },
    );

    test('updating an id that is gone does nothing', () async {
      await store.add(profile('Kept'));
      await store.update(9999, profile('Ghost'));

      final all = await store.all();
      expect(all, hasLength(1));
      expect(all.single.profile.name, 'Kept');
    });
  });

  group('deleting', () {
    test('the selected profile hands over to the oldest survivor', () async {
      final first = await store.add(profile('First'));
      await store.add(profile('Second'));
      await store.add(profile('Third'));

      await store.delete(first);

      expect((await store.selected())?.profile.name, 'Second');
    });

    test('a profile nobody is looking at leaves the selection alone', () async {
      await store.add(profile('First'));
      final second = await store.add(profile('Second'));

      await store.delete(second);

      expect((await store.selected())?.profile.name, 'First');
    });

    test('the last one leaves nothing selected', () async {
      final only = await store.add(profile('Only'));
      await store.delete(only);

      expect(await store.selected(), isNull);
      expect(await store.all(), isEmpty);
    });
  });

  group('migrating off SharedPreferences', () {
    test('brings the saved profile across and selects it', () async {
      final legacy = profile('Existing user');

      expect(await store.migrateFromPrefs(legacy), isTrue);

      final saved = await store.selected();
      expect(shape(saved!.profile), shape(legacy));
    });

    test('running twice does not duplicate anyone', () async {
      // Idempotent by checking the table rather than by writing a "migrated"
      // flag — a flag can be set while the insert that followed it failed,
      // and the cost of that is someone's birth details.
      final legacy = profile('Existing user');

      expect(await store.migrateFromPrefs(legacy), isTrue);
      expect(await store.migrateFromPrefs(legacy), isFalse);

      expect(await store.all(), hasLength(1));
    });

    test('never overwrites profiles that are already there', () async {
      // The dangerous case: an old preferences value still on disk after the
      // user has moved on. It must not clobber what they have now.
      await store.add(profile('Current'));

      expect(await store.migrateFromPrefs(profile('Stale')), isFalse);

      final all = await store.all();
      expect(all, hasLength(1));
      expect(all.single.profile.name, 'Current');
    });

    test('a fresh install with nothing to migrate is a no-op', () async {
      expect(await store.migrateFromPrefs(null), isFalse);
      expect(await store.all(), isEmpty);
    });
  });
}
