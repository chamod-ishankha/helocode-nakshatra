import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/config/app_locale.dart';
import 'package:nakshatra/core/theme/app_spacing.dart';
import 'package:nakshatra/core/theme/app_theme.dart';
import 'package:nakshatra/core/ui/info_notice.dart';

import '../../support/fonts.dart';

/// The shared notice, and the rule it exists to enforce (KAN-51).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadAppFonts);

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    AppLocale locale = AppLocale.en,
    Brightness brightness = Brightness.dark,
  }) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: brightness == Brightness.dark
            ? AppTheme.dark(locale)
            : AppTheme.light(locale),
        home: Scaffold(
          body: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('a caution notice always carries a mark', () {
    // The rule from SemanticColors, enforced in the type rather than in a
    // comment: about one Sri Lankan man in twelve cannot tell this app's
    // inauspicious red from its auspicious green, so the colour on its own
    // says nothing to them. A caution notice built with no icon at all would
    // be exactly that failure, so it is not a shape this widget can take.
    testWidgets('even when none was asked for', (tester) async {
      await pump(
        tester,
        const InfoNotice(text: 'Rāhu kālaya', tone: NoticeTone.caution),
      );

      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('and a given one is used instead of the default', (
      tester,
    ) async {
      await pump(
        tester,
        const InfoNotice(
          text: 'Birth time unknown',
          tone: NoticeTone.caution,
          icon: Icons.schedule,
        ),
      );

      expect(tester.widget<Icon>(find.byType(Icon)).icon, Icons.schedule);
    });
  });

  group('drawing', () {
    for (final locale in AppLocale.values) {
      testWidgets('both tones fit in ${locale.englishName}', (tester) async {
        // Sinhala and Tamil run taller and longer than the English these were
        // composed in, and a notice is usually the longest sentence on a
        // screen.
        await pump(
          tester,
          Column(
            children: [
              InfoNotice(
                text: switch (locale) {
                  AppLocale.si =>
                    'උපන් වේලාව නොදන්නා බැවින් මෙම ලග්නය ආසන්න අගයකි.',
                  AppLocale.ta =>
                    'பிறந்த நேரம் தெரியாததால் இந்த லக்னம் தோராயமானது.',
                  AppLocale.en =>
                    'Your birth time is unknown, so this lagna is approximate.',
                },
                tone: NoticeTone.caution,
              ),
              const SizedBox(height: AppSpacing.sm),
              const InfoNotice(
                text: 'The navāṁśa divides each rāśi into nine.',
              ),
            ],
          ),
          locale: locale,
        );

        expect(
          tester.takeException(),
          isNull,
          reason: 'a notice broke in ${locale.englishName}',
        );
        expect(find.byType(InfoNotice), findsNWidgets(2));
      });
    }

    testWidgets('a caution notice is outlined, never filled', (tester) async {
      // A flat tint of the inauspicious red over a light surface reads as
      // muddy brown — hit once already on the rāhu card. The fix was a plain
      // surface with a rule around it, and this keeps that.
      await pump(
        tester,
        const InfoNotice(text: 'Careful', tone: NoticeTone.caution),
        brightness: Brightness.light,
      );

      final box = tester.widget<Container>(find.byType(Container));
      final decoration = box.decoration! as BoxDecoration;

      expect(decoration.color, isNull, reason: 'caution must not be filled');
      expect(decoration.border, isNotNull);
    });
  });

  group('the spacing scale', () {
    test('is a four-point scale in ascending order', () {
      // Material's own metrics are built on four; mixing bases is what makes
      // alignment look accidental rather than chosen.
      const scale = [
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxl,
        AppSpacing.huge,
      ];

      for (final step in scale) {
        expect(step % 4, 0, reason: '$step is off the four-point grid');
      }
      for (var i = 1; i < scale.length; i++) {
        expect(scale[i], greaterThan(scale[i - 1]));
      }
    });
  });
}
