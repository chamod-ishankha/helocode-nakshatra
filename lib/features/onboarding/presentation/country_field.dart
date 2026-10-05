import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_locale.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/semantic_colors.dart';
import '../../../core/ui/brand_field.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/place_repository.dart';
import '../../../core/ui/state_views.dart';
import '../../../core/logging/app_logger.dart';

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
      // Over the tab bar, and over the partner form when opened from it.
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
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
    final palette = BrandPalette.of(context);
    final countries = ref.watch(countryListProvider);
    final current = ref.watch(effectiveCountryProvider).value;

    Widget message(String text) => Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: palette.muted),
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        // Tall enough to show a useful number of countries without covering
        // the whole screen, which would hide what the sheet is for.
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.placeCountryPick,
              style: BrandFonts.displayStyle(
                context,
                size: 24,
                color: palette.text,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              autofocus: true,
              style: TextStyle(color: palette.text),
              decoration: brandFieldDecoration(
                context,
                label: l.placeCountrySearch,
                icon: Icons.search,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: countries.when(
                loading: () => const ListSkeleton(rows: 6, height: 48),
                error: (e, s) {
                  AppLogger.error('Country list failed to load', e, s);
                  return InlineRetry(
                    message: l.placesLoadFailed,
                    onRetry: () => ref.invalidate(countryListProvider),
                  );
                },
                data: (list) {
                  final q = _query.trim().toLowerCase();
                  // Sri Lanka first while nothing is typed: most readers are
                  // picking it back after trying another, and it should not
                  // be 200 rows down between Spain and Sudan.
                  final matches = q.isEmpty
                      ? homeCountryFirst(list)
                      : list.where((c) => c.searchable.contains(q)).toList();
                  if (matches.isEmpty) {
                    return message(l.onboardingPlaceNoMatch);
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    itemCount: matches.length,
                    itemBuilder: (context, i) {
                      final c = matches[i];
                      return _CountryRow(
                        name: c.label(
                          locale == AppLocale.si,
                          locale == AppLocale.ta,
                        ),
                        selected: c.code == current,
                        // A rule under the pinned country, so it does not
                        // read as the first of an alphabetical list.
                        divider: q.isEmpty && i == 0 && c.code == homeCountry,
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

class _CountryRow extends StatelessWidget {
  const _CountryRow({
    required this.name,
    required this.selected,
    required this.divider,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final bool divider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = BrandPalette.of(context);
    final semantic = context.semantic;

    final row = Material(
      color: selected ? semantic.accentSurface : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: selected ? BorderSide(color: semantic.accent) : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? semantic.accent : palette.text,
                  ),
                ),
              ),
              // A tick as well as the gold, so the choice is not told by
              // colour alone.
              if (selected)
                Icon(Icons.check_rounded, size: 20, color: semantic.accent),
            ],
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: divider
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                row,
                Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 4),
                  child: Divider(height: 1, color: palette.line),
                ),
              ],
            )
          : row,
    );
  }
}
