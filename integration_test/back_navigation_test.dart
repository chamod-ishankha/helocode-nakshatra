import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nakshatra/app.dart';
import 'package:nakshatra/core/astro/ephemeris.dart';
import 'package:nakshatra/core/config/flavor.dart';
import 'package:nakshatra/features/onboarding/data/profile_repository.dart';
import 'package:nakshatra/features/onboarding/domain/birth_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

/// The Android back button, through the real router and the real screens.
///
/// Reported from a device: the header back arrow worked but the system back
/// button closed the app. `context.go` replaces the stack rather than pushing
/// onto it, so there was nothing to pop.
///
/// The host test in test/core/router/pop_or_home_test.dart covers the same
/// contract with stand-in routes, which means it would keep passing if a
/// screen went back to `go`. This is the one that would not.
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
    name: 'Test',
    birthDate: DateTime(1990, 6, 15),
    birthTime: const Duration(hours: 14, minutes: 30),
    place: colombo,
    birthTimeKnown: true,
  );

  late SharedPreferences prefs;

  setUpAll(() async {
    FlavorConfig.initialize(Flavor.dev);
    await Ephemeris.initialize();
    tzdata.initializeTimeZones();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  /// Boots the whole app, router included, on the home screen.
  Future<void> pumpApp(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    await container.read(profileProvider.notifier).save(profile);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const NakshatraApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nakshatra'), findsOneWidget, reason: 'should be home');
  }

  testWidgets('back from the chart returns home instead of closing the app', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.grid_on));
    await tester.pumpAndSettle();
    expect(find.text('Nakshatra'), findsNothing, reason: 'should be on chart');

    // False here means nothing handled the back, which on Android is the app
    // closing. That is the reported bug, exactly.
    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(
      handled,
      isTrue,
      reason: 'the system back button closed the app instead of going back',
    );
    expect(find.text('Nakshatra'), findsOneWidget);
  });

  testWidgets('back from the account screen returns home', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.account_circle_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Account'), findsOneWidget);

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();

    expect(find.text('Nakshatra'), findsOneWidget);
  });

  testWidgets('the header arrow and the system button agree', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byIcon(Icons.grid_on));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Nakshatra'), findsOneWidget);
  });

  testWidgets('back on home leaves the app, rather than trapping the user', (
    tester,
  ) async {
    await pumpApp(tester);

    // The mirror image of the bug: home is the root, so back there *should*
    // be unhandled and let Android close the app. Making every back handled
    // would leave no way out.
    expect(
      await tester.binding.handlePopRoute(),
      isFalse,
      reason: 'home is the root; back must not be swallowed',
    );
  });
}
