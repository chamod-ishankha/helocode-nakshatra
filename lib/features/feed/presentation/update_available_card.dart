import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config_service.dart';
import '../../../core/config/app_locale.dart';
import '../../../core/config/flavor.dart';
import '../../../core/config/version_gate.dart';
import '../../../core/feed/feed_reads.dart';
import '../../../features/onboarding/data/profile_repository.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'inbox_screen.dart';

/// "A newer version is available", once per published latest build.
///
/// A card, not a dialog: it sits under the date row on Home and is read in
/// passing. It says what the update brings when the panel has a note for it,
/// because "the latest fixes" is no reason to go to the store. Dismissing it
/// remembers the build it was for, so the next publish with a higher latest
/// shows it again; the bell keeps the dot until Updates has been opened.
class UpdateAvailableCard extends ConsumerWidget {
  const UpdateAvailableCard({super.key});

  static const _dismissedKey = 'update_available.dismissed_build';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offered = ref.watch(offeredUpdateProvider);
    if (offered == null) return const SizedBox.shrink();
    final prefs = ref.watch(sharedPreferencesProvider);
    if (prefs.getInt(_dismissedKey) == offered) return const SizedBox.shrink();

    final storeUrl = ref
        .watch(appConfigProvider)
        .gateFor(FlavorConfig.current.flavor)
        .storeUrl;
    final note = FeedReads.noteAhead(
      ref.watch(releaseNotesProvider),
      ref.watch(currentReleaseBuildProvider),
    );

    final l = L10n.of(context);
    final palette = Theme.of(context).colorScheme;
    return NoticeCard(
      icon: Icons.system_update_rounded,
      title: note == null
          ? l.updateAvailableTitle
          : l.updateAvailableVersion(note.version),
      body:
          note?.forLocale(AppLocale.of(context)).firstOrNull ??
          l.updateAvailableBody,
      actionLabel: l.updateOpenStore,
      onAction: () => openStore(storeUrl),
      footer: note == null
          ? null
          : Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () =>
                    InboxScreen.open(context, tab: InboxTab.updates),
                style: TextButton.styleFrom(foregroundColor: palette.primary),
                child: Text(l.updateSeeWhatsNew),
              ),
            ),
      onDismiss: () async {
        await prefs.setInt(_dismissedKey, offered);
        ref.invalidate(gateVerdictProvider);
      },
    );
  }
}
