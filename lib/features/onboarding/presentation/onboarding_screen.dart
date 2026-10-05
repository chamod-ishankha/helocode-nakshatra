import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/semantic_colors.dart';
import '../../../core/ui/brand_button.dart';
import '../../../core/ui/brand_field.dart';
import '../../../core/ui/info_notice.dart';
import '../../../core/ui/round_icon_button.dart';
import '../../../l10n/generated/app_localizations.dart';

import '../../../core/config/app_locale.dart';
import '../../../core/router/app_router.dart';
import '../data/place_repository.dart';
import 'country_field.dart';
import '../data/profile_repository.dart';
import '../domain/birth_profile.dart';
import '../domain/birth_wheels.dart';
import 'birth_wheels_view.dart';
import '../../../core/ui/state_views.dart';
import '../../../core/logging/app_logger.dart';

/// Birth-details capture.
///
/// The highest drop-off surface in the app, so it is deliberately forgiving:
/// one question per screen, always resumable by going back, and it never
/// requires a network connection.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.adding = false});

  /// True when this is collecting a *second* person's details (KAN-19).
  ///
  /// Passed from the route rather than read from a provider, because the
  /// wizard has to know before its first build: it decides whether to prefill,
  /// and prefilling is the difference between editing somebody and quietly
  /// duplicating them.
  final bool adding;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;
  final _nameController = TextEditingController();

  int _step = 0;

  /// Name, date, time, place. Language used to be the first step; it moved to
  /// the welcome flow so the intro is read in it too (KAN-81).
  static const _stepCount = 4;

  DateTime? _birthDate;
  Duration? _birthTime;
  bool _birthTimeKnown = true;
  Place? _place;
  bool _saving = false;

  /// True when the wizard was opened to change details that already exist,
  /// rather than to collect them for the first time.
  bool _editing = false;

  @override
  void initState() {
    super.initState();

    // The wizard used to start empty whatever the state of the profile, so
    // even once the route was reachable at all, "edit" meant retyping a name,
    // a date, a time and a town from nothing (KAN-61).
    // Adding a second person starts from nothing. Prefilling with whoever is
    // currently selected would be a trap: every field would look right, and
    // the one the user forgot to change would quietly make two charts the
    // same.
    final existing = widget.adding ? null : ref.read(profileProvider);
    if (existing != null) {
      _editing = true;

      _nameController.text = existing.name;
      _birthDate = existing.birthDate;
      _birthTime = existing.birthTime;
      _birthTimeKnown = existing.birthTimeKnown;
      _place = existing.place;
    }

    _pageController = PageController(initialPage: _step);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  bool get _canAdvance => switch (_step) {
    0 => _nameController.text.trim().isNotEmpty,
    1 => _birthDate != null,
    2 => _birthTime != null || !_birthTimeKnown,
    3 => _place != null,
    _ => false,
  };

  void _next() {
    // The name field keeps focus after its page slides away, and its keyboard
    // then covered the date wheels on the next one.
    FocusScope.of(context).unfocus();
    if (_step == _stepCount - 1) {
      _finish();
      return;
    }
    setState(() => _step++);
    _pageController.animateToPage(
      _step,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  /// Back from the first question returns to the last intro slide, for a new
  /// reader. Editing or adding a person came from Settings or Home, and the
  /// system back button already returns there.
  bool get _backLeavesWizard => _step == 0 && !_editing && !widget.adding;

  void _back() {
    if (_backLeavesWizard) {
      context.go(Routes.welcomeLastSlide);
      return;
    }
    if (_step == 0) return;
    FocusScope.of(context).unfocus();
    setState(() => _step--);
    _pageController.animateToPage(
      _step,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    if (_birthDate == null || _place == null) return;
    setState(() => _saving = true);

    final profile = BirthProfile(
      name: _nameController.text.trim(),
      birthDate: _birthDate!,
      birthTime: _birthTime ?? BirthProfile.defaultUnknownTime,
      place: _place!,
      birthTimeKnown: _birthTimeKnown,
    );

    final notifier = ref.read(profileProvider.notifier);
    // add() inserts a row and selects it; save() overwrites the selected one.
    // Using save() here would silently replace the person the user was
    // looking at with the one they just typed in.
    await (widget.adding ? notifier.add(profile) : notifier.save(profile));
    if (mounted) context.go(Routes.chart);
  }

  @override
  Widget build(BuildContext context) {
    // The system back button does what the arrow does. The wizard is reached
    // with go(), so there is nothing beneath it: without this, back on any
    // question closed the app and lost everything typed so far.
    final handlesBack = _step > 0 || _backLeavesWizard;
    return PopScope(
      canPop: !handlesBack,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: _scaffold(context),
    );
  }

  Widget _scaffold(BuildContext context) {
    final palette = BrandPalette.of(context);
    final l10n = L10n.of(context);
    final last = _step == _stepCount - 1;

    return Scaffold(
      backgroundColor: palette.background,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: palette.backdrop),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 24, 0),
                child: Row(
                  children: [
                    if (_step > 0 || _backLeavesWizard) ...[
                      RoundIconButton(
                        icon: Icons.arrow_back_rounded,
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).backButtonTooltip,
                        onPressed: _back,
                      ),
                      const SizedBox(width: 14),
                    ],
                    Expanded(
                      child: _Progress(step: _step, count: _stepCount),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _NameStep(
                      controller: _nameController,
                      onChanged: () => setState(() {}),
                    ),
                    _DateStep(
                      value: _birthDate,
                      onChanged: (d) => setState(() => _birthDate = d),
                    ),
                    _TimeStep(
                      value: _birthTime,
                      known: _birthTimeKnown,
                      onChanged: (t, known) => setState(() {
                        _birthTime = t;
                        _birthTimeKnown = known;
                      }),
                    ),
                    _PlaceStep(
                      value: _place,
                      birthDate: _birthDate,
                      birthTime: _birthTimeKnown
                          ? _birthTime
                          : BirthProfile.defaultUnknownTime,
                      onChanged: (p) => setState(() => _place = p),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: BrandButton(
                    expand: true,
                    label: last ? l10n.onboardingSeeChart : l10n.continueLabel,
                    onPressed: _canAdvance && !_saving ? _next : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One gold segment per question, filled up to this one.
class _Progress extends StatelessWidget {
  const _Progress({required this.step, required this.count});

  final int step, count;

  @override
  Widget build(BuildContext context) {
    final gold = context.semantic.accent;
    final idle = BrandPalette.of(context).line;
    return Semantics(
      label: '${step + 1} / $count',
      child: Row(
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 4,
                decoration: BoxDecoration(
                  color: i <= step ? gold : idle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StepScaffold extends StatelessWidget {
  const _StepScaffold({
    required this.title,
    this.subtitle,
    required this.child,
    this.scrollable = true,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  /// False for a step that scrolls its own content.
  ///
  /// Every other step is a short fixed column, which fits until a keyboard
  /// takes half the screen — then it overflows, and it overflows sooner in
  /// Sinhala and Tamil, where the question and its explanation run to more
  /// lines than the English they were laid out against.
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final palette = BrandPalette.of(context);

    // The question and its explanation scroll with the step, not above it.
    // Scrolling only the child was not enough: in a 380px-tall window — a
    // phone with the keyboard up, which is exactly the state this step is
    // reached in — the heading and subtitle alone can use the whole column
    // and overflow before the child is given anything at all.
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: BrandFonts.displayStyle(
            context,
            size: 30,
            color: palette.text,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle!,
            style: TextStyle(fontSize: 14, height: 1.5, color: palette.muted),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        if (scrollable) child else Expanded(child: child),
      ],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: scrollable ? SingleChildScrollView(child: content) : content,
    );
  }
}

class _NameStep extends StatelessWidget {
  const _NameStep({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    final palette = BrandPalette.of(context);

    return _StepScaffold(
      title: L10n.of(context).onboardingNameQuestion,
      subtitle: L10n.of(context).onboardingNameHelp,
      child: Column(
        children: [
          // The first letter of what is typed, as the chart's monogram: the
          // name is only a label, and this shows what it labels.
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final text = value.text.trim();
              return ExcludeSemantics(
                child: Container(
                  width: 96,
                  height: 96,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: semantic.accentSurface,
                    border: Border.all(color: semantic.accent),
                  ),
                  child: Text(
                    text.isEmpty
                        ? '?'
                        : String.fromCharCodes(
                            text.runes.take(1),
                          ).toUpperCase(),
                    style: BrandFonts.displayStyle(
                      context,
                      size: 40,
                      color: semantic.accent,
                    ).copyWith(height: 1),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: controller,
            autofocus: true,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.words,
            style: TextStyle(
              fontFamilyFallback: AppTheme.scriptFallbacks,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: palette.text,
            ),
            decoration: brandFieldDecoration(
              context,
              label: L10n.of(context).onboardingNameLabel,
            ),
            onChanged: (_) => onChanged(),
          ),
        ],
      ),
    );
  }
}

class _DateStep extends StatelessWidget {
  const _DateStep({required this.value, required this.onChanged});
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = BrandPalette.of(context);
    return _StepScaffold(
      title: L10n.of(context).onboardingDateQuestion,
      subtitle: L10n.of(context).onboardingDateHelp,
      child: Column(
        children: [
          BirthDateWheels(value: value, onChanged: onChanged),
          const SizedBox(height: AppSpacing.md),
          // The chosen date read back in full, weekday and all, so a wheel
          // left one notch off is caught here rather than in the chart.
          Text(
            value == null
                ? L10n.of(context).onboardingDateWheelHint
                : DateFormat.yMMMMEEEEd().format(value!),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: palette.muted),
          ),
        ],
      ),
    );
  }
}

class _TimeStep extends StatelessWidget {
  const _TimeStep({
    required this.value,
    required this.known,
    required this.onChanged,
  });

  final Duration? value;
  final bool known;
  final void Function(Duration?, bool known) onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = BrandPalette.of(context);
    final semantic = context.semantic;
    final l10n = L10n.of(context);

    return _StepScaffold(
      title: l10n.onboardingTimeQuestion,
      subtitle: l10n.onboardingTimeHelp,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BirthTimeWheels(
            value: value,
            enabled: known,
            onChanged: (t) => onChanged(t, true),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            !known
                ? l10n.onboardingTimeUnknown
                : value == null
                ? l10n.onboardingTimeWheelHint
                : _format(value!),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: palette.muted),
          ),
          const SizedBox(height: AppSpacing.lg),
          // A large share of users genuinely do not know their birth time.
          // Blocking them here loses the install outright, so offer the
          // traditional sunrise fallback and be honest about what it costs.
          Material(
            color: !known ? semantic.accentSurface : palette.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: !known ? semantic.accent : palette.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: CheckboxListTile(
              value: !known,
              onChanged: (v) => onChanged(value, !(v ?? false)),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: semantic.accent,
              title: Text(
                l10n.onboardingTimeUnknownLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: palette.text,
                ),
              ),
              subtitle: Text(
                l10n.onboardingTimeUnknown,
                style: TextStyle(color: palette.muted),
              ),
            ),
          ),
          if (!known) ...[
            const SizedBox(height: AppSpacing.md),
            InfoNotice(text: l10n.onboardingTimeUnknownHelp),
          ],
        ],
      ),
    );
  }

  /// The chosen time, in the reader's language.
  ///
  /// This used to build "AM"/"PM" by hand, so the one screen that asks for a
  /// birth time printed it in English while every screen that shows one used
  /// முற்பகல் or පෙ.ව.. `DateFormat` follows `Intl.defaultLocale`, which
  /// app.dart sets from the chosen language.
  String _format(Duration d) =>
      DateFormat('h:mm a').format(DateTime(2000).add(d));
}

class _PlaceStep extends ConsumerStatefulWidget {
  const _PlaceStep({
    required this.value,
    required this.birthDate,
    required this.birthTime,
    required this.onChanged,
  });
  final Place? value;

  /// For the timezone note: the offset a place had depends on the date, and
  /// for Sri Lanka between 1996 and 2006 it was not +5:30.
  final DateTime? birthDate;
  final Duration? birthTime;
  final ValueChanged<Place> onChanged;

  @override
  ConsumerState<_PlaceStep> createState() => _PlaceStepState();
}

class _PlaceStepState extends ConsumerState<_PlaceStep> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final country = ref.watch(effectiveCountryProvider);
    final palette = BrandPalette.of(context);
    final semantic = context.semantic;
    final l10n = L10n.of(context);
    final results = country.when(
      loading: () => const AsyncValue<List<Place>>.loading(),
      error: AsyncValue<List<Place>>.error,
      data: (cc) =>
          ref.watch(placeSearchProvider((countryCode: cc, query: _query))),
    );

    final chosen = widget.value;
    final offset = chosen == null || widget.birthDate == null
        ? null
        : BirthWheels.offsetAt(
            chosen.timezone,
            widget.birthDate!,
            widget.birthTime ?? BirthProfile.defaultUnknownTime,
          );

    return _StepScaffold(
      // Its results are a ListView with its own scrolling, which needs a
      // bounded height — a SingleChildScrollView would give it infinity.
      scrollable: false,
      title: l10n.onboardingPlaceQuestion,
      subtitle: l10n.onboardingPlaceHelp,
      child: Column(
        children: [
          // The country comes first because it scopes everything below it.
          // Two places in this data are called Colombo — one in Sri Lanka and
          // one in Brazil — and nine are called Victoria.
          SizedBox(
            width: double.infinity,
            child: CountryField(onChanged: () => setState(() {})),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            decoration: brandFieldDecoration(
              context,
              label: l10n.onboardingPlaceSearch,
              icon: Icons.search_rounded,
            ),
            style: TextStyle(
              fontFamilyFallback: AppTheme.scriptFallbacks,
              color: palette.text,
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          if (chosen != null) ...[
            const SizedBox(height: AppSpacing.sm),
            // Which zone the chart will be cast in, said out loud. A wrong
            // timezone is the worst bug this app can have and nothing else on
            // screen would show it.
            InfoNotice(
              text: offset == null
                  ? l10n.onboardingPlaceZoneOnly(chosen.timezone)
                  : l10n.onboardingPlaceZone(
                      chosen.timezone,
                      BirthWheels.offsetLabel(offset),
                    ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: results.when(
              loading: () => const ListSkeleton(),
              error: (e, s) {
                AppLogger.error('Place list failed to load', e, s);
                return InlineRetry(
                  message: l10n.placesLoadFailed,
                  onRetry: () {
                    ref.invalidate(countryListProvider);
                    ref.invalidate(placeSearchProvider);
                  },
                );
              },
              data: (places) => places.isEmpty
                  ? Center(
                      child: Text(
                        l10n.onboardingPlaceNoMatch,
                        style: TextStyle(color: palette.muted),
                      ),
                    )
                  : ListView.separated(
                      itemCount: places.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (context, i) {
                        final p = places[i];
                        // Name alone is not an identity once the list is
                        // worldwide — the coordinates are what differ between
                        // two towns that share a name.
                        final selected =
                            chosen?.en == p.en &&
                            chosen?.latitude == p.latitude &&
                            chosen?.longitude == p.longitude;
                        return Material(
                          color: selected
                              ? semantic.accentSurface
                              : Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(
                              color: selected
                                  ? semantic.accent
                                  : Colors.transparent,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            selected: selected,
                            selectedColor: palette.text,
                            leading: Icon(
                              Icons.location_on_outlined,
                              color: selected ? semantic.accent : palette.muted,
                            ),
                            // A tick as well as the gold: the choice is never
                            // carried by colour alone.
                            trailing: selected
                                ? Icon(
                                    Icons.check_rounded,
                                    color: semantic.accent,
                                  )
                                : null,
                            title: Text(
                              p.label(locale),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: palette.text,
                              ),
                            ),
                            subtitle: Text(
                              // The English name stays alongside for a reader
                              // who knows the town by it — the district beside
                              // it should still be in their language.
                              locale == AppLocale.en
                                  ? p.district
                                  : '${p.en} · ${p.districtLabel(locale)}',
                              style: TextStyle(color: palette.muted),
                            ),
                            onTap: () => widget.onChanged(p),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
