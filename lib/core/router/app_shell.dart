import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/generated/app_localizations.dart';
import '../sync/auth_service.dart';
import '../theme/brand_palette.dart';
import '../theme/semantic_colors.dart';

/// The five screens a reader moves between, and the bar that moves them
/// (KAN-92).
///
/// Home used to be the only way anywhere: four icons in its app bar and a
/// stack of link cards at the bottom, and every other screen a push with a
/// back arrow. A tab keeps its own place — the calendar month you were on, how
/// far down the chart you had scrolled — while you look at another.
///
/// Everything else (horoscope, daśā, saved charts, account, onboarding)
/// opens over the bar, because it is somewhere you go and come back from.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final palette = BrandPalette.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      body: shell,
      bottomNavigationBar: _NavBar(
        index: shell.currentIndex,
        onSelect: (i) => shell.goBranch(
          i,
          // Tapping the tab you are on takes it back to its start.
          initialLocation: i == shell.currentIndex,
        ),
      ),
    );
  }
}

/// Back on the first page of any tab but Today goes to Today rather than
/// closing the app: Today is where every visit starts, and leaving from the
/// calendar because back was pressed once is not what anybody meant.
///
/// On the tab's own first page, not around the whole shell. Android's
/// predictive back asks the innermost navigator whether it will take the
/// gesture, and a tab's navigator holding a single page said no — so a guard
/// on the shell was never asked, and back closed the app.
class BackToToday extends StatelessWidget {
  const BackToToday({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) StatefulNavigationShell.of(context).goBranch(0);
      },
      child: child,
    );
  }
}

class _NavBar extends ConsumerWidget {
  const _NavBar({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context);
    final palette = BrandPalette.of(context);

    // The dot that sat on Home's account icon, now on the tab the account
    // lives under. A phone-only account is the one hint that the backup dies
    // with the phone: worth a quiet mark, not a nag.
    final phoneOnly =
        ref.watch(accountStatusProvider).value?.kind == AccountKind.anonymous;

    final items = [
      (Icons.wb_sunny_outlined, Icons.wb_sunny_rounded, l.today),
      (
        Icons.calendar_month_outlined,
        Icons.calendar_month_rounded,
        l.navCalendar,
      ),
      (Icons.grid_view_outlined, Icons.grid_view_rounded, l.navChart),
      (Icons.favorite_border_rounded, Icons.favorite_rounded, l.navMatch),
      (Icons.more_horiz_rounded, Icons.more_horiz_rounded, l.navMore),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.background,
        border: Border(top: BorderSide(color: palette.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavItem(
                    icon: i == index ? items[i].$2 : items[i].$1,
                    label: items[i].$3,
                    selected: i == index,
                    dot: i == items.length - 1 && phoneOnly,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.dot = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final palette = BrandPalette.of(context);
    final semantic = context.semantic;
    final colour = selected ? semantic.accent : palette.muted;

    return Semantics(
      selected: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // The selected tab carries a filled icon and a pill as well as
              // the gold, so it is not told by colour alone.
              AnimatedContainer(
                // Only the tab being entered animates. The one being left
                // drops its pill at once, so nothing moves on a button the
                // reader did not touch.
                duration: selected
                    ? const Duration(milliseconds: 200)
                    : Duration.zero,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  // A clear gold, not Colors.transparent. That is clear
                  // *black*, and fading to or from it passes through grey:
                  // both the tab being left and the tab being entered
                  // flashed a dark pill, which read as a touch on the wrong
                  // button. Only the opacity should change.
                  color: selected
                      ? semantic.accentSurface
                      : semantic.accentSurface.withValues(alpha: 0),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Badge(
                  isLabelVisible: dot,
                  backgroundColor: semantic.inauspicious,
                  smallSize: 8,
                  child: Icon(icon, size: 22, color: colour),
                ),
              ),
              const SizedBox(height: 4),
              // Scaled down rather than cut: "நாட்காட்டி" in a fifth of a
              // 360 dp screen.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: colour,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
