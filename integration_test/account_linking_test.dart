import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nakshatra/core/error/result.dart';
import 'package:nakshatra/core/sync/auth_service.dart';
import 'package:nakshatra/core/sync/firebase_service.dart';
import 'package:nakshatra/core/sync/profile_sync.dart';
import 'package:nakshatra/features/onboarding/domain/birth_profile.dart';

/// Account linking against the real backend (KAN-48).
///
/// Runs on a device, never in CI. Needs Email/Password enabled under
/// Authentication → Sign-in method in the Firebase console; without it every
/// test here fails with `operation-not-allowed`.
///
/// Each run makes its own throwaway account and deletes it at the end, so
/// repeated runs neither collide nor accumulate users.
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
    name: 'LinkTest',
    birthDate: DateTime(1990, 6, 15),
    birthTime: const Duration(hours: 14, minutes: 30),
    place: colombo,
    birthTimeKnown: true,
  );

  const service = AuthService();

  // Unique per run. @example.com is never deliverable, which is exactly right
  // here: nothing is sent, and the product deliberately does not verify.
  final email =
      'kan48-${DateTime.now().microsecondsSinceEpoch}@example.com';
  const password = 'test-password-123';

  late String anonymousUid;

  setUpAll(() async {
    await FirebaseService.initialize();
    expect(
      FirebaseService.isAvailable,
      isTrue,
      reason: 'Firebase did not come up: ${FirebaseService.lastError}',
    );
    anonymousUid = FirebaseService.uid!;
  });

  tearDownAll(() async {
    // Leave no account behind, whatever happened above.
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .delete();
      await FirebaseAuth.instance.currentUser?.delete();
    } on Object {
      // Best effort. A leftover throwaway account is not worth failing on.
    }
  });

  test('linking keeps the uid, so the backup is not orphaned', () async {
    final sync = ProfileSync(FirebaseFirestore.instance);
    await sync.push(profile);

    final result = await service.linkEmail(email, password);

    expect(
      result.isSuccess,
      isTrue,
      reason: 'link failed: ${result.failureOrNull?.message} '
          '(enable Email/Password in the Firebase console if this says it is '
          'not enabled)',
    );

    // The whole point of linking rather than re-registering: same uid, so the
    // document written above is still the user's.
    expect(FirebaseService.uid, anonymousUid);

    final status = (result as Success<AccountStatus>).value;
    expect(status.kind, AccountKind.permanent);
    expect(status.isRecoverable, isTrue);
    expect(status.email, email);

    final restored = await sync.pull();
    expect(restored, isNotNull, reason: 'linking must not lose the backup');
    expect(restored!.name, 'LinkTest');
  });

  test('the account is not anonymous any more', () {
    final user = FirebaseAuth.instance.currentUser!;
    expect(user.isAnonymous, isFalse);
    expect(user.email, email);
    expect(
      user.providerData.map((p) => p.providerId),
      contains('password'),
    );
  });

  test('signing out returns to a working anonymous account', () async {
    final result = await service.signOut();

    expect(result.isSuccess, isTrue, reason: '${result.failureOrNull?.message}');
    expect(FirebaseService.uid, isNotNull);
    expect(FirebaseAuth.instance.currentUser!.isAnonymous, isTrue);
    // A fresh anonymous account, not the one we just left.
    expect(FirebaseAuth.instance.currentUser!.uid, isNot(anonymousUid));
  });

  test('signing back in returns the original account and its backup', () async {
    final result = await service.signInEmail(email, password);

    expect(result.isSuccess, isTrue, reason: '${result.failureOrNull?.message}');
    expect(
      FirebaseService.uid,
      anonymousUid,
      reason: 'signing in must land on the linked account, not a new one',
    );

    final restored = await ProfileSync(FirebaseFirestore.instance).pull();
    expect(restored?.name, 'LinkTest');
  });

  test('the wrong password is rejected with wording a user can act on',
      () async {
    final result = await service.signInEmail(email, 'not-the-password');

    expect(result.isSuccess, isFalse);
    final failure = result.failureOrNull;
    expect(failure, isA<AuthFailure>());
    expect((failure! as AuthFailure).message, isNot(contains('credential')));
  });

  test('the address cannot be taken twice', () async {
    // Prove the collision path the account screen depends on is real, rather
    // than trusting that Firebase reports it the way we assume.
    await service.signOut();
    final result = await service.linkEmail(email, password);

    expect(result.isSuccess, isFalse);
    final failure = result.failureOrNull! as AuthFailure;
    expect(
      AuthService.isEmailTaken(failure.code),
      isTrue,
      reason: 'got ${failure.code}, which the UI will not offer sign-in for',
    );
  });
}
