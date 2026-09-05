import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/config/flavor.dart';
import 'package:nakshatra/core/error/result.dart';
import 'package:nakshatra/core/sync/auth_service.dart';
import 'package:nakshatra/core/sync/firebase_service.dart';
import 'package:nakshatra/core/sync/profile_sync.dart';
import 'package:nakshatra/features/onboarding/data/profile_repository.dart';
import 'package:nakshatra/features/onboarding/domain/birth_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A stand-in for Firestore.
///
/// Reconciliation is the one place in the app where a wrong branch silently
/// destroys someone's birth details, and with no Firebase configured `pull`
/// always returns null — which would leave two of the four cases untested.
class _FakeSync implements ProfileSync {
  _FakeSync({this.remote});

  BirthProfile? remote;
  BirthProfile? pushed;
  int clears = 0;

  @override
  Future<BirthProfile?> pull() async => remote;

  @override
  Future<void> push(BirthProfile profile) async => pushed = profile;

  @override
  Future<void> clear() async => clears++;
}

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

  BirthProfile profileNamed(String name) => BirthProfile(
    name: name,
    birthDate: DateTime(1990, 6, 15),
    birthTime: const Duration(hours: 14, minutes: 30),
    place: colombo,
    birthTimeKnown: true,
  );

  final local = profileNamed('OnThisPhone');
  final account = profileNamed('OnTheAccount');

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    FlavorConfig.initialize(Flavor.dev);
    FirebaseService.resetForTesting();
  });

  ProviderContainer makeContainer({ProfileSync? sync}) {
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        if (sync != null) profileSyncProvider.overrideWithValue(sync),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('AccountStatus', () {
    test('no user is reported as none, not as anonymous', () {
      // These must not collapse together: "signed in anonymously" and "no
      // backend at all" need different words on the account screen.
      final status = AccountStatus.of(null);
      expect(status.kind, AccountKind.none);
      expect(status.isRecoverable, isFalse);
      expect(status.email, isNull);
    });
  });

  group('error messages', () {
    test('an address already in use reads as an offer, not a failure', () {
      final failure = AuthService.describe(
        FirebaseAuthException(code: 'email-already-in-use'),
      );
      expect(failure.code, 'email-already-in-use');
      expect(failure.message, contains('Sign in to it instead'));
    });

    test('every code the flow can hit has its own wording', () {
      const codes = [
        'invalid-email',
        'weak-password',
        'wrong-password',
        'invalid-credential',
        'user-not-found',
        'user-disabled',
        'too-many-requests',
        'network-request-failed',
        'operation-not-allowed',
      ];

      final messages = <String>{};
      for (final code in codes) {
        final failure = AuthService.describe(FirebaseAuthException(code: code));
        expect(failure.code, code);
        // No raw Firebase vocabulary should reach the user.
        expect(failure.message, isNot(contains('credential')));
        expect(failure.message, isNot(contains('FirebaseException')));
        messages.add(failure.message);
      }
      // Distinct enough to be worth the switch: a single generic string would
      // be no better than not mapping at all.
      expect(messages.length, greaterThan(5));
    });

    test('an unknown code still produces something sayable', () {
      final failure = AuthService.describe(
        FirebaseAuthException(code: 'some-code-added-in-a-future-sdk'),
      );
      expect(failure.message, isNotEmpty);
      expect(failure.message, isNot(contains('some-code')));
    });

    test('isEmailTaken covers all three ways Firebase says it', () {
      expect(AuthService.isEmailTaken('email-already-in-use'), isTrue);
      expect(AuthService.isEmailTaken('credential-already-in-use'), isTrue);
      expect(
        AuthService.isEmailTaken('account-exists-with-different-credential'),
        isTrue,
      );
      expect(AuthService.isEmailTaken('wrong-password'), isFalse);
    });
  });

  group('with no Firebase', () {
    test('status is none and the stream still emits', () async {
      const service = AuthService();
      expect(service.status.kind, AccountKind.none);
      expect((await service.changes.first).kind, AccountKind.none);
    });

    test('every operation fails softly rather than throwing', () async {
      const service = AuthService();

      for (final result in [
        await service.linkEmail('a@b.com', 'password'),
        await service.signInEmail('a@b.com', 'password'),
        await service.signOut(),
      ]) {
        expect(result.isSuccess, isFalse);
        expect(result.failureOrNull, isA<AuthFailure>());
        expect(result.failureOrNull!.message, isNotEmpty);
      }
    });

    test('signing in does not abandon anything when there is no account',
        () async {
      final sync = _FakeSync();
      const service = AuthService();

      await service.signInEmail('a@b.com', 'password', onAbandon: sync.clear);

      // Deleting the backup before we know a sign-in can even be attempted
      // would destroy it for nothing.
      expect(sync.clears, 0);
    });
  });

  group('Google when it is not set up', () {
    setUp(AuthService.resetGoogleForTesting);

    test('stays unavailable until the platform has actually been probed', () {
      // initializeGoogle has not run, so nothing is known about the platform.
      // Defaulting to available here would put a button on screen in unit
      // tests and on any host where the SDK never started.
      expect(AuthService.googleAvailable, isFalse);
    });

    test('both Google paths refuse before opening any chooser', () async {
      const service = AuthService();

      for (final result in [
        await service.linkGoogle(),
        await service.signInGoogle(),
      ]) {
        expect(result.isSuccess, isFalse);
        final failure = result.failureOrNull! as AuthFailure;
        // Not a generic error: the code is what the UI keys off to hide the
        // button rather than show a dead end.
        expect(failure.code, anyOf('google-unavailable', 'no-current-user',
            'no-firebase'));
        expect(failure.message, isNotEmpty);
      }
    });

    test('signing in does not abandon the backup when Google cannot run',
        () async {
      final sync = _FakeSync();
      const service = AuthService();

      await service.signInGoogle(onAbandon: sync.clear);

      // The chooser never opened, so there is nothing to abandon. Deleting
      // here would destroy a backup for an action that never happened.
      expect(sync.clears, 0);
    });
  });

  group('reconciling after signing in to another account', () {
    test('the account has nothing, so this phone fills it', () async {
      final sync = _FakeSync(remote: null);
      final container = makeContainer(sync: sync);
      final profiles = container.read(profileProvider.notifier);
      await profiles.save(local);

      expect(await profiles.reconcileAfterSignIn(), isNull);
      expect(sync.pushed?.name, 'OnThisPhone');
    });

    test('this phone has nothing, so the account fills it', () async {
      final sync = _FakeSync(remote: account);
      final container = makeContainer(sync: sync);
      final profiles = container.read(profileProvider.notifier);

      expect(await profiles.reconcileAfterSignIn(), isNull);
      expect(container.read(profileProvider)?.name, 'OnTheAccount');
    });

    test('identical copies are not a conflict', () async {
      // Signing in on a second device you already synced must not interrogate
      // the user about a choice that has no consequence.
      final sync = _FakeSync(remote: profileNamed('Same'));
      final container = makeContainer(sync: sync);
      final profiles = container.read(profileProvider.notifier);
      await profiles.save(profileNamed('Same'));

      expect(await profiles.reconcileAfterSignIn(), isNull);
    });

    test('two different profiles are returned rather than resolved', () async {
      final sync = _FakeSync(remote: account);
      final container = makeContainer(sync: sync);
      final profiles = container.read(profileProvider.notifier);
      await profiles.save(local);

      final conflict = await profiles.reconcileAfterSignIn();

      expect(conflict, isNotNull, reason: 'the user has to decide this one');
      expect(conflict!.name, 'OnTheAccount');
      // Nothing may change until they answer.
      expect(container.read(profileProvider)!.name, 'OnThisPhone');
    });

    test('a differing birth time counts as a conflict, not just the name',
        () async {
      final sync = _FakeSync(
        remote: local.copyWith(birthTime: const Duration(hours: 9)),
      );
      final container = makeContainer(sync: sync);
      final profiles = container.read(profileProvider.notifier);
      await profiles.save(local);

      // Two people can share a name; the chart is what actually differs.
      expect(await profiles.reconcileAfterSignIn(), isNotNull);
    });
  });

  group('applying the conflict decision', () {
    test('keeping the account copy overwrites this phone', () async {
      final sync = _FakeSync(remote: account);
      final container = makeContainer(sync: sync);
      final profiles = container.read(profileProvider.notifier);
      await profiles.save(local);

      await profiles.keepAccountProfile(account);

      expect(container.read(profileProvider)!.name, 'OnTheAccount');
      expect(prefs.getString('birth_profile_v1'), contains('OnTheAccount'));
    });

    test('keeping this phone pushes over the account', () async {
      final sync = _FakeSync(remote: account);
      final container = makeContainer(sync: sync);
      final profiles = container.read(profileProvider.notifier);
      await profiles.save(local);

      await profiles.keepDeviceProfile();

      expect(sync.pushed?.name, 'OnThisPhone');
      expect(container.read(profileProvider)!.name, 'OnThisPhone');
    });
  });
}
