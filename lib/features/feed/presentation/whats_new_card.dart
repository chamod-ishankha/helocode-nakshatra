import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_locale.dart';
import '../../../core/config/version_gate.dart';
import '../../../core/feed/feed_reads.dart';
import '../../../core/whats_new/whats_new.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'inbox_screen.dart';

/// Home's one-time "What's new" after an update ([WhatsNew]).
///
/// The first two paragraphs of the newest release, and the rest a tap away
/// on Updates: a whole release note on Home pushes the day off the screen.
class WhatsNewCard extends ConsumerWidget {
  const WhatsNewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final builds = ref.watch(whatsNewThisLaunchProvider);
    if (builds.isEmpty || ref.watch(whatsNewClosedProvider)) {
      return const SizedBox.shrink();
    }
    // The newest of the releases this reader has not seen that has a note. A
    // build shipped without one says nothing rather than something old.
    final note = ref
        .watch(releaseNotesProvider)
        .where((n) => builds.contains(n.build))
        .firstOrNull;
    if (note == null) return const SizedBox.shrink();

    final l = L10n.of(context);
    return NoticeCard(
      icon: Icons.auto_awesome_outlined,
      title: l.whatsNewTitle,
      body: note.forLocale(AppLocale.of(context)).take(2).join('\n\n'),
      actionLabel: l.whatsNewSeeAll,
      onAction: () => InboxScreen.open(context, tab: InboxTab.updates),
      onDismiss: () async => ref.read(whatsNewClosedProvider.notifier).close(),
    );
  }
}
