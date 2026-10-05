import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/ui/brand_button.dart';
import 'package:nakshatra/app.dart';
import 'package:nakshatra/core/config/flavor.dart';
import 'package:nakshatra/features/onboarding/data/profile_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Boot tests.
///
/// These exercise onboarding only. Anything past it renders a computed chart,
/// which needs the Swiss Ephemeris native library — unavailable under
/// `flutter test` on the host, so chart rendering is covered in
/// integration_test/ instead.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    FlavorConfig.initialize(Flavor.dev);
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const NakshatraApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Lets the launch scenes finish. They play over the first screen and
  /// block taps until they fade, as on a phone.
  Future<void> pastLaunch(WidgetTester tester) async {
    await tester.pumpAndSettle();
  }

  /// The intro slides animate continuously (an orbit, a pulse), so they never
  /// settle; step through them with fixed pumps instead.
  Future<void> pumpSlide(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('a first launch lands on the language choice', (tester) async {
    await pumpApp(tester);
    await pastLaunch(tester);

    // With no saved profile there is nothing to show, so every route must
    // redirect to the welcome — and the welcome opens on the language, so
    // everything after it is read in the right script (KAN-81).
    expect(find.text('Choose your language'), findsOneWidget);
  });

  testWidgets('the language choice offers all three languages', (tester) async {
    await pumpApp(tester);
    await pastLaunch(tester);

    // Each language is listed in its own script — a Tamil speaker looks for
    // "தமிழ்", not "Tamil".
    expect(find.text('සිංහල'), findsOneWidget);
    expect(find.text('தமிழ்'), findsOneWidget);
    expect(find.text('English'), findsWidgets);
  });

  testWidgets('language leads to the intro, and skipping it to the name', (
    tester,
  ) async {
    await pumpApp(tester);
    await pastLaunch(tester);

    await tester.tap(find.text('Continue'));
    await pumpSlide(tester);
    expect(find.text('Worked out here, not looked up'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('What is your name?'), findsOneWidget);
  });

  testWidgets('Continue is disabled until a name is entered', (tester) async {
    await pumpApp(tester);
    await pastLaunch(tester);
    await tester.tap(find.text('Continue'));
    await pumpSlide(tester);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    final button = tester.widget<BrandButton>(find.byType(BrandButton));
    expect(button.onPressed, isNull, reason: 'no name yet');

    await tester.enterText(find.byType(TextField), 'Chamod');
    await tester.pumpAndSettle();

    final enabled = tester.widget<BrandButton>(find.byType(BrandButton));
    expect(enabled.onPressed, isNotNull);
  });
}
