import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

  testWidgets('a first launch lands in onboarding', (tester) async {
    await pumpApp(tester);

    // With no saved profile there is nothing to show, so every route must
    // redirect here rather than rendering an empty chart.
    expect(find.text('Choose your language'), findsOneWidget);
  });

  testWidgets('the language step offers all three languages', (tester) async {
    await pumpApp(tester);

    // Each language is listed in its own script — a Tamil speaker looks for
    // "தமிழ்", not "Tamil".
    expect(find.text('සිංහල'), findsOneWidget);
    expect(find.text('தமிழ்'), findsOneWidget);
    expect(find.text('English'), findsWidgets);
  });

  testWidgets('the flow advances from language to name', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('What is your name?'), findsOneWidget);
  });

  testWidgets('Continue is disabled until a name is entered', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull, reason: 'no name yet');

    await tester.enterText(find.byType(TextField), 'Chamod');
    await tester.pumpAndSettle();

    final enabled = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(enabled.onPressed, isNotNull);
  });
}
