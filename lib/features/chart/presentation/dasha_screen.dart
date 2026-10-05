import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/ui/round_icon_button.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../onboarding/data/profile_repository.dart';
import 'dasha_timeline.dart';

/// The full daśā timeline, on its own screen (KAN-83).
///
/// Moved off the chart, where it ran for several screens and buried the report
/// tile; the chart now shows the running period and links here. The timeline
/// itself is redrawn in its own ticket (mock 4).
class DashaScreen extends ConsumerWidget {
  const DashaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final palette = BrandPalette.of(context);
    final l = L10n.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: palette.backdrop),
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
            children: [
              Row(
                children: [
                  RoundIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                    onPressed: () => popOrHome(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l.dashaTitle,
                      style: BrandFonts.displayStyle(
                        context,
                        size: 26,
                        color: palette.text,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (profile != null)
                DashaTimeline(
                  birthTimeKnown: profile.birthTimeKnown,
                  showTitle: false,
                ),
              const SizedBox(height: 20),
              Text(
                l.entertainmentOnly,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: palette.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
