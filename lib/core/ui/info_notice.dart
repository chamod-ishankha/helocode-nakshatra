import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/semantic_colors.dart';

/// What a notice is telling the reader (KAN-51).
///
/// The tone decides the colour — and, for [caution], forces an icon. See
/// [InfoNotice] for why that is a constructor requirement rather than advice.
enum NoticeTone {
  /// Context the reader may want. Gold tint, no border.
  info,

  /// Something to be careful about: an approximate lagna, a dosha, a window
  /// to avoid. Outlined in the inauspicious colour.
  caution,
}

/// The boxed line of explanation that appears on most screens.
///
/// It existed four times over before this — as `_Note`, `_Notice` and
/// `_Warning` — with three different corner radii and two different paddings,
/// which is what happens when a component is re-typed rather than reused.
///
/// ## Why a caution notice cannot be built without an icon
///
/// Colour must never be the only thing carrying meaning: roughly one Sri
/// Lankan man in twelve cannot distinguish this app's inauspicious red from
/// its auspicious green, and no palette fixes that — see [SemanticColors] for
/// the arithmetic. The rule is easy to write down and easy to forget at the
/// point of use, so it is enforced here instead: [NoticeTone.caution] defaults
/// to a warning icon and cannot be given none. A reader who sees no colour
/// still sees the mark.
class InfoNotice extends StatelessWidget {
  const InfoNotice({
    required this.text,
    this.tone = NoticeTone.info,
    this.icon,
    super.key,
  });

  final String text;
  final NoticeTone tone;

  /// Overrides the default mark. Null keeps the tone's own — which for
  /// [NoticeTone.caution] is never nothing.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final caution = tone == NoticeTone.caution;
    final colour = caution
        ? context.semantic.inauspicious
        : context.semantic.accent;

    final mark = icon ?? (caution ? Icons.warning_amber_rounded : null);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        // A flat tint of the inauspicious red over a light surface reads as
        // muddy brown — hit once already on the rāhu card. Caution notices are
        // outlined instead, and keep the surface underneath them.
        color: caution ? null : colour.withValues(alpha: 0.07),
        border: caution
            ? Border.all(color: colour.withValues(alpha: 0.5))
            : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mark != null) ...[
            Icon(mark, size: 18, color: colour),
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: caution ? null : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A line of explanation with nothing boxed around it.
///
/// For the empty states — "no prices right now", "no saved charts" — where a
/// box would draw attention to an absence rather than explain it.
class QuietNotice extends StatelessWidget {
  const QuietNotice({required this.text, this.padding, super.key});

  final String text;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding ?? const EdgeInsets.all(AppSpacing.xl),
    child: Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ),
  );
}
