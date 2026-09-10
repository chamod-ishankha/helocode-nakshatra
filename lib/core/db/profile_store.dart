import 'package:drift/drift.dart';

import '../../features/onboarding/domain/birth_profile.dart';
import '../logging/app_logger.dart';
import 'app_database.dart';

/// A saved profile and the row id it lives at.
///
/// [BirthProfile] deliberately has no id — it is the astrological input, and
/// the compatibility screen builds one for a partner who is never saved. The
/// id belongs to storage, so it is paired on rather than pushed into the
/// model.
class SavedProfile {
  const SavedProfile({
    required this.id,
    required this.profile,
    this.isSelected = false,
  });

  final int id;
  final BirthProfile profile;

  /// Whether this is the one the app is currently showing.
  ///
  /// Carried on the row rather than worked out by the caller. A list screen
  /// that compared names would tick two rows for a father and son who share
  /// one, which is exactly the family this feature exists for.
  final bool isSelected;

  @override
  bool operator ==(Object other) =>
      other is SavedProfile &&
      other.id == id &&
      other.profile == profile &&
      other.isSelected == isSelected;

  @override
  int get hashCode => Object.hash(id, profile, isSelected);
}

/// Birth profiles, in SQLite (KAN-19).
///
/// ## Why there is a "selected" flag rather than a stored index
///
/// Exactly one row is selected, and this class is what keeps that true. An
/// index into a list breaks the moment a profile is deleted; a flag cannot
/// drift out of range. Every write that could change it does so in a
/// transaction, because "no profile is selected" and "two are" are both
/// states the rest of the app has no answer for.
class ProfileStore {
  ProfileStore(this._db);

  final AppDatabase _db;

  /// Every saved profile, oldest first.
  Future<List<SavedProfile>> all() async {
    // Ordered by id as well as time. Two profiles added in the same
    // millisecond — a restore, or a fast tester — would otherwise come back in
    // whatever order SQLite felt like, and a list that reshuffles itself
    // between launches looks broken.
    final rows =
        await (_db.select(_db.profiles)..orderBy([
              (p) => OrderingTerm(expression: p.createdAt),
              (p) => OrderingTerm(expression: p.id),
            ]))
            .get();
    return rows.map(_toSaved).toList();
  }

  /// The profile the app is showing, or null before onboarding.
  Future<SavedProfile?> selected() async {
    final row = await (_db.select(
      _db.profiles,
    )..where((p) => p.isSelected.equals(true))).getSingleOrNull();
    return row == null ? null : _toSaved(row);
  }

  /// Saves a new profile. The first one is selected automatically, because a
  /// stored profile nobody is looking at is the same as no profile.
  Future<int> add(BirthProfile profile, {bool select = false}) async {
    return _db.transaction(() async {
      final count = await _count();
      final selectThis = select || count == 0;

      if (selectThis) await _clearSelection();

      return _db
          .into(_db.profiles)
          .insert(_toCompanion(profile, isSelected: selectThis));
    });
  }

  /// Replaces one profile's details, keeping its id and its selection.
  Future<void> update(int id, BirthProfile profile) async {
    final existing = await (_db.select(
      _db.profiles,
    )..where((p) => p.id.equals(id))).getSingleOrNull();
    if (existing == null) return;

    await (_db.update(_db.profiles)..where((p) => p.id.equals(id))).write(
      _toCompanion(
        profile,
        isSelected: existing.isSelected,
        createdAt: existing.createdAt,
      ),
    );
  }

  Future<void> select(int id) async {
    await _db.transaction(() async {
      await _clearSelection();
      await (_db.update(_db.profiles)..where((p) => p.id.equals(id))).write(
        const ProfilesCompanion(isSelected: Value(true)),
      );
    });
  }

  /// Deletes one profile, handing the selection to the oldest survivor.
  ///
  /// Without that, deleting the selected profile leaves the app with rows it
  /// will not show and a home screen waiting forever for a profile.
  Future<void> delete(int id) async {
    await _db.transaction(() async {
      final wasSelected =
          (await (_db.select(
            _db.profiles,
          )..where((p) => p.id.equals(id))).getSingleOrNull())?.isSelected ??
          false;

      await (_db.delete(_db.profiles)..where((p) => p.id.equals(id))).go();
      if (!wasSelected) return;

      final next =
          await (_db.select(_db.profiles)
                ..orderBy([
                  (p) => OrderingTerm(expression: p.createdAt),
                  (p) => OrderingTerm(expression: p.id),
                ])
                ..limit(1))
              .getSingleOrNull();
      if (next == null) return;

      await (_db.update(_db.profiles)..where((p) => p.id.equals(next.id)))
          .write(const ProfilesCompanion(isSelected: Value(true)));
    });
  }

  /// Saves over the selected profile, or creates the first one.
  ///
  /// What "save my details" means while the app still shows one profile at a
  /// time: editing replaces the row rather than adding a second person called
  /// the same thing every time somebody corrects a birth time.
  Future<void> upsertSelected(BirthProfile profile) async {
    final current = await selected();
    if (current == null) {
      await add(profile, select: true);
    } else {
      await update(current.id, profile);
    }
  }

  Future<void> clear() => _db.delete(_db.profiles).go();

  /// Moves the single SharedPreferences profile into the table, once.
  ///
  /// Returns true if it did anything. Idempotent by checking the table rather
  /// than by writing a "migrated" flag: a flag can be set while the insert
  /// that followed it failed, and the cost of that is a user's birth details.
  ///
  /// The caller must **not** delete the preferences copy afterwards. It costs
  /// a few hundred bytes and is the only way back if this table is ever lost.
  Future<bool> migrateFromPrefs(BirthProfile? legacy) async {
    if (legacy == null) return false;
    if (await _count() > 0) return false;

    await add(legacy, select: true);
    AppLogger.info('Migrated the saved profile into the database');
    return true;
  }

  Future<int> _count() async {
    final count = _db.profiles.id.count();
    final row = await (_db.selectOnly(
      _db.profiles,
    )..addColumns([count])).getSingle();
    return row.read(count) ?? 0;
  }

  Future<void> _clearSelection() => _db
      .update(_db.profiles)
      .write(const ProfilesCompanion(isSelected: Value(false)));

  static SavedProfile _toSaved(Profile row) => SavedProfile(
    id: row.id,
    isSelected: row.isSelected,
    profile: BirthProfile(
      name: row.name,
      birthDate: row.birthDate,
      birthTime: Duration(minutes: row.birthTimeMinutes),
      birthTimeKnown: row.birthTimeKnown,
      place: Place(
        en: row.placeEn,
        si: row.placeSi,
        ta: row.placeTa,
        latitude: row.latitude,
        longitude: row.longitude,
        district: row.district,
        districtSi: row.districtSi,
        districtTa: row.districtTa,
        timezone: row.timezone,
      ),
    ),
  );

  static ProfilesCompanion _toCompanion(
    BirthProfile profile, {
    required bool isSelected,
    DateTime? createdAt,
  }) => ProfilesCompanion(
    name: Value(profile.name),
    birthDate: Value(profile.birthDate),
    birthTimeMinutes: Value(profile.birthTime.inMinutes),
    birthTimeKnown: Value(profile.birthTimeKnown),
    placeEn: Value(profile.place.en),
    placeSi: Value(profile.place.si),
    placeTa: Value(profile.place.ta),
    district: Value(profile.place.district),
    districtSi: Value(profile.place.districtSiOrNull),
    districtTa: Value(profile.place.districtTaOrNull),
    latitude: Value(profile.place.latitude),
    longitude: Value(profile.place.longitude),
    timezone: Value(profile.place.timezone),
    isSelected: Value(isSelected),
    createdAt: Value(createdAt ?? DateTime.now()),
  );
}
