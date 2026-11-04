import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config_service.dart';
import '../../../core/config/app_locale.dart';
import '../../../core/config/flavor.dart';
import '../../../core/config/version_gate.dart';
import '../../../core/feed/feed_reads.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/ui/brand_button.dart';
import '../../../core/ui/brand_card.dart';
import '../../../core/whats_new/whats_new.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'feed_page.dart';

/// Every release's notes, newest first, with an update to take at the top.
///
/// A reader on an old build sees what the newer one brings before being
/// asked to fetch it — the reason to update, next to the button that does.
/// The Updates tab of [InboxScreen].
class UpdatesTab extends ConsumerStatefulWidget {
  const UpdatesTab({super.key});

  @override
  ConsumerState<UpdatesTab> createState() => _UpdatesTabState();
}

class _UpdatesTabState extends ConsumerState<UpdatesTab> {
  @override
  void initState() {
    super.initState();
    // Opening it is reading it: the dot goes, including for an update the
    // reader has now seen and chosen not to take yet.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(feedSeenProvider.notifier)
          .sawUpdates(
            ref.read(releaseNotesProvider),
            offer: ref.read(offeredUpdateProvider),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final notes = ref.watch(releaseNotesProvider);
    final current = ref.watch(currentReleaseBuildProvider);
    final updateAvailable = ref.watch(offeredUpdateProvider) != null;
    final storeUrl = ref
        .watch(appConfigProvider)
        .gateFor(FlavorConfig.current.flavor)
        .storeUrl;

    // Unknown build: one list, nothing marked as theirs.
    final newer = current == null
        ? const <ReleaseNote>[]
        : notes.where((n) => n.build > current).toList();
    final yours = current == null
        ? null
        : notes.where((n) => n.build == current).firstOrNull;
    final older = current == null
        ? notes
        : notes.where((n) => n.build < current).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (updateAvailable || newer.isNotEmpty) ...[
          BrandCard(
            tone: BrandCardTone.gold,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.updatesAvailable,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: BrandPalette.of(context).text,
                  ),
                ),
                for (final note in newer) _NoteBody(note: note),
                const SizedBox(height: AppSpacing.md),
                BrandButton(
                  label: l.updateOpenStore,
                  expand: true,
                  leading: const Icon(Icons.system_update_rounded),
                  onPressed: () => openStore(storeUrl),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (yours != null) ...[
          FeedSectionLabel(l.updatesYourVersion),
          BrandCard(child: _NoteBody(note: yours)),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (older.isNotEmpty) ...[
          if (yours != null) FeedSectionLabel(l.updatesEarlier),
          for (final note in older) ...[
            BrandCard(child: _NoteBody(note: note)),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ],
    );
  }
}

class _NoteBody extends StatelessWidget {
  const _NoteBody({required this.note});

  final ReleaseNote note;

  @override
  Widget build(BuildContext context) {
    final palette = BrandPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.sm),
        Text(
          L10n.of(context).settingsVersion('${note.version} (${note.build})'),
          style: TextStyle(fontWeight: FontWeight.w700, color: palette.text),
        ),
        for (final p in note.forLocale(AppLocale.of(context))) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            p,
            style: TextStyle(fontSize: 14, height: 1.5, color: palette.text),
          ),
        ],
      ],
    );
  }
}
