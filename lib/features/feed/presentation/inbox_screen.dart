import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/feed/feed_reads.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/ui/pill_segments.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'feed_page.dart';
import 'notices_tab.dart';
import 'updates_tab.dart';

/// Behind Home's bell: what the app has told its readers, and what each
/// version changed.
class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({this.tab, super.key});

  /// The tab to open on; null for whichever has something new.
  final InboxTab? tab;

  static Future<void> open(BuildContext context, {InboxTab? tab}) =>
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => InboxScreen(tab: tab)));

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  late InboxTab _tab =
      widget.tab ??
      FeedReads.tabToOpen(
        noticesUnread: ref.read(noticesUnreadProvider),
        updatesUnread: ref.read(updatesUnreadProvider),
      );

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return FeedPage(
      title: l.inboxTitle,
      children: [
        PillSegments<InboxTab>(
          segments: [
            (value: InboxTab.notices, label: l.noticesTitle),
            (value: InboxTab.updates, label: l.updatesTitle),
          ],
          selected: _tab,
          onChanged: (t) => setState(() => _tab = t),
          dotLabel: l.feedUnread,
          dotted: {
            if (ref.watch(noticesUnreadProvider)) InboxTab.notices,
            if (ref.watch(updatesUnreadProvider)) InboxTab.updates,
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        switch (_tab) {
          InboxTab.notices => const NoticesTab(),
          InboxTab.updates => const UpdatesTab(),
        },
      ],
    );
  }
}
