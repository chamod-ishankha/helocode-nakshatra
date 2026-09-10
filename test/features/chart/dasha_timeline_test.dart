import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/ads/locked_content.dart';
import 'package:nakshatra/core/ads/rewarded_unlock.dart';
import 'package:nakshatra/core/astro/dasha.dart';
import 'package:nakshatra/core/purchases/entitlements.dart';
import 'package:nakshatra/core/purchases/purchase_controller.dart';
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
                // Three rather than nine: the count does not matter to what
                // is under test, and nine would make every failure message a
                // wall of dates.
                children: [
                  for (var k = 0; k < 3; k++)
                    DashaPeriod(
                      lord: lords[(i + j + k) % lords.length],
                      level: DashaLevel.pratyantara,
                      start: start.add(Duration(days: 203 * j + 60 * k)),
                      end: start.add(Duration(days: 203 * j + 60 * (k + 1))),
                    ),
                ],
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
    bool ownsPro = false,
    bool canWatch = true,
    bool canBuy = true,
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
          featureProvider(
            PaidFeature.fullDashaTimeline,
          ).overrideWithValue(ownsPro),
          // Both doors pinned open. The real ones read static ad ids and a
          // live store, neither of which exists on a host — and a lock with
          // no way past it opens itself, which would make every assertion
          // below pass on nothing.
          rewardedAvailableProvider.overrideWithValue(canWatch),
          purchasesAvailableProvider.overrideWithValue(canBuy),
          unlockStoreProvider.overrideWithValue(
            UnlockStore(
              prefs: prefs,
              hasEntitlement: false,
              adsConfigured: true,
            ),
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

  testWidgets('the current period is opened and the rest are collapsed', (
    tester,
  ) async {
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

  /// Opens the first antardaśā inside the running mahādaśā.
  ///
  /// The running period is the third, and it is the only one expanded, so its
  /// sub-period rows are the only nested tiles in the tree. They sit well
  /// below a 640-high viewport, hence the scroll.
  Future<void> openFirstSubPeriod(WidgetTester tester) async {
    final antara = find
        .descendant(
          of: find.byType(ExpansionTile).at(2),
          matching: find.byType(ExpansionTile),
        )
        .first;

    await tester.ensureVisible(antara);
    await tester.pumpAndSettle();
    await tester.tap(antara);
    await tester.pumpAndSettle();
  }

  testWidgets('the third level arrives locked, not missing', (tester) async {
    await pump(tester, birthTimeKnown: true);

    // Nothing on screen until the user asks for it: the running mahādaśā is
    // open, but no sub-period is, so no lock has appeared yet.
    expect(find.byType(LockedContent), findsNothing);

    await openFirstSubPeriod(tester);

    // Behind the blur rather than absent. The content is what is being sold,
    // so it has to be built — with both doors out on top of it.
    expect(find.byType(LockedContent), findsOneWidget);
    expect(find.byType(ImageFiltered), findsOneWidget);
    expect(find.text('Watch a short video'), findsOneWidget);
  });

  testWidgets('the lock sits centred, not shifted by the nesting', (
    tester,
  ) async {
    // Reported from the device: the card sat 14 logical pixels right of
    // centre. Both ExpansionTiles indented their children on the left only,
    // and anything centred inside inherited the whole asymmetry. Nothing
    // failed — it just looked wrong, which is why it needs a number.
    await pump(tester, birthTimeKnown: true);
    await openFirstSubPeriod(tester);

    final card = tester.getRect(
      find.descendant(
        of: find.byType(LockedContent),
        matching: find.byType(Card),
      ),
    );
    final timeline = tester.getRect(find.byType(DashaTimeline));

    expect(
      card.center.dx,
      moreOrLessEquals(timeline.center.dx, epsilon: 0.5),
      reason:
          'card spans ${card.left}..${card.right} inside '
          '${timeline.left}..${timeline.right}',
    );
  });

  testWidgets('Remove Ads is not Pro', (tester) async {
    // Somebody who paid to remove ads gets no video button — the promise was
    // no ads anywhere — but they have not bought Pro, so the content stays
    // locked with the purchase as the only way through. Opening it for them
    // would make the cheap one-time buy strictly better value than the
    // subscription.
    await pump(tester, birthTimeKnown: true, canWatch: false);
    await openFirstSubPeriod(tester);

    expect(find.byType(LockedContent), findsOneWidget);
    expect(find.text('Watch a short video'), findsNothing);
    expect(find.text('Go Pro'), findsOneWidget);
  });

  testWidgets('a build that can neither sell nor show ads locks nothing', (
    tester,
  ) async {
    // A clone with no env file. Both doors are missing, so a lock would be a
    // wall — the app has to stay whole.
    await pump(tester, birthTimeKnown: true, canWatch: false, canBuy: false);
    await openFirstSubPeriod(tester);

    expect(find.byType(ImageFiltered), findsNothing);
    expect(find.text('Go Pro'), findsNothing);
  });

  testWidgets('Pro sees the third level with nothing over it', (tester) async {
    await pump(tester, birthTimeKnown: true, ownsPro: true);
    await openFirstSubPeriod(tester);

    // The prompt is gone, and so is the blur — a paying user must not be
    // shown a lock they have already opened.
    expect(find.text('Watch a short video'), findsNothing);
    expect(find.byType(ImageFiltered), findsNothing);
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
