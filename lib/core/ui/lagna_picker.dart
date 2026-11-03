import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/onboarding/data/profile_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import '../astro/models.dart';
import '../theme/app_spacing.dart';
import '../theme/brand_palette.dart';
import '../theme/semantic_colors.dart';

/// "Do you know your lagna?", for a reader who does not know the birth time
/// ([LagnaWindow]). The twelve rāśi in their usual order, then "I don't know",
/// which keeps sunrise.
///
/// Shared by onboarding and the compatibility partner form, so the two ask
/// the same question the same way.
class LagnaPicker extends ConsumerWidget {
  const LagnaPicker({
    required this.value,
    required this.onChanged,
    this.forPartner = false,
    super.key,
  });

  final Rasi? value;
  final ValueChanged<Rasi?> onChanged;

  /// "Their lagna" rather than "your lagna", on the partner form.
  final bool forPartner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context);
    final palette = BrandPalette.of(context);
    final locale = ref.watch(localeProvider);

    Widget tile(String label, Rasi? rasi) => Expanded(
      child: _Tile(
        label: label,
        selected: value == rasi,
        onTap: () => onChanged(rasi),
      ),
    );

    const gap = SizedBox(width: AppSpacing.sm);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          forPartner ? l.lagnaPickerQuestionPartner : l.lagnaPickerQuestion,
          style: TextStyle(fontWeight: FontWeight.w700, color: palette.text),
        ),
        const SizedBox(height: 2),
        Text(
          forPartner ? l.lagnaPickerHelpPartner : l.lagnaPickerHelp,
          style: TextStyle(fontSize: 13, height: 1.45, color: palette.muted),
        ),
        const SizedBox(height: AppSpacing.md),
        for (var row = 0; row < 4; row++) ...[
          Row(
            children: [
              for (var col = 0; col < 3; col++) ...[
                if (col > 0) gap,
                tile(
                  Rasi.values[row * 3 + col].label(locale),
                  Rasi.values[row * 3 + col],
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Row(children: [tile(l.lagnaPickerUnknown, null)]),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

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
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: selected ? semantic.accent : palette.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: palette.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
