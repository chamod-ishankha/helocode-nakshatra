import '../../../core/astro/models.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/ui/brand_card.dart';
import '../../../core/ui/info_notice.dart';
import '../../../core/ui/nakshatra_star.dart';
import '../../../core/ui/pill_segments.dart';
import '../../../core/ui/round_icon_button.dart';
import '../../../core/theme/semantic_colors.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/ads/interstitial.dart';
import '../../../core/ads/rewarded_unlock.dart';
import '../../../core/ads/rewarded_unlock_card.dart';
import '../../../core/router/app_router.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../home/domain/daily_providers.dart';
import '../../onboarding/data/profile_repository.dart';
import '../domain/fragment.dart';
import '../domain/horoscope_engine.dart';
import '../domain/horoscope_providers.dart';

/// The daily reading (KAN-31).
///
/// Reads for the day selected on the home screen, not always today, so the
/// date switcher and the calendar keep working the way they do everywhere
/// else in the app.
class HoroscopeScreen extends ConsumerStatefulWidget {
  const HoroscopeScreen({super.key});

  @override
  ConsumerState<HoroscopeScreen> createState() => _HoroscopeScreenState();
}

class _HoroscopeScreenState extends ConsumerState<HoroscopeScreen> {
  final _scroll = ScrollController();

  /// Whether the reading was scrolled to the end.
  ///
  /// The ticket asks for an interstitial *after reading* the horoscope, and
  /// this is what makes that true rather than "after opening" it. Somebody who
  /// glances at the sign and backs out has not been given anything, and an ad
  /// for that is the interruption that gets an app uninstalled.
  bool _readToEnd = false;

  /// Whether there was a reading on screen at all. Set during build.
  ///
  /// False while the day is locked behind a rewarded unlock, or when no copy
  /// exists for this build. Charging attention for a screen that showed
  /// nothing is the worst version of this placement.
  bool _hadReading = false;

  /// Guards against firing twice — the app bar button pops, which then also
  /// notifies [PopScope].
  bool _left = false;

  @override
  void initState() {
    super.initState();

    // Loaded while the user reads, so leaving is instant. Nothing is loaded
    // for somebody who bought Remove Ads; the controller checks that.
    unawaited(ref.read(interstitialControllerProvider).prepare());

    _scroll.addListener(_checkReadToEnd);
    // Short readings never scroll, so no listener would ever fire. Checked
    // once after the first layout instead.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkReadToEnd());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _checkReadToEnd() {
    if (_readToEnd || !_scroll.hasClients) return;
    // Eight logical pixels of slack: a fling settles a fraction short of the
    // bottom often enough that an exact comparison never matches.
    if (_scroll.position.extentAfter <= 8) _readToEnd = true;
  }

  /// Called once, as the user leaves.
  ///
  /// Read before navigating and fired afterwards: the controller holds
  /// everything it needs, so it does not matter that this widget is on its way
  /// out, and the ad lands over the screen the user arrived at rather than
  /// delaying the one they left.
  void _leaving() {
    if (_left) return;
    _left = true;
    if (!_readToEnd || !_hadReading) return;

    unawaited(ref.read(interstitialControllerProvider).showIfAllowed());
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final locale = ref.watch(localeProvider);
    final date = ref.watch(selectedDateProvider);

    // Days ahead are gated exactly as they are on the home screen. Gating one
    // and not the other would make the lock look arbitrary, and would leave an
    // obvious way around it.
    final now = DateTime.now();
    final ahead = date.isAfter(DateTime(now.year, now.month, now.day));
    final locked =
        ahead &&
        !ref.watch(unlockStoreProvider).isOpen(RewardedUnlock.futureDay);

    final axis = ref.watch(horoscopeAxisProvider);
    final horoscope = locked ? null : ref.watch(horoscopeProvider(axis));
    _hadReading = horoscope != null;

    final lagna = ref.watch(lagnaRasiProvider);
    final moon = ref.watch(janmaRasiProvider);
    // When the two coincide there is only one reading to give, and a toggle
    // between two identical readings would look broken.
    final bothSame = lagna != null && lagna == moon;
    final sign = ref.watch(horoscopeSignProvider(axis));

    final palette = BrandPalette.of(context);

    return PopScope(
      // The system back gesture pops on its own; this only needs to know it
      // happened. Blocking a back press to show an ad would be both hostile
      // and against AdMob's own placement rules.
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _leaving();
      },
      child: Scaffold(
        backgroundColor: palette.background,
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: palette.backdrop),
          child: SafeArea(
            bottom: false,
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
              children: [
                Row(
                  children: [
                    RoundIconButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).backButtonTooltip,
                      onPressed: () {
                        _leaving();
                        popOrHome(context);
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l.horoscopeTitle,
                        style: BrandFonts.displayStyle(
                          context,
                          size: 26,
                          color: palette.text,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                if (!bothSame && lagna != null && moon != null) ...[
                  PillSegments<HoroscopeAxis>(
                    segments: [
                      (value: HoroscopeAxis.lagna, label: l.horoscopeByLagna),
                      (value: HoroscopeAxis.rasi, label: l.horoscopeByRasi),
                    ],
                    selected: axis,
                    onChanged: (a) =>
                        ref.read(horoscopeAxisProvider.notifier).set(a),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                if (sign != null)
                  _SignMedallion(
                    sign: sign,
                    name: sign.label(locale),
                    date: DateFormat.MMMMEEEEd(
                      Localizations.localeOf(context).languageCode,
                    ).format(date),
                  ),
                if (bothSame)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      l.horoscopeSameSign,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: palette.muted),
                    ),
                  ),

                // The lagna moves a sign every two hours, so without a birth
                // time it is a guess. Saying nothing would present a coin flip
                // as a reading. A notice with its warning icon: it was red text
                // alone, which is colour carrying the meaning (KAN-86).
                if (axis == HoroscopeAxis.lagna &&
                    ref.watch(lagnaIsApproximateProvider)) ...[
                  const SizedBox(height: AppSpacing.md),
                  InfoNotice(
                    text: l.horoscopeLagnaApproximate,
                    tone: NoticeTone.caution,
                  ),
                ],

                const SizedBox(height: AppSpacing.lg),

                if (locked)
                  RewardedUnlockCard(
                    unlock: RewardedUnlock.futureDay,
                    title: l.unlockFutureTitle,
                    body: l.unlockFutureBody,
                  )
                else if (horoscope == null)
                  // No bundled copy for this build. Not worth an error: the
                  // rest of the app still works.
                  _Empty(text: l.horoscopeUnavailable)
                else ...[
                  for (final category in HoroscopeEngine.sectionOrder)
                    if (horoscope[category] case final text?)
                      _Section(category: category, text: text),
                  _LuckyRow(horoscope: horoscope),
                ],

                const SizedBox(height: AppSpacing.xl),
                Text(
                  l.entertainmentOnly,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: palette.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The sign being read, as a medallion: its symbol in a gold ring, the name
/// beneath, then the day.
class _SignMedallion extends StatelessWidget {
  const _SignMedallion({
    required this.sign,
    required this.name,
    required this.date,
  });

  final Rasi sign;
  final String name;
  final String date;

  @override
  Widget build(BuildContext context) {
    final palette = BrandPalette.of(context);
    final semantic = context.semantic;
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: semantic.accent),
            gradient: RadialGradient(
              colors: [
                Color.alphaBlend(
                  semantic.accent.withValues(alpha: 0.18),
                  palette.surface,
                ),
                palette.surface,
              ],
            ),
          ),
          // The zodiac symbol, U+2648 onwards in rāśi order, from the bundled
          // zodiac subset. Left to the system, Android draws it from the
          // colour emoji font as a blue tile, and the text presentation
          // selector did not stop it.
          child: ExcludeSemantics(
            child: Text(
              String.fromCharCode(0x2648 + sign.index),
              style: TextStyle(
                fontFamily: 'NotoZodiac',
                fontSize: 42,
                height: 1,
                color: semantic.accent,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          name,
          textAlign: TextAlign.center,
          style: BrandFonts.displayStyle(
            context,
            size: 30,
            color: palette.text,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          date,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: palette.muted),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = BrandPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          SizedBox.square(
            dimension: 96,
            child: CustomPaint(
              painter: NakshatraStarPainter(
                progress: 1,
                color: context.semantic.accent.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, height: 1.5, color: palette.muted),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.category, required this.text});

  final HoroscopeCategory category;
  final String text;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);

    final (label, icon) = switch (category) {
      HoroscopeCategory.general => (
        l.horoscopeGeneral,
        Icons.wb_sunny_outlined,
      ),
      HoroscopeCategory.career => (l.horoscopeCareer, Icons.work_outline),
      HoroscopeCategory.money => (l.horoscopeMoney, Icons.savings_outlined),
      HoroscopeCategory.love => (l.horoscopeLove, Icons.favorite_outline),
      HoroscopeCategory.health => (l.horoscopeHealth, Icons.spa_outlined),
      HoroscopeCategory.advice => (l.horoscopeAdvice, Icons.lightbulb_outline),
    };

    final palette = BrandPalette.of(context);
    final semantic = context.semantic;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BrandCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: semantic.accentSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: semantic.accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.55,
                      color: palette.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LuckyRow extends StatelessWidget {
  const _LuckyRow({required this.horoscope});

  final Horoscope horoscope;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: context.semantic.auspiciousSurface,
        borderRadius: BorderRadius.circular(BrandCard.radius),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _Lucky(
                label: l.horoscopeLuckyNumber,
                value: '${horoscope.luckyNumber}',
              ),
            ),
            VerticalDivider(width: 1, color: theme.dividerColor),
            Expanded(
              child: _Lucky(
                label: l.horoscopeLuckyColour,
                value: _colourName(l, horoscope.luckyColour),
                // Naming a colour in a different colour reads as a mistake:
                // the card's green accent made "Red" look wrong. Show the
                // swatch instead, so the word and the colour agree.
                swatch: _swatch(horoscope.luckyColour),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The colour itself, for the swatch beside the name.
  static Color? _swatch(String key) => switch (key) {
    'white' => const Color(0xFFF5F5F5),
    'red' => const Color(0xFFE05A4F),
    'yellow' => const Color(0xFFE9C46A),
    'green' => const Color(0xFF62B26B),
    'blue' => const Color(0xFF5B8DEF),
    'orange' => const Color(0xFFE8873B),
    'brown' => const Color(0xFF9A6B4F),
    'gold' => const Color(0xFFD4AF37),
    'silver' => const Color(0xFFB8BCC2),
    'purple' => const Color(0xFF8B6EE8),
    _ => null,
  };

  /// The engine names colours in English; the reader sees their own language.
  static String _colourName(L10n l, String key) => switch (key) {
    'white' => l.colourWhite,
    'red' => l.colourRed,
    'yellow' => l.colourYellow,
    'green' => l.colourGreen,
    'blue' => l.colourBlue,
    'orange' => l.colourOrange,
    'brown' => l.colourBrown,
    'gold' => l.colourGold,
    'silver' => l.colourSilver,
    _ => l.colourPurple,
  };
}

class _Lucky extends StatelessWidget {
  const _Lucky({required this.label, required this.value, this.swatch});

  final String label;
  final String value;

  /// Drawn as a dot beside the value. Null for the lucky number, which is not
  /// a colour.
  final Color? swatch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: BrandPalette.of(context).muted),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (swatch != null) ...[
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: swatch,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.dividerColor),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Flexible(
              child: Text(
                value,
                style: BrandFonts.displayStyle(
                  context,
                  size: 24,
                  color: BrandPalette.of(context).text,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
