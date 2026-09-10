import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/db/profile_store.dart';
import '../../../core/purchases/entitlements.dart';
import '../../../core/purchases/purchase_controller.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../onboarding/data/profile_repository.dart';
import '../../purchases/presentation/paywall.dart';

/// Switching between saved charts (KAN-19).
///
/// The storage has supported several profiles since Drift landed; this is the
/// part that lets anyone use them. Reading for a parent, a partner or a child
/// is the normal way an almanac gets used here, and it is the headline Pro
/// feature the epic was built around.
///
/// ## The first chart is never gated
///
/// A user who has entered their own details keeps them whatever they have
/// paid. The gate is on adding a *second* person, which is the point at which
/// this stops being "the app" and starts being the feature.
class ProfilesScreen extends ConsumerWidget {
  const ProfilesScreen({super.key});

  Future<void> _addAnother(BuildContext context, WidgetRef ref) async {
    if (!ref.read(featureProvider(PaidFeature.multipleProfiles))) {
      await showPaywall(context, ref, reason: PaywallReason.multipleProfiles);
      return;
    }
    if (!context.mounted) return;

    // Straight into onboarding, which is already the only birth-details
    // editor there is. It writes through ProfileNotifier.add rather than
    // save when it was opened this way.
    context.push(Routes.addProfile);
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    SavedProfile saved,
  ) async {
    final l = L10n.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.profilesRemoveConfirm(saved.profile.name)),
        content: Text(l.profilesRemoveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              l.profilesRemove,
              style: TextStyle(color: AppColors.inauspicious),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref.read(profileProvider.notifier).remove(saved.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context);
    final theme = Theme.of(context);
    final locale = ref.watch(localeProvider);
    final saved = ref.watch(savedProfilesProvider);
    final dates = DateFormat.yMMMd(locale.code);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.profilesTitle),
        leading: BackButton(onPressed: () => popOrHome(context)),
      ),
      body: saved.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        // A database that would not open is not an error worth a red screen:
        // the app still works with the one profile in preferences.
        error: (_, _) => _Notice(text: l.profilesUnavailable),
        data: (profiles) => profiles.isEmpty
            ? _Notice(text: l.profilesUnavailable)
            : ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (final entry in profiles)
                    ListTile(
                      leading: Icon(
                        entry.isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: entry.isSelected ? AppColors.accent : null,
                      ),
                      title: Text(entry.profile.name),
                      subtitle: Text(
                        '${l.profilesBornOn(dates.format(entry.profile.birthDate))}'
                        ' · ${entry.profile.place.label(locale)}',
                      ),
                      trailing: profiles.length > 1
                          ? IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: AppColors.inauspicious,
                              ),
                              tooltip: l.profilesRemove,
                              onPressed: () =>
                                  _confirmRemove(context, ref, entry),
                            )
                          // The last one has no delete. Removing it would put
                          // the user back at onboarding from a screen that
                          // says nothing about that; "Delete my details" in
                          // Settings is where erasing everything belongs.
                          : null,
                      onTap: () =>
                          ref.read(profileProvider.notifier).switchTo(entry.id),
                    ),

                  const Divider(height: 24),
                  ListTile(
                    leading: const Icon(Icons.person_add_alt),
                    title: Text(l.profilesAdd),
                    onTap: () => _addAnother(context, ref),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      l.profilesBackupNote,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ),
  );
}
