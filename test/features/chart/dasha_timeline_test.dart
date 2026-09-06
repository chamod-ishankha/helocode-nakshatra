import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/astro/dasha.dart';
import 'package:nakshatra/core/config/app_locale.dart';
import 'package:nakshatra/core/config/flavor.dart';
import 'package:nakshatra/core/theme/app_theme.dart';
import 'package:nakshatra/features/chart/presentation/dasha_timeline.dart';
import 'package:nakshatra/features/onboarding/data/profile_repository.dart';
import 'package:nakshatra/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The daśā table as a reader meets it (KAN-53).
///
/// `dashaProvider` is overridden rather than computed, because the real one
/// goes through the ephemeris and cannot run on the host. What is under test
/// here is the presentation: which period is called out, what is hidden, and
/// whether it survives three scripts on a small screen.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    FlavorConfig.initialize(Flavor.dev);
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  final now = DateTime.now().toUtc();

  /// A timeline whose third mahādaśā is running right now.
  ///
  /// Built by hand so "current" is deterministic — deriving it from a real
  /// chart would make the expected highlight depend on the day the suite runs.
  List<DashaPeriod> timelineWithCurrentThird() {
    final lords = Vimshottari.lords;
    final periods = <DashaPeriod>[];

    // Two finished periods, one running, the rest ahead.
    var cursor = now.subtract(const Duration(days: 365 * 12));

    for (var i = 0; i < lords.length; i++) {
      final length = Duration(days: 365 * 5);
      final start = cursor;
      final end = cursor.add(length);

      periods.add(
        DashaPeriod(
          lord: lords[i],
          level: DashaLevel.maha,
          start: start,
          end: end,
          children: [
            for (var j = 0; j < lords.length; j++)
              DashaPeriod(
                lord: lords[(i + j) % lords.length],
                level: DashaLevel.antara,
                start: start.add(Duration(days: 203 * j)),
                end: start.add(Duration(days: 203 * (j + 1))),
              ),
          ],
        ),
      );
      cursor = end;
    }
    return periods;
  }

  Future<void> pump(
    WidgetTester tester, {
    required bool birthTimeKnown,
    AppLocale locale = AppLocale.en,
    List<DashaPeriod>? timeline,
  }) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // The lord names are rendered in the reader's language, so the
          // widgets read localeProvider — which needs storage behind it.
          sharedPreferencesProvider.overrideWithValue(prefs),
          localeProvider.overrideWith(() => _FixedLocale(locale)),
          dashaProvider.overrideWithValue(
            timeline ?? timelineWithCurrentThird(),
          ),
        ],
        child: MaterialApp(
          locale: Locale(locale.code),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          theme: AppTheme.light(locale),
          home: Scaffold(
            body: SingleChildScrollView(
              child: DashaTimeline(birthTimeKnown: birthTimeKnown),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the running period is stated before the table', (tester) async {
    await pump(tester, birthTimeKnown: true);

    expect(find.text('Running now'), findsOneWidget);
    // A daśā table is 81 rows; nobody opens it to read 1997.
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('every mahādaśā is listed', (tester) async {
    await pump(tester, birthTimeKnown: true);

    for (final lord in Vimshottari.lords) {
      expect(
        find.text(lord.en),
        findsWidgets,
        reason: '${lord.en} is missing from the table',
      );
    }
  });

  testWidgets('the current period is opened and the rest are collapsed',
      (tester) async {
    await pump(tester, birthTimeKnown: true);

    // Only the running mahādaśā expands, so the screen does not arrive as
    // nine open lists.
    expect(find.text('Sub-periods'), findsOneWidget);
  });

  testWidgets('an unknown birth time is warned about', (tester) async {
    await pump(tester, birthTimeKnown: false);

    // Stronger than the houses caveat: half a day of uncertainty is up to
    // half a nakṣatra, which can change the ruling planet outright.
    expect(find.textContaining('rough guide'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });

  testWidgets('a known birth time gets no warning', (tester) async {
    await pump(tester, birthTimeKnown: true);

    expect(find.textContaining('rough guide'), findsNothing);
    expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
  });

  testWidgets('the shortened first period is explained', (tester) async {
    await pump(tester, birthTimeKnown: true);

    // Without this the first row just looks wrong — a five-year Venus period.
    expect(find.textContaining('shorter than its full length'), findsOneWidget);
  });

  testWidgets('nothing renders when there is no chart', (tester) async {
    await pump(tester, birthTimeKnown: true, timeline: const []);

    expect(find.text('Running now'), findsNothing);
    expect(find.byType(ExpansionTile), findsNothing);
  });

  testWidgets('no third level is shown while it is a Pro feature',
      (tester) async {
    await pump(tester, birthTimeKnown: true);

    // The engine can generate pratyantardaśā, but showing it behind a lock
    // that does nothing (KAN-36 is unbuilt) would be worse than not showing
    // it. Nested ExpansionTiles inside a sub-period would mean it leaked.
    final tiles = tester.widgetList<ExpansionTile>(find.byType(ExpansionTile));
    expect(tiles.length, Vimshottari.lords.length);
  });

  for (final locale in AppLocale.values) {
    testWidgets('it fits at 360x640 in ${locale.englishName}', (tester) async {
      await pump(tester, birthTimeKnown: false, locale: locale);

      // Sinhala and Tamil run taller and longer than the English this was
      // laid out in, and the warning paragraph is the longest string here.
      expect(
        tester.takeException(),
        isNull,
        reason: 'layout broke in ${locale.englishName}',
      );
    });
  }
}

/// Pins the language, so a locale test does not depend on what the device
/// running the suite happens to be set to.
class _FixedLocale extends LocaleNotifier {
  _FixedLocale(this._locale);
  final AppLocale _locale;

  @override
  AppLocale build() => _locale;
}
