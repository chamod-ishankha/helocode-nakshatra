import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/config/app_locale.dart';
import 'package:nakshatra/core/config/flavor.dart';
import 'package:nakshatra/core/sync/auth_service.dart';
import 'package:nakshatra/core/sync/firebase_service.dart';
import 'package:nakshatra/core/theme/app_theme.dart';
import 'package:nakshatra/features/account/presentation/account_screen.dart';
import 'package:nakshatra/features/onboarding/data/profile_repository.dart';
import 'package:nakshatra/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sinhala and Tamil in layouts that were composed in English.
///
/// Both scripts run taller than Latin, and the translations are frequently
/// longer, so a Column or Row that fits English can overflow in Sinhala. That
/// shows as a black-and-yellow stripe on a real phone and as a render
/// exception here — but only if something actually pumps the screen in that
/// language, which an English-only suite never does.
///
/// Sized to a 360x640 logical screen: the cheap Android phones this app is
/// aimed at, not the tester's desktop.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    FlavorConfig.initialize(Flavor.dev);
    FirebaseService.resetForTesting();
    AuthService.resetGoogleForTesting();
  });

  Future<void> pumpAccount(
    WidgetTester tester,
    AppLocale locale,
    AccountKind kind,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        accountStatusProvider.overrideWith(
          (ref) => Stream.value(
            AccountStatus(kind: kind, email: 'someone@example.com'),
          ),
        ),
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
          home: const AccountScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final locale in AppLocale.values) {
    for (final kind in AccountKind.values) {
      testWidgets(
        'the account screen in ${locale.englishName} (${kind.name}) fits',
        (tester) async {
          await pumpAccount(tester, locale, kind);

          // An overflow is reported as an exception rather than a failed
          // expectation, so it has to be collected explicitly.
          expect(
            tester.takeException(),
            isNull,
            reason: 'layout broke in ${locale.englishName}',
          );
        },
      );
    }
  }

  testWidgets('the theme picks the right font for each script', (tester) async {
    // The fallback list is what stops Sinhala rendering as empty boxes when
    // the interface is in English — place names carry it either way.
    expect(AppTheme.fontFor(AppLocale.si), AppTheme.sinhalaFont);
    expect(AppTheme.fontFor(AppLocale.ta), AppTheme.tamilFont);
    expect(
      AppTheme.fontFor(AppLocale.en),
      isNull,
      reason: 'English should keep the Material default face',
    );

    final theme = AppTheme.light(AppLocale.en);
    expect(
      theme.textTheme.bodyMedium?.fontFamilyFallback,
      containsAll([AppTheme.sinhalaFont, AppTheme.tamilFont]),
      reason: 'an English UI still has to draw Sinhala place names',
    );
  });
}
