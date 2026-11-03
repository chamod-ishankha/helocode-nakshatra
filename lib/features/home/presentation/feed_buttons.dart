import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/feed/feed_reads.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/semantic_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../feed/presentation/notices_screen.dart';
import '../../feed/presentation/updates_screen.dart';

/// Notices and Updates, on Home.
///
/// The app has no notification tab and no bell in a header; these two are
/// where a reader looks back at what the app said and what each version
/// changed. A gold dot says there is something they have not opened yet.
class FeedButtons extends ConsumerWidget {
  const FeedButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context);
    return Column(
      children: [
        _FeedButton(
          icon: Icons.campaign_outlined,
          title: l.noticesTitle,
          hint: l.noticesHint,
          unread: ref.watch(noticesUnreadProvider),
          onTap: () => NoticesScreen.open(context),
        ),
        const SizedBox(height: AppSpacing.sm),
        _FeedButton(
          icon: Icons.system_update_rounded,
          title: l.updatesTitle,
          hint: l.updatesHint,
          unread: ref.watch(updatesUnreadProvider),
          onTap: () => UpdatesScreen.open(context),
        ),
      ],
    );
  }
}

class _FeedButton extends StatelessWidget {
  const _FeedButton({
    required this.icon,
    required this.title,
    required this.hint,
    required this.unread,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String hint;
  final bool unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = BrandPalette.of(context);
    final semantic = context.semantic;
    return Semantics(
      button: true,
      child: Material(
        color: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: palette.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: semantic.accentSurface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: semantic.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: palette.text,
                        ),
                      ),
                      Text(
                        hint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: palette.muted),
                      ),
                    ],
                  ),
                ),
                if (unread)
                  Semantics(
                    label: L10n.of(context).feedUnread,
                    child: Container(
                      width: 9,
                      height: 9,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: semantic.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                Icon(Icons.chevron_right_rounded, color: palette.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
