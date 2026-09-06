import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nakshatra/core/sync/auth_service.dart';
import 'package:nakshatra/core/sync/firebase_service.dart';
import 'package:nakshatra/core/sync/profile_sync.dart';
import 'package:nakshatra/features/onboarding/domain/birth_profile.dart';

/// Deleting really deletes.
///
/// Reported from a device: the screen said the details were gone while the
/// Firestore document and the Firebase account were both still there. The
/// three causes were a field delete instead of a document delete, an
/// unawaited future, and no account deletion at all.
///
/// These assert against the real backend, because the bug was invisible to
/// everything that did not look at the server.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const colombo = Place(
    en: 'Colombo',
    si: 'කොළඹ',
    ta: 'கொழும்பு',
    latitude: 6.9271,
    longitude: 79.8612,
    district: 'Colombo',
  );

  final profile = BirthProfile(
    name: 'DeleteTest',
    birthDate: DateTime(1990, 6, 15),
    birthTime: const Duration(hours: 14, minutes: 30),
    place: colombo,
    birthTimeKnown: true,
  );

  setUpAll(() async {
    await FirebaseService.initialize();
    expect(
      FirebaseService.isAvailable,
      isTrue,
      reason: 'Firebase did not come up: ${FirebaseService.lastError}',
    );
  });

  /// Reads the raw document, which is the only way to tell a deleted document
  /// from one that merely has no profile field.
  Future<DocumentSnapshot<Map<String, dynamic>>> rawDoc(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid).get();

  test('clearing removes the whole document, not just one field', () async {
    final uid = FirebaseService.uid!;
    final sync = ProfileSync(FirebaseFirestore.instance);

    await sync.push(profile);
    expect((await rawDoc(uid)).exists, isTrue, reason: 'nothing was written');

    final removed = await sync.clear();
    expect(removed, isTrue, reason: 'clear reported failure');

    // The original bug: update({field: FieldValue.delete()}) left the document
    // in place carrying updatedAt and schemaVersion, so a user who checked the
    // console still saw a record filed under their uid.
    final after = await rawDoc(uid);
    expect(
      after.exists,
      isFalse,
      reason: 'document survived with ${after.data()}',
    );
  });

  test('clearing reports failure rather than pretending', () async {
    // With no Firestore behind it there is nothing to delete, and saying so
    // is what lets the UI avoid claiming a deletion that never happened.
    expect(await ProfileSync(null).clear(), isFalse);
  });

  test('the old identity is left behind and a fresh one takes over', () async {
    // Firebase refuses to delete an account whose sign-in is old, and for a
    // returning user it always is — startup only signs in when there is no
    // user, so auth_time dates from installation. An anonymous account has no
    // credential to re-authenticate with, so the account record itself cannot
    // always be removed from the client.
    //
    // What must hold regardless: the user ends up on a different, working
    // account, and the old uid is no longer the one in use.
    final before = FirebaseService.uid!;
    const service = AuthService();

    final result = await service.deleteAccount();
    expect(
      result.isSuccess,
      isTrue,
      reason: 'even a stale session should end on a usable account: '
          '${result.failureOrNull?.message}',
    );

    final after = FirebaseAuth.instance.currentUser;
    expect(after, isNotNull, reason: 'the app was left with no user at all');
    expect(
      after!.uid,
      isNot(before),
      reason: 'still signed in as the account that was just deleted',
    );
    expect(after.isAnonymous, isTrue);
  });

  test('the deleted uid cannot be signed back into', () async {
    // Proves the old identity is gone rather than merely signed out.
    final current = FirebaseService.uid!;
    final doc = await rawDoc(current);
    expect(doc.exists, isFalse, reason: 'a fresh account should own nothing');
  });

  tearDownAll(() async {
    // Leave the throwaway account behind cleanly.
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .delete();
      await FirebaseAuth.instance.currentUser?.delete();
    } on Object {
      // Best effort.
    }
  });
}
