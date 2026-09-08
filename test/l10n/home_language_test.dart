import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nakshatra/core/ads/ad_gate.dart';
import 'package:nakshatra/core/astro/models.dart';
import 'package:nakshatra/core/astro/panchanga_models.dart';
import 'package:nakshatra/core/config/app_locale.dart';
import 'package:nakshatra/core/config/flavor.dart';
import 'package:nakshatra/core/sync/auth_service.dart';
import 'package:nakshatra/core/sync/firebase_service.dart';
import 'package:nakshatra/core/theme/app_theme.dart';
import 'package:nakshatra/features/home/domain/daily_providers.dart';
import 'package:nakshatra/features/home/presentation/home_screen.dart';
import 'package:nakshatra/features/onboarding/data/profile_repository.dart';
import 'package:nakshatra/features/onboarding/domain/birth_profile.dart';
import 'package:nakshatra/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fonts.dart';

/// The home screen, rendered in each language.
///
/// It had no test of any kind, which is how two faults reached closed testing:
/// the sunrise/sunset/moonrise row overflowed by 7px in Tamil, and the rāhu
/// kālaya card — the card the app is opened for — printed its heading in
/// **Sinhala** whatever language the reader had chosen.
///
/// Neither could be found by reading the widget tree. The first needs a layout
/// at a real width in a script wider than English; the second looks correct in
/// the source, because leading with the Sinhala form was a deliberate decision
/// that simply does not survive a Tamil reader.
///
/// The almanac itself is stubbed. Swiss Ephemeris does not load in a widget
/// test, and nothing here is about whether the numbers are right — that is
/// covered in `test/core/astro/`. This is only about whether the screen can
/// draw them in three scripts.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadAppFonts);

  final sinhala = RegExp(r'[඀-෿]');
  final tamil = RegExp(r'[஀-௿]');

  final today = DateTime(2026, 9, 8, 12);

  DateTime at(int h, int m) => DateTime(2026, 9, 8, h, m);

  final panchanga = Panchanga(
    date: today,
    vara: Vara.mangala,
    tithi: PanchangaElement(value: Tithi.values.first, endsAt: at(14, 43)),
    paksha: Paksha.krishna,
    nakshatra: PanchangaElement(
      value: Nakshatra.values.first,
      endsAt: at(16, 39),
    ),
    yoga: PanchangaElement(value: Yoga.values.first, endsAt: at(11, 18)),
    karana: PanchangaElement(value: Karana.values.first, endsAt: at(14, 43)),
    sunrise: at(6, 5),
    sunset: at(18, 10),
    moonrise: at(3, 15),
  );

  final rahu = TimeWindow(
    start: at(15, 9),
    end: at(16, 40),
    name: 'Rāhu kālaya',
  );

  late SharedPreferences prefs;

  setUp(() async {
    const place = Place(
      en: 'Panadura',
      si: 'පානදුර',
      ta: 'பாணந்துறை',
      latitude: 6.713,
      longitude: 79.903,
      district: 'Kalutara',
      districtSi: 'කළුතර',
      districtTa: 'களுத்துறை',
    );

    SharedPreferences.setMockInitialValues({
      'birth_profile_v1': jsonEncode(
        BirthProfile(
          name: 'Chamod',
          birthDate: DateTime(2000, 7, 23),
          birthTime: const Duration(hours: 6),
          birthTimeKnown: true,
          place: place,
        ).toJson(),
      ),
    });
    prefs = await SharedPreferences.getInstance();
    FlavorConfig.initialize(Flavor.dev);
    FirebaseService.resetForTesting();
    AuthService.resetGoogleForTesting();
  });

  Future<List<String>> pumpHome(WidgetTester tester, AppLocale locale) async {
    // What app.dart and bootstrap.dart do at startup. Without it DateFormat
    // falls back to en_US and every time on the screen is measured at English
    // width — which is how a Tamil overflow sat in a test that passed. The
    // widths are the whole point of the test.
    await initializeDateFormatting();
    Intl.defaultLocale = locale.code;
    addTearDown(() => Intl.defaultLocale = null);

    // A real phone's width, and a viewport tall enough to hold the whole
    // page. The width is what these tests are about — Sinhala and Tamil are
    // wider than English and that is what overflows. The height is deliberate
    // too: at 720 the lower cards are never laid out at all, and the
    // inauspicious-periods card sat below the fold overflowing by 18px while
    // this test passed.
    tester.view.physicalSize = const Size(360, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        // bootstrap.dart supplies this; the ad gate throws without it, and
        // the banner only mounts once the page lays out far enough to reach
        // it — which is exactly what the tall viewport makes happen.
        appLaunchedAtProvider.overrideWithValue(today),
        panchangaProvider.overrideWithValue(panchanga),
        inauspiciousProvider.overrideWithValue([
          rahu,
          TimeWindow(start: at(9, 6), end: at(10, 37), name: 'Yamaganda'),
        ]),
        auspiciousProvider.overrideWithValue([
          TimeWindow(
            start: at(13, 38),
            end: at(15, 9),
            name: 'Subha',
            auspicious: true,
          ),
        ]),
        currentlyInauspiciousProvider.overrideWithValue(null),
        poyaTodayProvider.overrideWithValue(null),
        nextPoyaProvider.overrideWithValue(null),
        nextFestivalProvider.overrideWithValue(null),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: Locale(locale.code),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          theme: AppTheme.light(locale),
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  for (final locale in AppLocale.values) {
    testWidgets('the home screen lays out in ${locale.englishName}', (
      tester,
    ) async {
      await pumpHome(tester, locale);

      // An overflow is thrown, not returned, so it has to be taken explicitly.
      expect(
        tester.takeException(),
        isNull,
        reason: 'home layout broke in ${locale.englishName}',
      );
    });
  }

  testWidgets('a Tamil reader is not shown Sinhala', (tester) async {
    // The rāhu kālaya heading was hardcoded to රාහු කාලය in every language,
    // with the translated name demoted to small grey type beneath it. The
    // reasoning — that it is the form printed on every litha — is true for a
    // Sinhala reader and meaningless to a Tamil one, who cannot read the
    // script it is written in.
    final drawn = await pumpHome(tester, AppLocale.ta);

    final wrongScript = drawn.where(sinhala.hasMatch).toList();
    expect(
      wrongScript,
      isEmpty,
      reason: 'Sinhala shown in a Tamil app: $wrongScript',
    );
    expect(
      drawn.any(tamil.hasMatch),
      isTrue,
      reason: 'the Tamil screen drew no Tamil at all',
    );
  });

  testWidgets('a Sinhala reader is not shown Tamil', (tester) async {
    final drawn = await pumpHome(tester, AppLocale.si);

    final wrongScript = drawn.where(tamil.hasMatch).toList();
    expect(
      wrongScript,
      isEmpty,
      reason: 'Tamil shown in a Sinhala app: $wrongScript',
    );
    expect(drawn.any(sinhala.hasMatch), isTrue);
  });
}
