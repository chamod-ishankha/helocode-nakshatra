import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:nakshatra/core/astro/calendar_models.dart';
import 'package:nakshatra/core/astro/sri_lankan_calendar.dart';
import 'package:nakshatra/core/config/app_locale.dart';
import 'package:nakshatra/core/theme/app_theme.dart';
import 'package:nakshatra/features/calendar/domain/calendar_providers.dart';
import 'package:nakshatra/features/calendar/presentation/calendar_screen.dart';
import 'package:nakshatra/features/onboarding/data/profile_repository.dart';
import 'package:nakshatra/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fonts.dart';

/// The calendar has to say what it is marking.
///
/// KAN-23 failed QA as "there is only poya day and calander, others are not in
/// there". The grid put a dot on a day and never named it, so a month with no
/// festival in it read as an app that knows about poya days and nothing else.
///
/// `monthMarkersProvider` is overridden because everything behind it needs
/// Swiss Ephemeris, which does not load in a widget test. That is also why
/// `SriLankanCalendar` had no test file at all, and why it could ship knowing
/// five festivals without anyone noticing.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadAppFonts);

  final poya = PoyaDay(
    date: DateTime(2026, 9, 26),
    month: PoyaMonth.binara,
    isAdhi: false,
    fullMoon: DateTime(2026, 9, 26, 20, 12),
  );

  final christmas = Festival(
    date: DateTime(2026, 12, 25),
    name: 'Christmas Day',
    si: 'නත්තල්',
    ta: 'கிறிஸ்துமஸ்',
    kind: FestivalKind.fixed,
  );

  Future<List<String>> pump(
    WidgetTester tester,
    AppLocale locale, {
    required Map<int, List<Festival>> markers,
  }) async {
    await initializeDateFormatting();
    Intl.defaultLocale = locale.code;
    addTearDown(() => Intl.defaultLocale = null);

    tester.view.physicalSize = const Size(360, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({'app_locale_v1': locale.code});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        monthMarkersProvider.overrideWithValue(markers),
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
          home: const CalendarScreen(),
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
    testWidgets('the month\'s events are named in ${locale.englishName}', (
      tester,
    ) async {
      final drawn = await pump(
        tester,
        locale,
        markers: {
          26: [poya],
          25: [christmas],
        },
      );

      expect(
        drawn,
        contains(poya.label(locale)),
        reason: 'the poya is marked but not named',
      );
      expect(
        drawn,
        contains(christmas.label(locale)),
        reason: 'the festival is marked but not named',
      );
    });
  }

  testWidgets('a month with nothing in it says so', (tester) async {
    // The failure this ticket was raised for. An empty grid with no
    // explanation reads as an app that does not know about festivals.
    final drawn = await pump(tester, AppLocale.en, markers: const {});
    final l10n = await L10n.delegate.load(const Locale('en'));

    expect(drawn, contains(l10n.calendarNoEvents));
  });

  testWidgets('the festivals it cannot compute are named too', (tester) async {
    // Four of Sri Lanka's public holidays are set by moon sighting or local
    // custom. Silently omitting them tells the reader something false about
    // the year, so the screen lists them and says why.
    final drawn = await pump(tester, AppLocale.en, markers: const {});
    final joined = drawn.join(' | ');

    expect(SriLankanCalendar.unsupportedFestivals, isNotEmpty);
    for (final name in SriLankanCalendar.unsupportedFestivals.keys) {
      expect(joined, contains(name), reason: '$name is not named on screen');
    }
  });

  test('the announced list covers the ones with no rule', () {
    // Guards the list itself: these four are gazetted rather than calculated,
    // and dropping one from the map silently removes it from the screen.
    expect(
      SriLankanCalendar.unsupportedFestivals.keys,
      containsAll(<String>[
        'Deepavali',
        'Eid al-Fitr',
        'Eid al-Adha',
        'Milad un-Nabi',
      ]),
    );
  });
}
