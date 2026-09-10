import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/semantic_colors.dart';
import '../../../l10n/generated/app_localizations.dart';

import '../../../core/config/app_locale.dart';
import '../../../core/router/app_router.dart';
import '../data/place_repository.dart';
import '../data/profile_repository.dart';
import '../domain/birth_profile.dart';

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
  static const _stepCount = 5;

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

      // Straight to the name. The language step is behind them — they chose
      // once, and the screen they came from has a language row of its own.
      _step = 1;

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
    0 => true,
    1 => _nameController.text.trim().isNotEmpty,
    2 => _birthDate != null,
    3 => _birthTime != null || !_birthTimeKnown,
    4 => _place != null,
    _ => false,
  };

  void _next() {
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

  void _back() {
    if (_step == 0) return;
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
    return Scaffold(
      appBar: AppBar(
        leading: _step > (_editing ? 1 : 0)
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: _back)
            : null,
        title: LinearProgressIndicator(
          value: (_step + 1) / _stepCount,
          minHeight: 4,
        ),
        titleSpacing: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _LanguageStep(onChanged: () => setState(() {})),
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
                    onChanged: (p) => setState(() => _place = p),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _canAdvance && !_saving ? _next : null,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _step == _stepCount - 1
                              ? L10n.of(context).onboardingSeeChart
                              : L10n.of(context).continueLabel,
                        ),
                ),
              ),
            ),
          ],
        ),
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
    final theme = Theme.of(context);

    // The question and its explanation scroll with the step, not above it.
    // Scrolling only the child was not enough: in a 380px-tall window — a
    // phone with the keyboard up, which is exactly the state this step is
    // reached in — the heading and subtitle alone can use the whole column
    // and overflow before the child is given anything at all.
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.headlineSmall),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 24),
        if (scrollable) child else Expanded(child: child),
      ],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: scrollable ? SingleChildScrollView(child: content) : content,
    );
  }
}

class _LanguageStep extends ConsumerWidget {
  const _LanguageStep({required this.onChanged});
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider);
    return _StepScaffold(
      // Its own ListView scrolls the three languages.
      scrollable: false,
      title: L10n.of(context).onboardingChooseLanguage,
      subtitle: 'භාෂාව තෝරන්න · மொழியைத் தேர்ந்தெடுக்கவும்',
      child: ListView(
        children: [
          // A plain selectable tile rather than RadioListTile: the Radio
          // group API is deprecated in this Flutter version, and a check mark
          // reads more clearly at this size anyway.
          for (final locale in AppLocale.values)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                selected: locale == current,
                onTap: () async {
                  await ref.read(localeProvider.notifier).set(locale);
                  onChanged();
                },
                title: Text(locale.nativeName),
                subtitle: locale.nativeName == locale.englishName
                    ? null
                    : Text(locale.englishName),
                trailing: locale == current
                    ? const Icon(Icons.check_circle)
                    : const Icon(Icons.circle_outlined),
              ),
            ),
        ],
      ),
    );
  }
}

class _NameStep extends StatelessWidget {
  const _NameStep({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: L10n.of(context).onboardingNameQuestion,
      subtitle: L10n.of(context).onboardingNameHelp,
      child: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: L10n.of(context).onboardingNameLabel,
          border: const OutlineInputBorder(),
        ),
        onChanged: (_) => onChanged(),
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
    return _StepScaffold(
      title: L10n.of(context).onboardingDateQuestion,
      subtitle: L10n.of(context).onboardingDateHelp,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today),
            label: Text(
              value == null
                  ? L10n.of(context).onboardingDatePickerTitle
                  : DateFormat('d MMMM yyyy').format(value!),
            ),
            onPressed: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: value ?? DateTime(now.year - 25),
                // The ephemeris is validated over this span; outside it the
                // engine refuses rather than returning a silently wrong chart.
                firstDate: DateTime(1900),
                lastDate: now,
                helpText: L10n.of(context).onboardingDateLabel,
              );
              if (picked != null) onChanged(picked);
            },
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
    final theme = Theme.of(context);
    return _StepScaffold(
      title: L10n.of(context).onboardingTimeQuestion,
      subtitle: L10n.of(context).onboardingTimeHelp,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.schedule),
            label: Text(
              value == null || !known
                  ? L10n.of(context).onboardingTimePickerTitle
                  : _format(value!),
            ),
            onPressed: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: value == null
                    ? const TimeOfDay(hour: 6, minute: 0)
                    : TimeOfDay(
                        hour: value!.inHours,
                        minute: value!.inMinutes % 60,
                      ),
                helpText: L10n.of(context).onboardingTimeLabel,
              );
              if (picked != null) {
                onChanged(
                  Duration(hours: picked.hour, minutes: picked.minute),
                  true,
                );
              }
            },
          ),
          const SizedBox(height: 24),
          // A large share of users genuinely do not know their birth time.
          // Blocking them here loses the install outright, so offer the
          // traditional sunrise fallback and be honest about what it costs.
          CheckboxListTile(
            value: !known,
            onChanged: (v) => onChanged(value, !(v ?? false)),
            title: Text(L10n.of(context).onboardingTimeUnknownLabel),
            subtitle: Text(L10n.of(context).onboardingTimeUnknown),
            contentPadding: EdgeInsets.zero,
          ),
          if (!known)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.semantic.accent.withValues(alpha: 0.10),
                border: Border.all(
                  color: context.semantic.accent.withValues(alpha: 0.4),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                L10n.of(context).onboardingTimeUnknownHelp,
                style: theme.textTheme.bodySmall,
              ),
            ),
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
  const _PlaceStep({required this.value, required this.onChanged});
  final Place? value;
  final ValueChanged<Place> onChanged;

  @override
  ConsumerState<_PlaceStep> createState() => _PlaceStepState();
}

class _PlaceStepState extends ConsumerState<_PlaceStep> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final results = ref.watch(placeSearchProvider(_query));

    return _StepScaffold(
      // Its results are a ListView with its own scrolling, which needs a
      // bounded height — a SingleChildScrollView would give it infinity.
      scrollable: false,
      title: L10n.of(context).onboardingPlaceQuestion,
      subtitle: L10n.of(context).onboardingPlaceHelp,
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              labelText: L10n.of(context).onboardingPlaceSearch,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: results.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(L10n.of(context).onboardingPlaceLoadFailed('$e')),
              ),
              data: (places) => places.isEmpty
                  ? Center(child: Text(L10n.of(context).onboardingPlaceNoMatch))
                  : ListView.builder(
                      itemCount: places.length,
                      itemBuilder: (context, i) {
                        final p = places[i];
                        final selected = widget.value?.en == p.en;
                        return ListTile(
                          selected: selected,
                          leading: Icon(
                            selected
                                ? Icons.check_circle
                                : Icons.location_on_outlined,
                          ),
                          title: Text(p.label(locale)),
                          subtitle: Text(
                            // The English name stays alongside for a reader
                            // who knows the town by it — the district beside
                            // it should still be in their language.
                            locale == AppLocale.en
                                ? p.district
                                : '${p.en} · ${p.districtLabel(locale)}',
                          ),
                          onTap: () => widget.onChanged(p),
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
