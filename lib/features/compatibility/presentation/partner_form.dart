import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/app_locale.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../onboarding/data/place_repository.dart';
import '../../onboarding/data/profile_repository.dart';
import '../../onboarding/domain/birth_profile.dart';
import '../domain/compatibility_providers.dart';

/// Collects the partner's birth details.
///
/// A full-screen sheet rather than a dialog: it asks for four things, one of
/// which is a searchable place list, and a dialog on a 360 dp phone leaves no
/// room for that once the keyboard is up.
Future<void> showPartnerForm(BuildContext context, WidgetRef ref) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _PartnerForm(),
    );

class _PartnerForm extends ConsumerStatefulWidget {
  const _PartnerForm();

  @override
  ConsumerState<_PartnerForm> createState() => _PartnerFormState();
}

class _PartnerFormState extends ConsumerState<_PartnerForm> {
  final _name = TextEditingController();
  final _placeQuery = TextEditingController();

  DateTime? _date;
  Duration? _time;
  bool _timeKnown = true;
  Place? _place;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(partnerProvider);
    if (existing != null) {
      _name.text = existing.name;
      _date = existing.birthDate;
      _time = existing.birthTime;
      _timeKnown = existing.birthTimeKnown;
      _place = existing.place;
      // initState cannot reach Localizations, and the provider is the
      // same source MaterialApp.locale is driven from.
      _placeQuery.text = existing.place.label(ref.read(localeProvider));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _placeQuery.dispose();
    super.dispose();
  }

  bool get _complete => _date != null && _place != null;

  void _save() {
    if (!_complete) return;
    ref
        .read(partnerProvider.notifier)
        .set(
          BirthProfile(
            name: _name.text.trim(),
            birthDate: _date!,
            // Sunrise, matching what onboarding assumes when the time is unknown.
            birthTime: _timeKnown
                ? (_time ?? const Duration(hours: 6))
                : const Duration(hours: 6),
            place: _place!,
            birthTimeKnown: _timeKnown && _time != null,
          ),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final theme = Theme.of(context);
    final results = ref.watch(placeSearchProvider(_placeQuery.text));

    return Padding(
      // Lifts the sheet clear of the keyboard rather than letting it cover
      // the field being typed into.
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.compatPartnerDetails, style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),

            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l.compatPartnerName,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today, size: 18),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date ?? DateTime(1995),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                  helpText: l.onboardingDateLabel,
                );
                if (picked != null) setState(() => _date = picked);
              },
              label: Text(
                _date == null
                    ? l.onboardingDatePickerTitle
                    : DateFormat.yMMMd().format(_date!),
              ),
            ),
            const SizedBox(height: 8),

            OutlinedButton.icon(
              icon: const Icon(Icons.schedule, size: 18),
              onPressed: !_timeKnown
                  ? null
                  : () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                          hour: _time?.inHours ?? 6,
                          minute: (_time?.inMinutes ?? 0) % 60,
                        ),
                        helpText: l.onboardingTimeLabel,
                      );
                      if (picked != null) {
                        setState(
                          () => _time = Duration(
                            hours: picked.hour,
                            minutes: picked.minute,
                          ),
                        );
                      }
                    },
              label: Text(
                !_timeKnown || _time == null
                    ? l.onboardingTimePickerTitle
                    : '${_time!.inHours.toString().padLeft(2, '0')}:'
                          '${(_time!.inMinutes % 60).toString().padLeft(2, '0')}',
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: !_timeKnown,
              onChanged: (v) => setState(() => _timeKnown = !v),
              title: Text(
                l.onboardingTimeUnknown,
                style: theme.textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _placeQuery,
              decoration: InputDecoration(
                labelText: l.onboardingPlaceSearch,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() => _place = null),
            ),
            const SizedBox(height: 8),

            if (_place != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.place),
                title: Text(_place!.label(AppLocale.of(context))),
                subtitle: Text(_place!.districtLabel(AppLocale.of(context))),
              )
            else
              SizedBox(
                height: 180,
                child: results.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      Center(child: Text(l.onboardingPlaceLoadFailed('$e'))),
                  data: (places) => places.isEmpty
                      ? Center(child: Text(l.onboardingPlaceNoMatch))
                      : ListView.builder(
                          itemCount: places.length,
                          itemBuilder: (context, i) => ListTile(
                            dense: true,
                            title: Text(places[i].label(AppLocale.of(context))),
                            subtitle: Text(
                              places[i].districtLabel(AppLocale.of(context)),
                            ),
                            onTap: () => setState(() {
                              _place = places[i];
                              _placeQuery.text = places[i].label(
                                AppLocale.of(context),
                              );
                            }),
                          ),
                        ),
                ),
              ),

            const SizedBox(height: 16),
            FilledButton(
              onPressed: _complete ? _save : null,
              child: Text(l.continueLabel),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
