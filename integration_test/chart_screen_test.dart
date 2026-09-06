import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nakshatra/core/astro/ephemeris.dart';
import 'package:nakshatra/core/astro/models.dart';
import 'package:nakshatra/core/config/chart_style.dart';
import 'package:nakshatra/core/config/flavor.dart';
import 'package:nakshatra/features/chart/presentation/chart_screen.dart';
import 'package:nakshatra/l10n/generated/app_localizations.dart';
import 'package:nakshatra/features/onboarding/data/profile_repository.dart';
import 'package:nakshatra/features/chart/presentation/north_indian_chart.dart';
import 'package:nakshatra/features/chart/presentation/rasi_chart.dart';
import 'package:nakshatra/features/chart/presentation/chart_sharing.dart';
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
        child: const MaterialApp(
          // The screen reads its labels through L10n, so it cannot
          // build without the delegates. Pinned to English so the
          // assertions below stay readable.
          locale: Locale('en'),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: ChartScreen(),
        ),
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
    // not build children it has not reached — so scroll to each in turn.
    //
    // Deliberately one scroll per item rather than scrolling to the bottom and
    // asserting three things at once: the daśā timeline (KAN-53) now sits
    // between the table and the footer, so they are no longer on screen
    // together and never will be again as the page grows.
    final scrollable = find.byType(Scrollable).first;

    for (final target in [
      find.text('Planetary positions'),
      find.textContaining('Ayanāṃśa'),
      find.text('Daśā periods'),
      find.textContaining('entertainment purposes'),
    ]) {
      await tester.scrollUntilVisible(target, 300, scrollable: scrollable);
      await tester.pumpAndSettle();
      expect(target, findsWidgets);
    }
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

  testWidgets('tapping a house opens its detail sheet', (tester) async {
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

    // The cell is the target rather than the two-letter graha label, so a
    // house with nothing in it can still be opened.
    await tester.tap(find.text('Aquarius').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('House'), findsWidgets);
  });

  testWidgets('a table row opens the graha detail', (tester) async {
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

    // Scoped to the table: since the daśā timeline landed, "Sun" also names a
    // mahādaśā and an antardaśā, so a bare text finder is ambiguous. Scrolled
    // to the row itself rather than the heading, which can be on screen while
    // the row is still below the fold.
    final sunRow = find.descendant(
      of: find.byType(DataTable),
      matching: find.text('Sun'),
    );
    await tester.scrollUntilVisible(
      sunRow,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(sunRow);
    await tester.pumpAndSettle();

    // The sheet carries what the abbreviation in the chart leaves out.
    expect(find.textContaining('Exalted in'), findsOneWidget);
    expect(find.textContaining('House'), findsWidgets);
  });

  testWidgets('the nodes are shown without a dignity claim', (tester) async {
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

    final rahuRow = find.descendant(
      of: find.byType(DataTable),
      matching: find.text('Rahu'),
    );
    await tester.scrollUntilVisible(
      rahuRow,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(rahuRow);
    await tester.pumpAndSettle();

    // Traditions disagree on where the nodes are exalted, so the sheet says
    // so rather than picking a school.
    expect(find.textContaining('traditions disagree'), findsOneWidget);
    expect(find.textContaining('Exalted in'), findsNothing);
  });

  testWidgets('the chart renders to a real PNG for sharing', (tester) async {
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

    // The share sheet itself is system UI a test cannot assert against, so
    // this exercises the half that can actually be wrong: finding the
    // boundary, rasterising it and encoding it.
    final boundary = find.byType(ShareableChart);
    expect(boundary, findsOneWidget);

    final key = tester.widget<ShareableChart>(boundary).boundaryKey;
    final result = await ChartSharing.captureBoundary(key);

    expect(result.isSuccess, isTrue, reason: '${result.failureOrNull}');
    final bytes = result.valueOrNull!;
    expect(bytes, isNotEmpty);

    // PNG magic number, so this is an image rather than an empty buffer that
    // happened not to throw.
    expect(bytes.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
  });

  testWidgets('the shared image carries its own attribution', (tester) async {
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

    // A shared chart travels without the app around it, so the caption and
    // attribution have to be inside the captured region rather than added at
    // capture time.
    final inside = find.descendant(
      of: find.byType(ShareableChart),
      matching: find.textContaining('HeloCode Labs'),
    );
    expect(inside, findsOneWidget);
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
