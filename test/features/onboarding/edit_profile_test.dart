import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/config/app_locale.dart';
import 'package:nakshatra/core/theme/app_theme.dart';
import 'package:nakshatra/features/onboarding/data/profile_repository.dart';
import 'package:nakshatra/features/onboarding/domain/birth_profile.dart';
import 'package:nakshatra/features/onboarding/presentation/onboarding_screen.dart';
import 'package:nakshatra/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Opening the wizard over an existing profile has to be an edit.
///
/// Reaching the route was only half of KAN-61. The wizard had no `initState`
/// at all: every field started null and the name box started blank, whatever
/// was already saved. So even once Settings > "Edit birth details" stopped
/// bouncing back to home, it would have dropped the user into an empty
/// five-step form and asked them to retype a name, a date, a time and a town
/// they had already given — a re-entry wizard wearing an edit label.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const place = Place(
    timezone: 'Asia/Colombo',
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
    birthTime: const Duration(hours: 6, minutes: 30),
    birthTimeKnown: true,
    place: place,
  );

  Future<void> pump(WidgetTester tester, {required bool withProfile}) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues(
      withProfile ? {'birth_profile_v1': jsonEncode(profile.toJson())} : {},
    );
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          theme: AppTheme.light(AppLocale.en),
          home: const OnboardingScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('an existing profile fills the wizard in', (tester) async {
    await pump(tester, withProfile: true);

    // The name is the one field visible on the step an edit opens at, and the
    // one that proves the controller was seeded rather than left empty.
    final name = tester.widget<TextField>(find.byType(TextField).first);
    expect(name.controller?.text, 'Chamod');
  });

  testWidgets('an edit skips the language step', (tester) async {
    // The reader has already chosen a language — twice over, since the screen
    // they came from has a language row of its own. Making them pass through
    // it again to reach the field they wanted is friction with no purpose.
    await pump(tester, withProfile: true);

    expect(
      find.byType(TextField),
      findsWidgets,
      reason: 'an edit should open on the name step, not the language step',
    );
  });

  testWidgets('a first run starts empty, on the language step', (tester) async {
    // The other half of the same rule: nothing to prefill, and the language
    // step is the first thing a new user should see.
    await pump(tester, withProfile: false);

    expect(
      find.byType(TextField),
      findsNothing,
      reason: 'a first run should open on the language step',
    );
  });

  testWidgets('an edit cannot go back past its first step', (tester) async {
    // The wizard's back arrow appears from step 1 onward. An edit starts on
    // step 1, so an unguarded arrow would walk the reader into the language
    // step the edit deliberately skipped.
    await pump(tester, withProfile: true);

    expect(find.byIcon(Icons.arrow_back), findsNothing);
  });
}
