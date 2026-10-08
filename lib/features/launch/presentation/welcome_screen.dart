import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_locale.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/semantic_colors.dart';
import '../../../core/ui/brand_button.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../onboarding/data/profile_repository.dart';
import 'intro_art.dart';
import 'launch_scenes.dart';
import '../../../core/ui/disclaimer.dart';

/// Language first, then three slides, then the birth-details questions
/// (KAN-81).
///
/// Language comes before the slides so they are read in the reader's own
/// script. It used to be the first question of onboarding, after which every
/// earlier screen had been in whatever the phone was set to — usually English
/// on phones sold here, whatever the owner reads.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key, this.initialPage = 0});

  /// Where to open. Going back from the first onboarding question lands on
  /// the last slide rather than on the language list again.
  final int initialPage;

  static const pageCount = 4;

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  late final PageController _pages = PageController(
    initialPage: widget.initialPage.clamp(0, WelcomeScreen.pageCount - 1),
  );
  late int _page = widget.initialPage.clamp(0, WelcomeScreen.pageCount - 1);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int page) => _pages.animateToPage(
    page,
    duration: const Duration(milliseconds: 380),
    curve: Curves.easeOutCubic,
  );

  void _toOnboarding() => context.go(Routes.onboarding);

  @override
  Widget build(BuildContext context) {
    final palette = BrandPalette.of(context);

    return PopScope(
      // Back steps through the slides; only on the language list does it
      // leave the app.
      canPop: _page == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goTo(_page - 1);
      },
      child: Scaffold(
        backgroundColor: palette.background,
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: palette.backdrop),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const StaticSky(count: 18),
              SafeArea(
                child: PageView(
                  controller: _pages,
                  onPageChanged: (p) => setState(() => _page = p),
                  children: [
                    _LanguagePage(onContinue: () => _goTo(1)),
                    _IntroPage(
                      index: 1,
                      art: IntroArtKind.onPhone,
                      onNext: () => _goTo(2),
                      onSkip: _toOnboarding,
                    ),
                    _IntroPage(
                      index: 2,
                      art: IntroArtKind.languages,
                      onNext: () => _goTo(3),
                      onSkip: _toOnboarding,
                    ),
                    _IntroPage(
                      index: 3,
                      art: IntroArtKind.private,
                      onNext: _toOnboarding,
                      onSkip: null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguagePage extends ConsumerWidget {
  const _LanguagePage({required this.onContinue});

  final VoidCallback onContinue;

  /// "Choose your language" in each language, written in its own script.
  static const _askedIn = {
    AppLocale.si: 'භාෂාව තෝරන්න',
    AppLocale.ta: 'மொழியைத் தேர்ந்தெடுக்கவும்',
    AppLocale.en: 'Choose your language',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = BrandPalette.of(context);
    final l10n = L10n.of(context);
    final current = ref.watch(localeProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      child: Column(
        children: [
          Text(
            l10n.onboardingChooseLanguage,
            textAlign: TextAlign.center,
            style: BrandFonts.displayStyle(
              context,
              size: 24,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 6),
          // The question in the other two scripts, so it can be answered
          // before the app knows which one to use. Not the current one again:
          // the heading above already says it.
          Text(
            _askedIn.entries
                .where((e) => e.key != current)
                .map((e) => e.value)
                .join(' · '),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamilyFallback: AppTheme.scriptFallbacks,
              fontSize: 13,
              height: 1.6,
              color: palette.muted,
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final locale in AppLocale.values)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _LanguageOption(
                          locale: locale,
                          selected: locale == current,
                          onTap: () =>
                              ref.read(localeProvider.notifier).set(locale),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.welcomeLanguageHint,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: palette.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: BrandButton(
              label: l10n.continueLabel,
              expand: true,
              onPressed: onContinue,
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.locale,
    required this.selected,
    required this.onTap,
  });

  final AppLocale locale;
  final bool selected;
  final VoidCallback onTap;

  /// One letter of the script, so the choice is recognisable before it is
  /// read.
  String get _glyph => switch (locale) {
    AppLocale.si => 'සි',
    AppLocale.ta => 'த',
    AppLocale.en => 'A',
  };

  @override
  Widget build(BuildContext context) {
    final palette = BrandPalette.of(context);
    final semantic = context.semantic;

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? semantic.accentSurface : palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: selected ? semantic.accent : palette.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: semantic.accentSurface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _glyph,
                    style: TextStyle(
                      fontFamily: locale == AppLocale.en
                          ? BrandFonts.display
                          : AppTheme.fontFor(locale),
                      fontFamilyFallback: AppTheme.scriptFallbacks,
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: semantic.accent,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locale.nativeName,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFor(locale),
                          fontFamilyFallback: AppTheme.scriptFallbacks,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: palette.text,
                        ),
                      ),
                      if (locale.nativeName != locale.englishName)
                        Text(
                          locale.englishName,
                          style: TextStyle(fontSize: 13, color: palette.muted),
                        ),
                    ],
                  ),
                ),
                // A tick as well as the gold border: the selection is never
                // carried by colour alone.
                AnimatedOpacity(
                  opacity: selected ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.check_rounded, color: semantic.accent),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  const _IntroPage({
    required this.index,
    required this.art,
    required this.onNext,
    required this.onSkip,
  });

  /// 1..3.
  final int index;
  final IntroArtKind art;
  final VoidCallback onNext;

  /// Null on the last slide, which has nothing left to skip.
  final VoidCallback? onSkip;

  static const _slides = 3;

  @override
  Widget build(BuildContext context) {
    final palette = BrandPalette.of(context);
    final gold = context.semantic.accent;
    final l10n = L10n.of(context);
    final last = index == _slides;
    final latin = Localizations.localeOf(context).languageCode == 'en';

    final (kicker, title, body) = switch (art) {
      IntroArtKind.onPhone => (
        l10n.introOnPhoneKicker,
        l10n.introOnPhoneTitle,
        l10n.introOnPhoneBody,
      ),
      IntroArtKind.languages => (
        l10n.introLanguagesKicker,
        l10n.introLanguagesTitle,
        l10n.introLanguagesBody,
      ),
      IntroArtKind.private => (
        l10n.introPrivateKicker,
        l10n.introPrivateTitle,
        l10n.introPrivateBody,
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 10, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.introProgress(index, _slides),
                  style: TextStyle(fontSize: 13, color: palette.muted),
                ),
              ),
              if (onSkip != null)
                TextButton(
                  onPressed: onSkip,
                  child: Text(
                    l10n.introSkip,
                    style: TextStyle(color: palette.muted),
                  ),
                )
              else
                const SizedBox(height: 48),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: IntroArt(art),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kicker,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.7,
                  fontWeight: FontWeight.w600,
                  color: gold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: BrandFonts.displayStyle(
                  context,
                  size: 30,
                  color: palette.text,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                body,
                style: TextStyle(
                  fontSize: latin ? 16 : 15,
                  height: latin ? 1.5 : 1.55,
                  color: palette.muted,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
          child: last
              ? Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: BrandButton(
                        label: l10n.introStart,
                        expand: true,
                        onPressed: onNext,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Disclaimer(),
                  ],
                )
              : Row(
                  children: [
                    _Dots(
                      active: index - 1,
                      count: _slides,
                      gold: gold,
                      idle: palette.line,
                    ),
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: BrandButton(
                          label: l10n.introNext,
                          trailing: Icons.arrow_forward_rounded,
                          onPressed: onNext,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({
    required this.active,
    required this.count,
    required this.gold,
    required this.idle,
  });

  final int active, count;
  final Color gold, idle;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < count; i++)
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(right: 8),
          width: i == active ? 26 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: i == active ? gold : idle,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
    ],
  );
}
