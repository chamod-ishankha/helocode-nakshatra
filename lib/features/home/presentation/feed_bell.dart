import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/feed/feed_reads.dart';
import '../../../core/ui/pill_segments.dart';
import '../../../core/ui/round_icon_button.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../feed/presentation/inbox_screen.dart';

/// The way to notices and updates, in Home's header.
///
/// Rarely needed and read in passing, so it takes no room from the day: two
/// full-width buttons here cost a seventh of the first screen every morning,
/// for something with news on few of them. The dot says when there is some.
class FeedBell extends ConsumerWidget {
  const FeedBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context);
    final unread =
        ref.watch(noticesUnreadProvider) || ref.watch(updatesUnreadProvider);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        RoundIconButton(
          icon: Icons.notifications_none_rounded,
          tooltip: unread ? '${l.inboxTitle}, ${l.feedUnread}' : l.inboxTitle,
          onPressed: () => InboxScreen.open(context),
        ),
        if (unread)
          const Positioned(
            top: 1,
            right: 1,
            // Decorative here: the tooltip above already says it.
            child: ExcludeSemantics(child: UnreadDot()),
          ),
      ],
    );
  }
}
