import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nakshatra/core/astro/ephemeris.dart';
import 'package:nakshatra/core/config/flavor.dart';
import 'package:nakshatra/features/home/domain/daily_providers.dart';
import 'package:nakshatra/features/home/presentation/home_screen.dart';
import 'package:nakshatra/features/onboarding/data/profile_repository.dart';
import 'package:nakshatra/features/onboarding/domain/birth_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

/// The daily home screen against the real almanac engine (KAN-27).
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
  late ProviderContainer container;

  setUpAll(() async {
    FlavorConfig.initialize(Flavor.dev);
    await Ephemeris.initialize();
    tzdata.initializeTimeZones();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> pumpHome(WidgetTester tester) async {
    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    await container.read(profileProvider.notifier).save(profile);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('rahu kalaya is the headline, above the fold', (tester) async {
    await pumpHome(tester);

    // This is what the app is opened for, so it must be visible without
    // scrolling — not buried under a horoscope.
    expect(find.text('රාහු කාලය'), findsOneWidget);
    expect(find.text('Rāhu kālaya'), findsOneWidget);
    expect(find.textContaining('minutes'), findsWidgets);
  });

  testWidgets('the panchanga strip shows all five limbs', (tester) async {
    await pumpHome(tester);

    for (final label in ['Vāra', 'Tithi', 'Nakṣatra', 'Yoga', 'Karana']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('sunrise, sunset and moonrise are shown', (tester) async {
    await pumpHome(tester);
    expect(find.text('Sunrise'), findsOneWidget);
    expect(find.text('Sunset'), findsOneWidget);
    expect(find.text('Moonrise'), findsOneWidget);
  });

  testWidgets('the other two inauspicious periods are listed', (tester) async {
    await pumpHome(tester);
    await tester.scrollUntilVisible(
      find.text('Other inauspicious periods'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Yamaganda'), findsOneWidget);
    expect(find.text('Gulika kālaya'), findsOneWidget);
  });

  testWidgets('clear times are offered, not just warnings', (tester) async {
    await pumpHome(tester);
    await tester.scrollUntilVisible(
      find.text('Clear times today'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Clear times today'), findsOneWidget);
  });

  group('date switching', () {
    testWidgets('moves forward and back a day', (tester) async {
      await pumpHome(tester);
      final start = container.read(selectedDateProvider);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      expect(
        container.read(selectedDateProvider),
        start.add(const Duration(days: 1)),
      );

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      expect(container.read(selectedDateProvider), start);
    });

    testWidgets('a Today button appears only when away from today', (
      tester,
    ) async {
      await pumpHome(tester);
      expect(find.text('Today'), findsNothing);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      expect(find.text('Today'), findsOneWidget);

      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();
      expect(find.text('Today'), findsNothing);
    });

    testWidgets('the almanac actually changes with the date', (tester) async {
      await pumpHome(tester);
      final before = container.read(panchangaProvider)!;

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
      final after = container.read(panchangaProvider)!;

      // A different day has a different sunrise and a different vara.
      expect(after.sunrise, isNot(before.sunrise));
      expect(after.vara, isNot(before.vara));
    });
  });

  testWidgets('the "now" banner only appears while viewing today', (
    tester,
  ) async {
    await pumpHome(tester);

    // Whether a period is running right now depends on the clock, so assert
    // the invariant rather than a fixed outcome: on any other day it must be
    // absent, because "right now" is meaningless there.
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    expect(container.read(currentlyInauspiciousProvider), isNull);
  });

  testWidgets('unbuilt sections are declared, not faked', (tester) async {
    await pumpHome(tester);
    // Scroll to the very bottom: the disclaimer sits below "Still to come",
    // and a ListView has not built what it has not reached.
    await tester.scrollUntilVisible(
      find.textContaining('entertainment purposes'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    // Inventing a horoscope would undermine the accuracy the rest of the app
    // is built on, so the gap is stated instead.
    expect(find.text('Still to come'), findsOneWidget);
    expect(find.textContaining('entertainment purposes'), findsOneWidget);
  });
}
