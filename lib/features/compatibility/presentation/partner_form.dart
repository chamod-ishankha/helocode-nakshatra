import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/app_locale.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/semantic_colors.dart';
import '../../../core/ui/brand_button.dart';
import '../../../core/ui/brand_field.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../onboarding/data/place_repository.dart';
import '../../onboarding/data/profile_repository.dart';
import '../../onboarding/presentation/birth_wheels_view.dart';
import '../../onboarding/presentation/country_field.dart';
import '../../onboarding/domain/birth_profile.dart';
import '../domain/compatibility_providers.dart';
import '../../../core/ui/state_views.dart';
import '../../../core/logging/app_logger.dart';

/// Collects the partner's birth details.
///
/// A full-screen sheet rather than a dialog: it asks for four things, one of
/// which is a searchable place list, and a dialog on a 360 dp phone leaves no
/// room for that once the keyboard is up.
Future<void> showPartnerForm(BuildContext context, WidgetRef ref) =>
    showModalBottomSheet<void>(
      context: context,
      // Over the tab bar, not under it (KAN-92).
      useRootNavigator: true,
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

  /// Fills the form from one of the reader's saved charts — a spouse or
  /// fiancé already entered once should not have to be typed in again.
  void _fillFrom(BirthProfile p) {
    setState(() {
      _name.text = p.name;
      _date = p.birthDate;
      _time = p.birthTime;
      _timeKnown = p.birthTimeKnown;
      _place = p.place;
      _placeQuery.text = p.place.label(ref.read(localeProvider));
    });
  }

  void _save() {
    if (!_complete) return;
    ref
        .read(partnerProvider.notifier)
        .set(
          partnerFromForm(
            name: _name.text,
            date: _date!,
            time: _time,
            timeKnown: _timeKnown,
            place: _place!,
          ),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final palette = BrandPalette.of(context);
    final semantic = context.semantic;
    final locale = AppLocale.of(context);
    final country = ref.watch(effectiveCountryProvider);
    final results = country.when(
      loading: () => const AsyncValue<List<Place>>.loading(),
      error: AsyncValue<List<Place>>.error,
      data: (cc) => ref.watch(
        placeSearchProvider((countryCode: cc, query: _placeQuery.text)),
      ),
    );

    TextStyle question() => TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: palette.text,
    );

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
            Text(
              l.compatPartnerDetails,
              style: BrandFonts.displayStyle(
                context,
                size: 28,
                color: palette.text,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            _SavedCharts(onPick: _fillFrom),

            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(
                fontFamilyFallback: AppTheme.scriptFallbacks,
                color: palette.text,
              ),
              decoration: brandFieldDecoration(
                context,
                label: l.compatPartnerName,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // The same wheels as onboarding (KAN-82), in place of the
            // Material dialogs it already dropped.
            Text(l.compatPartnerDateQuestion, style: question()),
            const SizedBox(height: AppSpacing.sm),
            BirthDateWheels(
              value: _date,
              onChanged: (d) => setState(() => _date = d),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _date == null
                  ? l.compatPartnerDateWheelHint
                  : DateFormat.yMMMMEEEEd().format(_date!),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: palette.muted),
            ),
            const SizedBox(height: AppSpacing.xl),

            Text(l.compatPartnerTimeQuestion, style: question()),
            const SizedBox(height: AppSpacing.sm),
            BirthTimeWheels(
              value: _time,
              enabled: _timeKnown,
              onChanged: (t) => setState(() => _time = t),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              // Through DateFormat, in the reader's language. This used to
              // build "14:39" by hand, which is English digits and a 24-hour
              // clock in a Sinhala or Tamil app.
              // The time that will be used, always: an untouched wheel is
              // 6:00 AM, and saying "scroll to your time" beside it suggested
              // nothing had been chosen yet.
              !_timeKnown
                  ? l.onboardingTimeUnknown
                  : DateFormat('h:mm a').format(
                      DateTime(
                        2000,
                      ).add(_time ?? BirthProfile.defaultUnknownTime),
                    ),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: palette.muted),
            ),
            const SizedBox(height: AppSpacing.md),
            Material(
              color: !_timeKnown ? semantic.accentSurface : palette.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: !_timeKnown ? semantic.accent : palette.line,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: CheckboxListTile(
                value: !_timeKnown,
                onChanged: (v) => setState(() => _timeKnown = !(v ?? false)),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: semantic.accent,
                title: Text(
                  l.compatPartnerTimeUnknownLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: palette.text,
                  ),
                ),
                subtitle: Text(
                  l.onboardingTimeUnknown,
                  style: TextStyle(color: palette.muted),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            Text(l.compatPartnerPlaceQuestion, style: question()),
            const SizedBox(height: AppSpacing.sm),
            // Scopes the search below it. A partner is often born in a
            // different country from the user, so this is not a formality.
            SizedBox(
              width: double.infinity,
              child: CountryField(
                onChanged: () => setState(() => _place = null),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            TextField(
              controller: _placeQuery,
              style: TextStyle(
                fontFamilyFallback: AppTheme.scriptFallbacks,
                color: palette.text,
              ),
              decoration: brandFieldDecoration(
                context,
                label: l.onboardingPlaceSearch,
                icon: Icons.search_rounded,
              ),
              onChanged: (_) => setState(() => _place = null),
            ),
            const SizedBox(height: AppSpacing.sm),

            if (_place != null)
              Material(
                color: semantic.accentSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: semantic.accent),
                ),
                child: ListTile(
                  leading: Icon(
                    Icons.location_on_outlined,
                    color: semantic.accent,
                  ),
                  title: Text(
                    _place!.label(locale),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: palette.text,
                    ),
                  ),
                  subtitle: Text(
                    _place!.districtLabel(locale),
                    style: TextStyle(color: palette.muted),
                  ),
                  // A tick as well as the gold: chosen, not just highlighted.
                  trailing: Icon(Icons.check_rounded, color: semantic.accent),
                ),
              )
            else
              SizedBox(
                height: 200,
                child: results.when(
                  loading: () => const ListSkeleton(),
                  error: (e, s) {
                    AppLogger.error('Place list failed to load', e, s);
                    return InlineRetry(
                      message: l.placesLoadFailed,
                      onRetry: () {
                        ref.invalidate(countryListProvider);
                        ref.invalidate(placeSearchProvider);
                      },
                    );
                  },
                  data: (places) => places.isEmpty
                      ? Center(
                          child: Text(
                            l.onboardingPlaceNoMatch,
                            style: TextStyle(color: palette.muted),
                          ),
                        )
                      : ListView.builder(
                          itemCount: places.length,
                          itemBuilder: (context, i) => ListTile(
                            dense: true,
                            leading: Icon(
                              Icons.location_on_outlined,
                              color: palette.muted,
                            ),
                            title: Text(
                              places[i].label(locale),
                              style: TextStyle(color: palette.text),
                            ),
                            subtitle: Text(
                              places[i].districtLabel(locale),
                              style: TextStyle(color: palette.muted),
                            ),
                            onTap: () => setState(() {
                              _place = places[i];
                              _placeQuery.text = places[i].label(locale);
                            }),
                          ),
                        ),
                ),
              ),

            const SizedBox(height: AppSpacing.xl),
            BrandButton(
              expand: true,
              onPressed: _complete ? _save : null,
              label: l.continueLabel,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

/// The reader's other saved charts, as one-tap partners. Hidden when there
/// are none besides the reader's own.
class _SavedCharts extends ConsumerWidget {
  const _SavedCharts({required this.onPick});

  final void Function(BirthProfile) onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final others = [
      for (final s in ref.watch(savedProfilesProvider).value ?? const [])
        if (!s.isSelected) s.profile,
    ];
    if (others.isEmpty) return const SizedBox.shrink();

    final l = L10n.of(context);
    final palette = BrandPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.compatPartnerFromSaved,
            style: TextStyle(fontSize: 13, color: palette.muted),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in others)
                ActionChip(
                  avatar: const Icon(Icons.person_outline, size: 18),
                  label: Text(
                    p.name.isEmpty
                        ? DateFormat.yMMMd().format(p.birthDate)
                        : p.name,
                    style: TextStyle(
                      fontFamilyFallback: AppTheme.scriptFallbacks,
                      color: palette.text,
                    ),
                  ),
                  onPressed: () => onPick(p),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
