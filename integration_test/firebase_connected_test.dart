import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nakshatra/core/sync/firebase_service.dart';
import 'package:nakshatra/core/sync/profile_sync.dart';
import 'package:nakshatra/features/onboarding/domain/birth_profile.dart';

/// Firebase against the real backend (KAN-47).
///
/// Needs `android/app/google-services.json` and a network connection, so this
/// runs on a device and never in CI. The mirror-image case — Firebase entirely
/// unconfigured — is covered in test/core/sync/firebase_degradation_test.dart.
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

  setUpAll(() async {
    await FirebaseService.initialize();
  });

  test('Firebase initialises and signs in anonymously', () {
    expect(
      FirebaseService.isAvailable,
      isTrue,
      // Without this the failure is a bare `false`, which says nothing about
      // whether the console is misconfigured or the phone is simply offline.
      reason:
          'Firebase did not come up: ${FirebaseService.lastError}. '
          'network-request-failed means this device has no connection, not '
          'that anything is misconfigured. Otherwise check '
          'android/app/google-services.json and that Anonymous sign-in is '
          'enabled in the Firebase console.',
    );
    expect(FirebaseService.uid, isNotNull);
    expect(FirebaseService.currentUser!.isAnonymous, isTrue);
  });

  test('the uid is stable across calls', () {
    // A new anonymous account per launch would orphan every previous backup.
    final first = FirebaseService.uid;
    expect(FirebaseService.uid, first);
  });

  test('a profile round-trips through Firestore', () async {
    final sync = ProfileSync(FirebaseFirestore.instance);

    final profile = BirthProfile(
      name: 'RoundTrip',
      birthDate: DateTime(1990, 6, 15),
      birthTime: const Duration(hours: 14, minutes: 30),
      place: colombo,
      birthTimeKnown: true,
    );

    await sync.push(profile);

    final restored = await sync.pull();
    expect(restored, isNotNull, reason: 'nothing came back from Firestore');
    expect(restored!.name, 'RoundTrip');
    expect(restored.birthDate, profile.birthDate);
    expect(restored.birthTime, profile.birthTime);
    expect(restored.birthTimeKnown, isTrue);
    expect(restored.place.en, 'Colombo');
    expect(restored.place.latitude, closeTo(colombo.latitude, 1e-9));

    // Leave the account clean so a later run starts from nothing.
    await sync.clear();
    expect(await sync.pull(), isNull);
  });
}
