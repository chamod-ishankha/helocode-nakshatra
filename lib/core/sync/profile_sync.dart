import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/onboarding/domain/birth_profile.dart';
import '../logging/app_logger.dart';
import 'firebase_service.dart';

/// Mirrors the saved birth profile to Firestore so it survives a reinstall.
///
/// ## What is stored
///
/// Only the birth profile: name, date, time, place. Nothing computed — charts
/// and nekath are derived on-device and would be pure waste to store, and
/// nothing about how the app is used.
///
/// ## What this is not
///
/// Not the source of truth. Local storage is, and the app reads from it. This
/// only pushes a copy up and pulls one back when the device has none — a
/// restore path, not a live database.
///
/// Every operation fails silently. A user with no network still gets a fully
/// working app; they just do not get a backup.
class ProfileSync {
  ProfileSync(this._firestore);

  final FirebaseFirestore? _firestore;

  static const String _collection = 'users';
  static const String _profileField = 'birthProfile';

  DocumentReference<Map<String, dynamic>>? get _doc {
    final uid = FirebaseService.uid;
    final db = _firestore;
    if (uid == null || db == null) return null;
    return db.collection(_collection).doc(uid);
  }

  /// Pushes [profile] to the user's document.
  ///
  /// `updatedAt` uses the server clock, not the device's, so a phone with a
  /// wrong date cannot win a last-write-wins comparison it should have lost.
  Future<void> push(BirthProfile profile) async {
    final doc = _doc;
    if (doc == null) return;

    try {
      await doc.set({
        _profileField: profile.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
        'schemaVersion': 1,
      }, SetOptions(merge: true));
      AppLogger.debug('Profile synced');
    } on Object catch (e, s) {
      // A failed backup must never surface as an error to the user: nothing
      // they can see is broken.
      AppLogger.warn('Profile sync failed', e, s);
    }
  }

  /// Fetches the stored profile, or null if there is none.
  Future<BirthProfile?> pull() async {
    final doc = _doc;
    if (doc == null) return null;

    try {
      final snapshot = await doc.get();
      final data = snapshot.data();
      final raw = data?[_profileField];
      if (raw is! Map) return null;

      return BirthProfile.fromJson(Map<String, dynamic>.from(raw));
    } on Object catch (e, s) {
      AppLogger.warn('Profile restore failed', e, s);
      return null;
    }
  }

  /// Removes the stored copy. Used when a user starts over.
  Future<void> clear() async {
    final doc = _doc;
    if (doc == null) return;
    try {
      await doc.update({_profileField: FieldValue.delete()});
    } on Object catch (e, s) {
      AppLogger.warn('Profile clear failed', e, s);
    }
  }
}

final profileSyncProvider = Provider<ProfileSync>(
  (ref) => ProfileSync(
    FirebaseService.isAvailable ? FirebaseFirestore.instance : null,
  ),
);
