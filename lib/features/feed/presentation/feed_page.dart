import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/ui/round_icon_button.dart';

/// The frame both Notices and Updates sit in: back arrow, title, a list.
class FeedPage extends StatelessWidget {
  const FeedPage({required this.title, required this.children, super.key});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = BrandPalette.of(context);
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
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: BrandFonts.displayStyle(
                        context,
                        size: 26,
                        color: palette.text,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// A small heading between groups on a feed page.
class FeedSectionLabel extends StatelessWidget {
  const FeedSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm, top: AppSpacing.sm),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: BrandPalette.of(context).muted,
      ),
    ),
  );
}
