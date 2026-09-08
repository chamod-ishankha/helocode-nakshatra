import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:nakshatra/core/config/app_locale.dart';
import 'package:nakshatra/core/theme/app_theme.dart';
import 'package:nakshatra/features/onboarding/data/profile_repository.dart';
import 'package:nakshatra/features/onboarding/domain/birth_profile.dart';
import 'package:nakshatra/features/onboarding/presentation/onboarding_screen.dart';
import 'package:nakshatra/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fonts.dart';

/// The onboarding wizard, in each language.
///
/// It had no language coverage at all, and it collected the four values every
/// other screen is computed from. Two faults were sitting on the birth-time
/// step: the "I don't know my birth time" checkbox was a hardcoded English
/// string, and the chosen time was formatted by building "AM"/"PM" by hand —
/// so the one screen that *asks* for a time printed it in English while every
/// screen that *shows* one printed முற்பகல் or පෙ.ව.
///
/// The step also overflowed once a keyboard was up, and sooner in Sinhala and
/// Tamil, where the question and its explanation run to more lines than the
/// English they were laid out against.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadAppFonts);

  final latin = RegExp(r'[A-Za-z]');

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

  final profile = BirthProfile(
    name: 'Chamod',
    birthDate: DateTime(2000, 7, 23),
    // Afternoon, so a mishandled 12-hour clock shows up as the wrong half of
    // the day rather than looking plausible.
    birthTime: const Duration(hours: 14, minutes: 39),
    birthTimeKnown: true,
    place: place,
  );

  /// Opens the wizard as an edit and walks to the birth-time step.
  Future<void> pumpTimeStep(
    WidgetTester tester,
    AppLocale locale, {
    required Size size,
  }) async {
    await initializeDateFormatting();
    Intl.defaultLocale = locale.code;
    addTearDown(() => Intl.defaultLocale = null);

    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({
      'birth_profile_v1': jsonEncode(profile.toJson()),
    });
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
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
          home: const OnboardingScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // An edit opens on the name step; name and date are already filled, so
    // Continue is live on both.
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
    }
  }

  List<String> drawn(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
      .where((s) => s.isNotEmpty)
      .toList();

  for (final locale in [AppLocale.si, AppLocale.ta]) {
    testWidgets('the birth-time step draws no English in '
        '${locale.englishName}', (tester) async {
      await pumpTimeStep(tester, locale, size: const Size(360, 720));

      final english = drawn(tester).where(latin.hasMatch).toList();
      expect(
        english,
        isEmpty,
        reason: 'still English in ${locale.englishName}: $english',
      );
    });
  }

  for (final locale in AppLocale.values) {
    testWidgets('the birth-time step survives a keyboard in '
        '${locale.englishName}', (tester) async {
      // Roughly what is left of a phone once the keyboard is up — and the
      // keyboard *is* up, because the step before this one is a text field.
      await pumpTimeStep(tester, locale, size: const Size(360, 380));

      expect(
        tester.takeException(),
        isNull,
        reason: 'the time step overflowed in ${locale.englishName}',
      );
    });
  }

  testWidgets('the chosen time is written the way the app writes times', (
    tester,
  ) async {
    // Not "2:39 PM". Every other screen goes through DateFormat and says
    // பிற்பகல்; this one built the suffix itself and said PM.
    await pumpTimeStep(tester, AppLocale.ta, size: const Size(360, 720));

    final expected = DateFormat(
      'h:mm a',
    ).format(DateTime(2000).add(profile.birthTime));
    expect(drawn(tester), contains(expected));
    expect(expected, isNot(contains('PM')));
  });
}
