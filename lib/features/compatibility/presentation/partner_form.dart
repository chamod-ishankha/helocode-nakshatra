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
      backgroundColor: BrandPalette.of(context).background,
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
            Text(l.onboardingDateQuestion, style: question()),
            const SizedBox(height: AppSpacing.sm),
            BirthDateWheels(
              value: _date,
              onChanged: (d) => setState(() => _date = d),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _date == null
                  ? l.onboardingDateWheelHint
                  : DateFormat.yMMMMEEEEd().format(_date!),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: palette.muted),
            ),
            const SizedBox(height: AppSpacing.xl),

            Text(l.onboardingTimeQuestion, style: question()),
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
              !_timeKnown
                  ? l.onboardingTimeUnknown
                  : _time == null
                  ? l.onboardingTimeWheelHint
                  : DateFormat('h:mm a').format(DateTime(2000).add(_time!)),
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
                  l.onboardingTimeUnknownLabel,
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

            Text(l.onboardingPlaceQuestion, style: question()),
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
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      Center(child: Text(l.onboardingPlaceLoadFailed('$e'))),
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
