import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/db/app_database.dart';
import 'package:sqlite3/sqlite3.dart';

/// Schema 1 → 2, the migration that carries saved birth profiles into the
/// worldwide place list (KAN-66).
///
/// Worth its own test because the failure mode is losing someone's birth
/// details. A birth date and an exact birth time are not things a user can be
/// asked to type again because a schema moved, and most people do not know
/// their birth time to the minute without looking it up.
void main() {
  /// The v1 `profiles` table, exactly as shipped: `place_si` and `place_ta`
  /// NOT NULL, and no `country_code`.
  const createV1 = '''
    CREATE TABLE profiles (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      birth_date INTEGER NOT NULL,
      birth_time_minutes INTEGER NOT NULL,
      birth_time_known INTEGER NOT NULL DEFAULT 1 CHECK ("birth_time_known" IN (0, 1)),
      place_en TEXT NOT NULL,
      place_si TEXT NOT NULL,
      place_ta TEXT NOT NULL,
      district TEXT NOT NULL,
      district_si TEXT NULL,
      district_ta TEXT NULL,
      latitude REAL NOT NULL,
      longitude REAL NOT NULL,
      timezone TEXT NOT NULL,
      is_selected INTEGER NOT NULL DEFAULT 0 CHECK ("is_selected" IN (0, 1)),
      created_at INTEGER NOT NULL
    )
  ''';

  late AppDatabase db;

  /// Builds a v1 database holding one profile, then opens it at the current
  /// schema so the migration actually runs.
  ///
  /// The v1 schema is laid down through a raw sqlite3 handle rather than
  /// through drift. Drift opens lazily and would run `onCreate` at the current
  /// version on the first statement, which creates the table this is trying to
  /// pre-date — the upgrade would then never be exercised at all.
  Future<void> openUpgradedFromV1() async {
    final raw = sqlite3.openInMemory();
    raw.execute(createV1);
    raw.execute('''
      INSERT INTO profiles (
        name, birth_date, birth_time_minutes, birth_time_known,
        place_en, place_si, place_ta, district, district_si, district_ta,
        latitude, longitude, timezone, is_selected, created_at
      ) VALUES (
        'Chamod', 643939200, 870, 1,
        'Colombo', 'කොළඹ', 'கொழும்பு', 'Colombo', 'කොළඹ', 'கொழும்பு',
        6.9271, 79.8612, 'Asia/Colombo', 1, 643939200
      )
    ''');
    raw.userVersion = 1;

    db = AppDatabase(NativeDatabase.opened(raw));
  }

  tearDown(() async => db.close());

  test('a v1 profile survives the upgrade with every field intact', () async {
    await openUpgradedFromV1();

    final rows = await db.select(db.profiles).get();
    expect(rows, hasLength(1));

    final row = rows.single;
    expect(row.name, 'Chamod');
    expect(row.placeEn, 'Colombo');
    expect(row.placeSi, 'කොළඹ');
    expect(row.placeTa, 'கொழும்பு');
    expect(row.district, 'Colombo');
    expect(row.latitude, closeTo(6.9271, 1e-9));
    expect(row.longitude, closeTo(79.8612, 1e-9));
    expect(row.birthTimeMinutes, 870);
    expect(row.birthTimeKnown, isTrue);
    expect(row.isSelected, isTrue);

    // The chart depends on this one above all others.
    expect(row.timezone, 'Asia/Colombo');

    // Left null rather than stamped 'LK': "saved before countries existed" is
    // the truth, and "the user chose Sri Lanka" is not.
    expect(row.countryCode, isNull);
  });

  test('the upgraded schema accepts a place with no translation', () async {
    await openUpgradedFromV1();

    // The point of the migration: place_si and place_ta were NOT NULL, and
    // most of the world has neither. If the widening did not take, this throws.
    await db
        .into(db.profiles)
        .insert(
          ProfilesCompanion.insert(
            name: 'Partner',
            birthDate: DateTime.utc(1992, 3, 4),
            birthTimeMinutes: 400,
            placeEn: 'Melbourne',
            district: 'Melbourne',
            latitude: -37.814,
            longitude: 144.963,
            timezone: 'Australia/Melbourne',
            countryCode: const Value('AU'),
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        );

    final saved = await (db.select(
      db.profiles,
    )..where((p) => p.placeEn.equals('Melbourne'))).getSingle();

    expect(saved.placeSi, isNull);
    expect(saved.placeTa, isNull);
    expect(saved.countryCode, 'AU');
    expect(saved.timezone, 'Australia/Melbourne');
  });

  test('a fresh database starts at the current schema', () async {
    db = AppDatabase(NativeDatabase.memory());

    await db
        .into(db.profiles)
        .insert(
          ProfilesCompanion.insert(
            name: 'New',
            birthDate: DateTime.utc(2000, 1, 1),
            birthTimeMinutes: 0,
            placeEn: 'Tokyo',
            district: 'Tokyo',
            latitude: 35.689,
            longitude: 139.692,
            timezone: 'Asia/Tokyo',
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        );

    expect(await db.select(db.profiles).get(), hasLength(1));
  });
}
