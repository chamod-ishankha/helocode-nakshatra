import '../../../core/theme/semantic_colors.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    return PopScope(
      // The system back gesture pops on its own; this only needs to know it
      // happened. Blocking a back press to show an ad would be both hostile
      // and against AdMob's own placement rules.
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _leaving();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.horoscopeTitle),
          leading: BackButton(
            onPressed: () {
              _leaving();
              popOrHome(context);
            },
          ),
        ),
        body: ListView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            if (!bothSame && lagna != null && moon != null) ...[
              _AxisToggle(axis: axis),
              const SizedBox(height: 12),
            ],

            if (sign != null)
              Text(
                sign.label(locale),
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            if (bothSame)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  l.horoscopeSameSign,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

            // The lagna moves a sign every two hours, so without a birth time it
            // is a guess. Saying nothing would present a coin flip as a reading.
            if (axis == HoroscopeAxis.lagna &&
                ref.watch(lagnaIsApproximateProvider))
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  l.horoscopeLagnaApproximate,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.semantic.inauspicious,
                  ),
                ),
              ),

            const SizedBox(height: 16),

            if (locked)
              RewardedUnlockCard(
                unlock: RewardedUnlock.futureDay,
                title: l.unlockFutureTitle,
                body: l.unlockFutureBody,
              )
            else if (horoscope == null)
              // No chart yet, or no bundled copy for this build. Neither is
              // worth an error: the rest of the app still works.
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  l.horoscopeUnavailable,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else ...[
              for (final category in HoroscopeEngine.sectionOrder)
                if (horoscope[category] case final text?)
                  _Section(category: category, text: text),
              const SizedBox(height: 8),
              _LuckyRow(horoscope: horoscope),
            ],

            const SizedBox(height: 24),
            Text(
              l.entertainmentOnly,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lagna or rāśi. Same shape as the compatibility screen's system toggle, so
/// the two "which system are you reading" choices in the app look alike.
class _AxisToggle extends ConsumerWidget {
  const _AxisToggle({required this.axis});

  final HoroscopeAxis axis;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context);

    return SegmentedButton<HoroscopeAxis>(
      segments: [
        ButtonSegment(
          value: HoroscopeAxis.lagna,
          label: Text(l.horoscopeByLagna),
        ),
        ButtonSegment(
          value: HoroscopeAxis.rasi,
          label: Text(l.horoscopeByRasi),
        ),
      ],
      selected: {axis},
      onSelectionChanged: (s) =>
          ref.read(horoscopeAxisProvider.notifier).set(s.first),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.category, required this.text});

  final HoroscopeCategory category;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: context.semantic.accent),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: context.semantic.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(text, style: theme.textTheme.bodyMedium),
        ],
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

    return Card(
      elevation: 0,
      color: context.semantic.auspicious.withValues(alpha: 0.07),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: context.semantic.auspicious.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _Lucky(
              label: l.horoscopeLuckyNumber,
              value: '${horoscope.luckyNumber}',
            ),
            Container(width: 1, height: 32, color: theme.dividerColor),
            _Lucky(
              label: l.horoscopeLuckyColour,
              value: _colourName(l, horoscope.luckyColour),
              // Naming a colour in a different colour reads as a mistake: the
              // card's green accent made "Red" look wrong. Show the swatch
              // instead, so the word and the colour agree.
              swatch: _swatch(horoscope.luckyColour),
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
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
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
              const SizedBox(width: 8),
            ],
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                color: context.semantic.auspicious,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
