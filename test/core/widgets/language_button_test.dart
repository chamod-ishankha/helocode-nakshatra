import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/config/app_locale.dart';
import 'package:nakshatra/core/config/flavor.dart';
import 'package:nakshatra/core/theme/app_theme.dart';
import 'package:nakshatra/core/widgets/language_button.dart';
import 'package:nakshatra/features/onboarding/data/profile_repository.dart';
import 'package:nakshatra/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Changing language after onboarding.
///
/// The case that matters is a user who is already stuck: they picked the wrong
/// row, cannot read the interface, and the only alternative is clearing app
/// data, which also destroys their chart.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    FlavorConfig.initialize(Flavor.dev);
  });

  Future<void> pump(WidgetTester tester, {AppLocale? start}) async {
    if (start != null) {
      SharedPreferences.setMockInitialValues({'app_locale_v1': start.code});
      prefs = await SharedPreferences.getInstance();
    }

    container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, _) {
            final locale = ref.watch(localeProvider);
            return MaterialApp(
              locale: Locale(locale.code),
              localizationsDelegates: L10n.localizationsDelegates,
              supportedLocales: L10n.supportedLocales,
              theme: AppTheme.light(locale),
              home: const Scaffold(
                appBar: null,
                body: Center(child: LanguageButton()),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.byType(LanguageButton));
    await tester.pumpAndSettle();
  }

  testWidgets('every language is offered in its own script', (tester) async {
    await pump(tester);
    await openMenu(tester);

    // Written natively so the list is usable by someone who cannot read the
    // language currently showing.
    expect(find.text('සිංහල'), findsOneWidget);
    expect(find.text('தமிழ்'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
  });

  testWidgets('the current language is marked', (tester) async {
    await pump(tester, start: AppLocale.ta);
    await openMenu(tester);

    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('picking a language switches the app immediately',
      (tester) async {
    await pump(tester, start: AppLocale.en);
    expect(container.read(localeProvider), AppLocale.en);

    await openMenu(tester);
    await tester.tap(find.text('සිංහල'));
    await tester.pumpAndSettle();

    expect(container.read(localeProvider), AppLocale.si);
  });

  testWidgets('the choice is written to storage, not just held in memory',
      (tester) async {
    // Losing it on restart would put the user straight back where they were.
    await pump(tester, start: AppLocale.en);

    await openMenu(tester);
    await tester.tap(find.text('தமிழ்'));
    await tester.pumpAndSettle();

    expect(prefs.getString('app_locale_v1'), 'ta');
  });

  testWidgets('a user stuck in Tamil can still find their way out',
      (tester) async {
    // The whole point. The interface is in a script they cannot read, so the
    // icon carries no words and every option is in its own script.
    await pump(tester, start: AppLocale.ta);

    expect(find.byIcon(Icons.translate), findsOneWidget);

    await openMenu(tester);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(container.read(localeProvider), AppLocale.en);
    expect(prefs.getString('app_locale_v1'), 'en');
  });

  testWidgets('re-picking the current language changes nothing', (tester) async {
    await pump(tester, start: AppLocale.si);

    await openMenu(tester);
    await tester.tap(find.text('සිංහල'));
    await tester.pumpAndSettle();

    expect(container.read(localeProvider), AppLocale.si);
    expect(prefs.getString('app_locale_v1'), 'si');
  });
}
