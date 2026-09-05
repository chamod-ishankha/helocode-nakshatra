import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/config/flavor.dart';
import 'package:nakshatra/core/sync/auth_service.dart';
import 'package:nakshatra/core/sync/firebase_service.dart';
import 'package:nakshatra/features/account/presentation/account_screen.dart';
import 'package:nakshatra/l10n/generated/app_localizations.dart';
import 'package:nakshatra/features/onboarding/data/profile_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    FlavorConfig.initialize(Flavor.dev);
    FirebaseService.resetForTesting();
  });

  Future<void> pumpWith(WidgetTester tester, AccountStatus status) async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        accountStatusProvider.overrideWith((ref) => Stream.value(status)),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          // The screen reads every label through L10n, so without the
          // delegates it cannot build at all.
          locale: Locale('en'),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: AccountScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('no Google button until the provider is actually set up', (
    tester,
  ) async {
    AuthService.resetGoogleForTesting();
    await pumpWith(tester, const AccountStatus(kind: AccountKind.anonymous));

    // A button that can only fail is worse than no button at all.
    expect(find.text('Continue with Google'), findsNothing);
    // The email form must still be offered in its place.
    expect(find.text('Create account'), findsOneWidget);
  });

  testWidgets('an anonymous account is told its backup is at risk', (
    tester,
  ) async {
    await pumpWith(tester, const AccountStatus(kind: AccountKind.anonymous));

    expect(find.text('Saved to this phone only'), findsOneWidget);
    expect(find.textContaining('loses it for good'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });

  testWidgets('the missing-verification trade-off is stated before signing up',
      (tester) async {
    // A user cannot discover this until the day they need to recover, so it
    // has to be on screen at the moment they choose an address.
    await pumpWith(tester, const AccountStatus(kind: AccountKind.anonymous));

    expect(
      find.textContaining('cannot be recovered'),
      findsOneWidget,
      reason: 'the no-verification consequence must be visible up front',
    );
  });

  testWidgets('a signed-in account shows the email and offers sign out', (
    tester,
  ) async {
    await pumpWith(
      tester,
      const AccountStatus(kind: AccountKind.permanent, email: 'a@b.com'),
    );

    expect(find.text('Saved to a@b.com'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
    expect(find.text('Create account'), findsNothing);
  });

  testWidgets('with no backend the form is hidden rather than broken', (
    tester,
  ) async {
    await pumpWith(tester, const AccountStatus(kind: AccountKind.none));

    expect(find.text('Backup unavailable'), findsOneWidget);
    // Offering a form that cannot possibly work is worse than offering none.
    expect(find.text('Create account'), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('a short password is rejected before a round trip', (
    tester,
  ) async {
    await pumpWith(tester, const AccountStatus(kind: AccountKind.anonymous));

    await tester.enterText(find.byType(TextFormField).first, 'me@example.com');
    await tester.enterText(find.byType(TextFormField).last, 'abc');
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Use at least 6 characters'), findsOneWidget);
  });

  testWidgets('an address with no @ is rejected', (tester) async {
    await pumpWith(tester, const AccountStatus(kind: AccountKind.anonymous));

    await tester.enterText(find.byType(TextFormField).first, 'not-an-email');
    await tester.enterText(find.byType(TextFormField).last, 'longenough');
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(
      find.text('That does not look like an email address'),
      findsOneWidget,
    );
  });

  testWidgets('switching to sign-in drops the sign-up-only rules', (
    tester,
  ) async {
    await pumpWith(tester, const AccountStatus(kind: AccountKind.anonymous));

    await tester.tap(find.text('Already have an account? Sign in'));
    await tester.pumpAndSettle();

    // An existing password set before a rule changed must still be enterable,
    // so the length minimum applies to sign-up only.
    expect(find.text('Sign in'), findsWidgets);
    expect(find.textContaining('cannot be recovered'), findsNothing);
  });
}
