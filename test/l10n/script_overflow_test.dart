import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nakshatra/core/config/app_locale.dart';
import 'package:nakshatra/core/config/flavor.dart';
import 'package:nakshatra/core/sync/auth_service.dart';
import 'package:nakshatra/core/sync/firebase_service.dart';
import 'package:nakshatra/core/theme/app_theme.dart';
import 'package:nakshatra/features/account/presentation/account_screen.dart';
import 'package:nakshatra/features/onboarding/data/profile_repository.dart';
import 'package:nakshatra/features/settings/presentation/settings_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:nakshatra/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fonts.dart';

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

  setUpAll(loadAppFonts);

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

  Future<void> pumpSettings(WidgetTester tester, AppLocale locale) async {
    await initializeDateFormatting();
    Intl.defaultLocale = locale.code;
    addTearDown(() => Intl.defaultLocale = null);

    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    PackageInfo.setMockInitialValues(
      appName: 'Nakshatra',
      packageName: 'io.helocode.nakshatra',
      version: '1.0.1',
      buildNumber: '1',
      buildSignature: '',
    );

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
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final locale in AppLocale.values) {
    testWidgets('the settings rows keep their shape in ${locale.englishName}', (
      tester,
    ) async {
      // KAN-60. The theme row used to put a DropdownButton in the trailing
      // slot, and a dropdown sizes itself to its widest item, which ListTile
      // lays out before the text gets any width. The widest Tamil option is
      // தொலைபேசியைப் பின்பற்று, and it left the title column about one
      // character wide — the hint wrapped into a vertical ribbon on the phone.
      // English was squeezed too, just tolerably, which is why nobody looked.
      //
      // Nothing was wrong with the assertions this file already used: on the
      // old code this throws a _RenderListTile layout assertion here, so
      // takeException() catches it. What was missing was that the settings
      // screen was never pumped in any language at all — only the account
      // screen was. Coverage, not cleverness.
      //
      // The height check stays because it fails with a number and a language
      // in the message rather than a wall of render-library output, and
      // because a row can be squeezed unusably without ever throwing.
      await pumpSettings(tester, locale);

      expect(
        tester.takeException(),
        isNull,
        reason: 'settings layout broke in ${locale.englishName}',
      );

      final tiles = find.byType(ListTile);
      expect(tiles, findsWidgets);

      for (var i = 0; i < tiles.evaluate().length; i++) {
        final height = tester.getSize(tiles.at(i)).height;
        expect(
          height,
          lessThan(200),
          reason:
              'a settings row is ${height.toStringAsFixed(0)}px tall in '
              '${locale.englishName} — its text column has been squeezed',
        );
      }
    });
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
