import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Saved birth profiles (KAN-19).
///
/// One row per person. The app has always had exactly one, kept as JSON in
/// SharedPreferences; a table is what lets a family have several, which is the
/// Pro feature the epic is built around.
///
/// The place is stored flat rather than as a foreign key into the bundled
/// place list. That list ships with the app and can change between releases —
/// a town could be renamed, or corrected — and a saved birth place must not
/// change underneath someone because an asset was edited. These columns are a
/// copy of what the user chose on the day they chose it.
class Profiles extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  /// Midnight on the birth date, local time.
  DateTimeColumn get birthDate => dateTime()();

  /// Minutes after midnight, so it survives a timezone the phone did not have
  /// when it was saved. A DateTime here would carry an offset that is only
  /// correct on the device that wrote it.
  IntColumn get birthTimeMinutes => integer()();

  /// False when the user said they do not know. The lagna is then a
  /// convention rather than a computation, and every screen must say so.
  BoolColumn get birthTimeKnown =>
      boolean().withDefault(const Constant(true))();

  TextColumn get placeEn => text()();
  TextColumn get placeSi => text()();
  TextColumn get placeTa => text()();
  TextColumn get district => text()();
  TextColumn get districtSi => text().nullable()();
  TextColumn get districtTa => text().nullable()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  TextColumn get timezone => text()();

  /// Which profile the app is showing. Exactly one row is true; the store
  /// enforces it, because two would make "whose chart is this" unanswerable.
  BoolColumn get isSelected => boolean().withDefault(const Constant(false))();

  /// Oldest first, so a list keeps the order they were added in.
  DateTimeColumn get createdAt => dateTime()();
}

@DriftDatabase(tables: [Profiles])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'nakshatra'));

  /// Bumped whenever a column is added, removed or changed. Every step needs a
  /// case in [migration] — a birth date is not something a user can be asked
  /// to type again because a schema moved.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) async {
      // Off by default in SQLite, and this schema will grow foreign keys.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
