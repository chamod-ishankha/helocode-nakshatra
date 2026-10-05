import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../theme/brand_palette.dart';
import '../theme/semantic_colors.dart';
import 'brand_button.dart';

/// Whole-screen states: something went wrong, nothing is here (KAN-95).
///
/// Replaces the bare icons and raw exception text the audit found. A reader
/// gets a mark, a title, one plain sentence and a way forward; the exception
/// goes to the log, where it is useful, and never onto the screen, where it
/// is not.
class StatusView extends StatelessWidget {
  const StatusView({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.warning = false,
    this.action,
    this.secondary,
  });

  final IconData icon;
  final String title;
  final String? body;

  /// Red mark: something failed. Otherwise the mark is neutral.
  final bool warning;

  final ({String label, VoidCallback onPressed})? action;
  final ({String label, VoidCallback onPressed})? secondary;

  @override
  Widget build(BuildContext context) {
    final palette = BrandPalette.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusBadge(icon: icon, warning: warning),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: BrandFonts.displayStyle(
                context,
                size: 26,
                color: palette.text,
              ),
            ),
            if (body case final text?) ...[
              const SizedBox(height: 10),
              Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: palette.muted,
                ),
              ),
            ],
            if (action case final a?) ...[
              const SizedBox(height: 22),
              BrandButton(label: a.label, onPressed: a.onPressed),
            ],
            if (secondary case final s?) ...[
              const SizedBox(height: 4),
              TextButton(
                onPressed: s.onPressed,
                style: TextButton.styleFrom(
                  foregroundColor: context.semantic.accent,
                ),
                child: Text(s.label),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The round mark at the top of a [StatusView], and of the offline card.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.icon,
    this.warning = false,
    this.size = 88,
  });

  final IconData icon;
  final bool warning;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = BrandPalette.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: palette.surface,
        border: Border.all(color: palette.line),
      ),
      child: Icon(
        icon,
        size: size * 0.4,
        color: warning ? context.semantic.inauspicious : palette.text,
      ),
    );
  }
}

/// What a network failure means for this app, said where one happens.
///
/// Not a screen of its own: nothing in the app stops working offline. The
/// chart, the almanac and the reports are all worked out on the phone; only
/// the backup, ads and purchases go out. So the one place a reader meets a
/// dead network — signing in — gets this card, which says so, rather than a
/// red line that sounds like the whole app is broken.
class OfflineNotice extends StatelessWidget {
  const OfflineNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final palette = BrandPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const StatusBadge(icon: Icons.wifi_off_rounded, size: 48),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.stateOfflineTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l.stateOfflineBody,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: palette.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A placeholder block that shimmers while the real thing is worked out.
///
/// Shaped like what it stands in for, so the page does not jump when the
/// content arrives — which a spinner in the middle of an empty screen always
/// did. Still when the phone asks for reduced motion.
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.width, required this.height, this.radius});

  final double? width;
  final double height;
  final double? radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = BrandPalette.of(context);
    final radius = BorderRadius.circular(widget.radius ?? 18);

    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          // A band of the raised surface sweeping left to right across the
          // flat one, the mock's 200%-wide gradient moved by its offset.
          final t = _controller.value * 2 - 1;
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment(-1 + t * 2, 0),
                end: Alignment(1 + t * 2, 0),
                colors: [palette.surface, palette.surfaceHigh, palette.surface],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A screen's worth of [Skeleton]s while a page is first worked out: a title,
/// a row, a large card and four tiles, as on Home, with the reason underneath.
class PageSkeleton extends StatelessWidget {
  const PageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = BrandPalette.of(context);

    Widget pair() => const Row(
      children: [
        Expanded(child: Skeleton(height: 84)),
        SizedBox(width: 10),
        Expanded(child: Skeleton(height: 84)),
      ],
    );

    return Semantics(
      liveRegion: true,
      label: L10n.of(context).stateCalculating,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        children: [
          const FractionallySizedBox(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: 0.6,
            child: Skeleton(height: 44),
          ),
          const SizedBox(height: 14),
          const Skeleton(height: 40),
          const SizedBox(height: 16),
          const Skeleton(height: 210, radius: 28),
          const SizedBox(height: 14),
          pair(),
          const SizedBox(height: 10),
          pair(),
          const SizedBox(height: 14),
          ExcludeSemantics(
            child: Text(
              L10n.of(context).stateCalculating,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: palette.muted),
            ),
          ),
        ],
      ),
    );
  }
}

/// A few list rows' worth of [Skeleton]s, for lists inside a page.
class ListSkeleton extends StatelessWidget {
  const ListSkeleton({super.key, this.rows = 3, this.height = 56});

  final int rows;
  final double height;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < rows; i++)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Skeleton(height: height, radius: 14),
        ),
    ],
  );
}

/// A list inside a page that could not load: one plain line and a retry.
///
/// What [StatusView] is for a whole screen. The cause goes to the log; the
/// screen used to print it — "Could not load places: FormatException: …" —
/// which helped nobody holding the phone.
class InlineRetry extends StatelessWidget {
  const InlineRetry({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = BrandPalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: palette.muted),
            ),
            TextButton.icon(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: context.semantic.accent,
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(L10n.of(context).stateTryAgain),
            ),
          ],
        ),
      ),
    );
  }
}
