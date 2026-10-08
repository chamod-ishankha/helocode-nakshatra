import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../theme/brand_palette.dart';

/// "For entertainment purposes only", at the foot of a screen.
///
/// Required, not decoration: Play's misrepresentation policy covers
/// fortune-telling, and this line on every screen is the app's standing
/// statement that it makes no predictive claim (docs/play-listing.md). So it
/// stays on every screen, but quietly — the owner found it competing with
/// the content above it. One widget, so the size and colour cannot drift
/// between screens, and so a change to either is made once.
///
/// Still legible on purpose: a disclaimer nobody can read is not one.
class Disclaimer extends StatelessWidget {
  const Disclaimer({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = BrandPalette.of(context);
    return Text(
      L10n.of(context).entertainmentOnly,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 11,
        letterSpacing: 0.2,
        color: palette.muted.withValues(alpha: 0.7),
      ),
    );
  }
}
