import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/config/app_locale.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../data/place_repository.dart';
import '../data/profile_repository.dart';
import '../domain/birth_profile.dart';

/// Birth-details capture.
///
/// The highest drop-off surface in the app, so it is deliberately forgiving:
/// one question per screen, always resumable by going back, and it never
/// requires a network connection.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  final _nameController = TextEditingController();

  int _step = 0;
  static const _stepCount = 5;

  DateTime? _birthDate;
  Duration? _birthTime;
  bool _birthTimeKnown = true;
  Place? _place;
  bool _saving = false;

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

    await ref.read(profileProvider.notifier).save(profile);
    if (mounted) context.go(Routes.chart);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _step > 0
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
                          _step == _stepCount - 1 ? 'See my chart' : 'Continue',
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
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
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
          Expanded(child: child),
        ],
      ),
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
      title: 'Choose your language',
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
      title: 'What is your name?',
      subtitle: 'Used only to label your chart. It stays on this device.',
      child: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Name',
          border: OutlineInputBorder(),
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
      title: 'When were you born?',
      subtitle: 'The date decides your rāśi and every planetary position.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today),
            label: Text(
              value == null
                  ? 'Select date of birth'
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
                helpText: 'Date of birth',
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
      title: 'What time were you born?',
      subtitle:
          'The ascendant changes roughly every two hours, so this '
          'matters more than the date for house placements.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.schedule),
            label: Text(
              value == null || !known
                  ? 'Select time of birth'
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
                helpText: 'Time of birth',
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
            title: const Text("I don't know my birth time"),
            subtitle: const Text('We will use sunrise (6:00 AM)'),
            contentPadding: EdgeInsets.zero,
          ),
          if (!known)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.10),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.4),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Your rāśi, nakṣatra and planetary positions will still be '
                'accurate. The ascendant and house placements will be '
                'approximate, and the app will mark them as such.',
                style: theme.textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }

  String _format(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final suffix = h < 12 ? 'AM' : 'PM';
    final h12 = h % 12 == 0 ? 12 : h % 12;
    return '$h12:${m.toString().padLeft(2, '0')} $suffix';
  }
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
      title: 'Where were you born?',
      subtitle:
          'Coordinates set the ascendant. Search in Sinhala, Tamil or '
          'English.',
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Search town or district',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: results.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Could not load places: $e')),
              data: (places) => places.isEmpty
                  ? const Center(child: Text('No matching place'))
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
                            locale == AppLocale.en
                                ? p.district
                                : '${p.en} · ${p.district}',
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
