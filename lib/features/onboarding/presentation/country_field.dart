import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_locale.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/place_repository.dart';

/// The country the place search is scoped to, and a sheet to change it.
///
/// A country picker rather than a country → district → city drill-down.
/// "District" is not a level that exists everywhere: the United States has
/// states and counties, the United Kingdom has counties, India has states and
/// then districts. Three taps only beat typing three letters when the
/// hierarchy is real, and across 244 countries it is not — so the district
/// stays where it is useful, as the line under each place that tells two towns
/// of the same name apart.
class CountryField extends ConsumerWidget {
  const CountryField({super.key, this.onChanged});

  /// Called after a different country is chosen, so the caller can clear a
  /// place that belonged to the old one.
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context);
    final locale = AppLocale.of(context);
    final code = ref.watch(effectiveCountryProvider);
    final countries = ref.watch(countryListProvider);

    final name = switch ((code, countries)) {
      (AsyncData(value: final c), AsyncData(value: final list)) =>
        list
            .where((e) => e.code == c)
            .map((e) => e.label(locale == AppLocale.si, locale == AppLocale.ta))
            .firstOrNull,
      _ => null,
    };

    final palette = BrandPalette.of(context);
    // Styled as the redesign's text fields (KAN-82), since it sits directly
    // above one and is read as the first of a pair.
    return Material(
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: palette.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: name == null ? null : () => _open(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(Icons.public, size: 20, color: palette.muted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name ?? l.placeCountry,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: palette.text,
                  ),
                ),
              ),
              Icon(Icons.expand_more_rounded, color: palette.muted),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CountrySheet(),
    );
    if (picked == null) return;
    ref.read(pickerCountryProvider.notifier).select(picked);
    onChanged?.call();
  }
}

class _CountrySheet extends ConsumerStatefulWidget {
  const _CountrySheet();

  @override
  ConsumerState<_CountrySheet> createState() => _CountrySheetState();
}

class _CountrySheetState extends ConsumerState<_CountrySheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final locale = AppLocale.of(context);
    final countries = ref.watch(countryListProvider);
    final current = ref.watch(effectiveCountryProvider).value;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SizedBox(
        // Tall enough to show a useful number of countries without covering
        // the whole screen, which would hide what the sheet is for.
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Text(
              l.placeCountryPick,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                labelText: l.placeCountrySearch,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: countries.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Center(child: Text(l.onboardingPlaceLoadFailed('$e'))),
                data: (list) {
                  final q = _query.trim().toLowerCase();
                  final matches = q.isEmpty
                      ? list
                      : list.where((c) => c.searchable.contains(q)).toList();
                  if (matches.isEmpty) {
                    return Center(child: Text(l.onboardingPlaceNoMatch));
                  }
                  return ListView.builder(
                    itemCount: matches.length,
                    itemBuilder: (context, i) {
                      final c = matches[i];
                      final selected = c.code == current;
                      return ListTile(
                        dense: true,
                        selected: selected,
                        leading: selected
                            ? const Icon(Icons.check_circle)
                            : const Icon(Icons.public_outlined),
                        title: Text(
                          c.label(
                            locale == AppLocale.si,
                            locale == AppLocale.ta,
                          ),
                        ),
                        onTap: () => Navigator.of(context).pop(c.code),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
