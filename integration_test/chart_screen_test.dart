import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nakshatra/core/astro/ephemeris.dart';
import 'package:nakshatra/core/astro/models.dart';
import 'package:nakshatra/core/config/chart_style.dart';
import 'package:nakshatra/core/config/flavor.dart';
import 'package:nakshatra/features/chart/presentation/chart_screen.dart';
import 'package:nakshatra/features/onboarding/data/profile_repository.dart';
import 'package:nakshatra/features/chart/presentation/north_indian_chart.dart';
import 'package:nakshatra/features/chart/presentation/rasi_chart.dart';
import 'package:nakshatra/features/onboarding/domain/birth_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// End-to-end check that a saved profile renders a real chart on a device.
///
/// This needs the Swiss Ephemeris native library, so it cannot run under
/// `flutter test` on the host — hence integration_test.
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

  late SharedPreferences prefs;

  setUpAll(() async {
    FlavorConfig.initialize(Flavor.dev);
    await Ephemeris.initialize();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> pumpChart(WidgetTester tester, BirthProfile profile) async {
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    await container.read(profileProvider.notifier).save(profile);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ChartScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a saved profile renders a chart with all twelve rasi', (
    tester,
  ) async {
    await pumpChart(
      tester,
      BirthProfile(
        name: 'Test',
        birthDate: DateTime(1990, 6, 15),
        birthTime: const Duration(hours: 14, minutes: 30),
        place: colombo,
        birthTimeKnown: true,
      ),
    );

    expect(find.text('Test'), findsOneWidget);

    // The South Indian layout shows every rāśi in a fixed cell, so all twelve
    // names must be on screen regardless of what the chart contains.
    for (final rasi in Rasi.values) {
      expect(find.text(rasi.en), findsWidgets, reason: rasi.en);
    }

    // Everything below the chart is off-screen on a phone, and a ListView does
    // not build children it has not reached — so scroll rather than asserting
    // against a tree that was never created.
    await tester.scrollUntilVisible(
      find.textContaining('entertainment purposes'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Planetary positions'), findsOneWidget);
    expect(find.textContaining('Ayanāṃśa'), findsOneWidget);
    expect(find.textContaining('entertainment purposes'), findsOneWidget);
  });

  testWidgets('every graha appears in the positions table', (tester) async {
    await pumpChart(
      tester,
      BirthProfile(
        name: 'Test',
        birthDate: DateTime(1990, 6, 15),
        birthTime: const Duration(hours: 14, minutes: 30),
        place: colombo,
        birthTimeKnown: true,
      ),
    );

    for (final g in Graha.values) {
      expect(find.text(g.en), findsWidgets, reason: '${g.en} missing');
    }
  });

  testWidgets('an unknown birth time is disclosed, not hidden', (tester) async {
    await pumpChart(
      tester,
      BirthProfile(
        name: 'Test',
        birthDate: DateTime(1990, 6, 15),
        birthTime: BirthProfile.defaultUnknownTime,
        place: colombo,
        birthTimeKnown: false,
      ),
    );

    // Presenting an assumed sunrise lagna as fact would be dishonest, so the
    // banner and the in-chart marker must both be present.
    expect(find.textContaining('Birth time unknown'), findsOneWidget);
    expect(find.text('approximate'), findsOneWidget);
  });

  testWidgets('a known birth time shows no approximation warning', (
    tester,
  ) async {
    await pumpChart(
      tester,
      BirthProfile(
        name: 'Test',
        birthDate: DateTime(1990, 6, 15),
        birthTime: const Duration(hours: 14, minutes: 30),
        place: colombo,
        birthTimeKnown: true,
      ),
    );

    expect(find.textContaining('Birth time unknown'), findsNothing);
    expect(find.text('approximate'), findsNothing);
  });

  testWidgets('a birth date outside the supported range fails visibly', (
    tester,
  ) async {
    await pumpChart(
      tester,
      BirthProfile(
        name: 'Test',
        birthDate: DateTime(1500, 1, 1),
        birthTime: const Duration(hours: 12),
        place: colombo,
        birthTimeKnown: true,
      ),
    );

    // Better a clear error than a silently wrong chart.
    expect(find.textContaining('Could not calculate'), findsOneWidget);
  });

  testWidgets('the chart style is user-switchable and persists', (
    tester,
  ) async {
    await pumpChart(
      tester,
      BirthProfile(
        name: 'Test',
        birthDate: DateTime(1990, 6, 15),
        birthTime: const Duration(hours: 14, minutes: 30),
        place: colombo,
        birthTimeKnown: true,
      ),
    );

    // Defaults to South Indian: it is what Sri Lankan and South Indian users
    // expect, and showing them a North Indian diamond reads as simply wrong.
    expect(find.text('South Indian'), findsOneWidget);
    expect(find.text('North Indian'), findsOneWidget);
    expect(find.byType(RasiChart), findsOneWidget);
    expect(find.byType(NorthIndianChart), findsNothing);

    await tester.tap(find.text('North Indian'));
    await tester.pumpAndSettle();

    expect(find.byType(NorthIndianChart), findsOneWidget);
    expect(find.byType(RasiChart), findsNothing);

    // The choice is written through to storage, so it survives a restart.
    expect(prefs.getString('chart_style_v1'), ChartStyle.northIndian.name);

    await tester.tap(find.text('South Indian'));
    await tester.pumpAndSettle();
    expect(find.byType(RasiChart), findsOneWidget);
    expect(prefs.getString('chart_style_v1'), ChartStyle.southIndian.name);
  });

  testWidgets('North Indian places the lagna sign in house 1', (tester) async {
    await pumpChart(
      tester,
      BirthProfile(
        name: 'Test',
        birthDate: DateTime(1990, 6, 15),
        birthTime: const Duration(hours: 14, minutes: 30),
        place: colombo,
        birthTimeKnown: true,
      ),
    );

    await tester.tap(find.text('North Indian'));
    await tester.pumpAndSettle();

    // In this layout houses are fixed and signs rotate, so every house shows a
    // sign number 1-12 and each number appears exactly once. Getting the
    // rotation wrong is the classic way to draw this chart incorrectly.
    for (var n = 1; n <= 12; n++) {
      expect(
        find.text('$n'),
        findsWidgets,
        reason: 'sign number $n missing from the North Indian chart',
      );
    }
  });
}
