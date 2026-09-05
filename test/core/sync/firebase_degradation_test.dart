import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/app.dart';
import 'package:nakshatra/core/config/flavor.dart';
import 'package:nakshatra/core/sync/firebase_service.dart';
import 'package:nakshatra/core/sync/profile_sync.dart';
import 'package:nakshatra/features/onboarding/data/profile_repository.dart';
import 'package:nakshatra/features/onboarding/domain/birth_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Firebase must never be load-bearing.
///
/// These run with Firebase entirely unconfigured — which is the normal state of
/// a fresh clone and of CI — and assert the app is unaffected. Sync is a
/// backup, not a dependency: someone with no signal must get the same app as
/// someone in Colombo.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const colombo = Place(
    en: 'Colombo',
    si: 'කොළඹ',
    ta: 'கொழும்பு',
    latitude: 6.9271,
    longitude: 79.8612,
    district: 'Colombo',
  );

  final profile = BirthProfile(
    name: 'Test',
    birthDate: DateTime(1990, 6, 15),
    birthTime: const Duration(hours: 14, minutes: 30),
    place: colombo,
    birthTimeKnown: true,
  );

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    FlavorConfig.initialize(Flavor.dev);
    FirebaseService.resetForTesting();
  });

  ProviderContainer makeContainer() {
    final c = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('Firebase reports unavailable when unconfigured', () {
    expect(FirebaseService.isAvailable, isFalse);
    expect(FirebaseService.uid, isNull);
    expect(FirebaseService.currentUser, isNull);
  });

  test('initialize never throws, even with no configuration', () async {
    // A crash here would take the whole launch down.
    await expectLater(FirebaseService.initialize(), completes);
    expect(FirebaseService.isAvailable, isFalse);
  });

  test('saving a profile still works with no Firebase', () async {
    final container = makeContainer();
    await container.read(profileProvider.notifier).save(profile);

    expect(container.read(profileProvider), isNotNull);
    expect(container.read(profileProvider)!.name, 'Test');

    // And it really reached local storage, which is the source of truth.
    expect(prefs.getString('birth_profile_v1'), isNotNull);
  });

  test('clearing a profile still works with no Firebase', () async {
    final container = makeContainer();
    await container.read(profileProvider.notifier).save(profile);
    await container.read(profileProvider.notifier).clear();

    expect(container.read(profileProvider), isNull);
    expect(prefs.getString('birth_profile_v1'), isNull);
  });

  group('ProfileSync with no backend', () {
    test('push is a silent no-op', () async {
      final container = makeContainer();
      await expectLater(
        container.read(profileSyncProvider).push(profile),
        completes,
      );
    });

    test('pull returns null rather than throwing', () async {
      final container = makeContainer();
      expect(await container.read(profileSyncProvider).pull(), isNull);
    });

    test('clear is a silent no-op', () async {
      final container = makeContainer();
      await expectLater(container.read(profileSyncProvider).clear(), completes);
    });
  });

  test('restoreFromBackup reports nothing recovered', () async {
    final container = makeContainer();
    expect(
      await container.read(profileProvider.notifier).restoreFromBackup(),
      isFalse,
    );
    expect(container.read(profileProvider), isNull);
  });

  test('restore never overwrites a profile this device already has', () async {
    // Local storage is the source of truth. A backup must not clobber it.
    final container = makeContainer();
    await container.read(profileProvider.notifier).save(profile);

    final recovered = await container
        .read(profileProvider.notifier)
        .restoreFromBackup();

    expect(recovered, isFalse, reason: 'a local profile already exists');
    expect(container.read(profileProvider)!.name, 'Test');
  });

  testWidgets('the app still boots into onboarding', (tester) async {
    final container = makeContainer();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const NakshatraApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Choose your language'), findsOneWidget);
  });
}
