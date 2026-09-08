import 'package:flutter/material.dart';

import '../../../core/astro/models.dart';
import '../../../core/config/app_locale.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';

/// A graha in a chart cell: its abbreviation, and a retrograde mark.
///
/// Shared by both chart styles so the notation cannot drift apart between
/// them — it did, and both were wrong in the same two ways.
///
/// ## The abbreviation is looked up, not sliced
///
/// It used to be the first two letters of the English name, which is English
/// wherever the app is set (KAN-58). The obvious repair — transliterating "Su"
/// into Sinhala letter by letter — is worse than the bug, because it produces
/// something no reader recognises. [Graha.shortLabel] holds the forms printed
/// charts actually use: රවි for the Sun, කුජ for Mars.
///
/// ## The retrograde mark
///
/// It used to be `℞` appended straight to the abbreviation, rendering as `Ra℞`
/// (KAN-57). Since `℞` is an R with a stroke through it, sitting against
/// another capital it reads as a rendering fault rather than as notation. It is
/// now a smaller raised mark with a hair space in front, so it marks the
/// abbreviation instead of joining it.
///
/// The mark is a letter of the reader's own language, abbreviated from that
/// language's word for retrograde, for the same reason the graha abbreviation
/// is: a Latin R in a Sinhala chart is one more English letter to decode.
///
/// It is separated by a full space rather than the hair space it started with.
/// A hair space is enough between Latin letters and enough in Sinhala, and it
/// was not enough in Tamil: ராகு followed by வ closed up into ராகுவ, which a
/// Tamil reader parses as an inflected form of the graha's name rather than as
/// a mark on it — the same fault as the old `Ra℞`, in a different script.
///
/// The colour is not enough on its own: red says nothing to a reader who
/// cannot separate the reds, and nothing at all in a grey print.
class GrahaLabel extends StatelessWidget {
  const GrahaLabel({
    required this.position,
    this.style,
    this.abbreviated = true,
    super.key,
  });

  final GrahaPosition position;
  final TextStyle? style;

  /// False in the positions table, which has room for the graha's full name.
  ///
  /// The table is why this flag exists rather than a second widget: it had its
  /// own copy of the notation and drew a bare `℞` long after both charts had
  /// stopped, which is the drift this widget was created to prevent — it was
  /// just never told about the third caller.
  final bool abbreviated;

  @override
  Widget build(BuildContext context) {
    final colour = position.isRetrograde
        ? AppColors.inauspicious
        : Theme.of(context).colorScheme.onSurface;
    final base = (style ?? Theme.of(context).textTheme.labelMedium)?.copyWith(
      fontWeight: FontWeight.w600,
      color: colour,
    );

    return Text.rich(
      TextSpan(
        text: abbreviated
            ? position.graha.shortLabel(AppLocale.of(context))
            : position.graha.label(AppLocale.of(context)),
        style: base,
        children: [
          if (position.isRetrograde)
            TextSpan(
              text: ' ${L10n.of(context).chartRetrogradeMark}',
              style: base?.copyWith(
                fontSize: (base.fontSize ?? 12) * 0.72,
                fontFeatures: const [FontFeature.superscripts()],
              ),
            ),
        ],
      ),
    );
  }
}
