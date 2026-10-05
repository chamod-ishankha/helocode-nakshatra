import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/db/profile_store.dart';
import '../../../core/router/app_router.dart';
import '../../../core/config/app_locale.dart';
import '../../../core/purchases/entitlements.dart';
import '../../../core/purchases/purchase_controller.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/semantic_colors.dart';
import '../../../core/ui/brand_button.dart';
import '../../../core/ui/brand_card.dart';
import '../../../core/ui/round_icon_button.dart';
import '../../../core/ui/info_notice.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../onboarding/data/profile_repository.dart';
import 'add_family_member.dart';
import '../../../core/purchases/nudges.dart';
import '../../purchases/presentation/pro_nudge.dart';
import '../../../core/ui/state_views.dart';

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

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    SavedProfile saved,
  ) async {
    final l = L10n.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BrandPalette.of(context).background,
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
              style: TextStyle(color: context.semantic.inauspicious),
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
    final palette = BrandPalette.of(context);
    final locale = ref.watch(localeProvider);
    final saved = ref.watch(savedProfilesProvider);
    final owned = ref.watch(featureProvider(PaidFeature.multipleProfiles));

    Widget page(List<Widget> children) => Scaffold(
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
                    onPressed: () => popOrHome(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l.profilesTitle,
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
              const SizedBox(height: AppSpacing.xl),
              Text(
                l.entertainmentOnly,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: palette.muted),
              ),
            ],
          ),
        ),
      ),
    );

    return saved.when(
      loading: () => page([const ListSkeleton(height: 72)]),
      // A database that would not open is not an error worth a red screen:
      // the app still works with the one profile in preferences.
      error: (_, _) => page([QuietNotice(text: l.profilesUnavailable)]),
      data: (profiles) => profiles.isEmpty
          ? page([QuietNotice(text: l.profilesUnavailable)])
          : page([
              // Somebody who met the gate adding a chart, on a later day
              // (KAN-75). Almost always renders nothing.
              const ProNudge(triggers: [NudgeTrigger.family]),
              BrandCard(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Column(
                  children: [
                    for (var i = 0; i < profiles.length; i++)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          border: i == 0
                              ? null
                              : Border(top: BorderSide(color: palette.line)),
                        ),
                        child: _PersonRow(
                          entry: profiles[i],
                          locale: locale,
                          // The last one has no remove. Removing it would put
                          // the user back at onboarding from a screen that
                          // says nothing about that; "Delete my details" in
                          // Settings is where erasing everything belongs.
                          onRemove: profiles.length > 1
                              ? () => _confirmRemove(context, ref, profiles[i])
                              : null,
                          onTap: () => ref
                              .read(profileProvider.notifier)
                              .switchTo(profiles[i].id),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _AddMember(
                owned: owned,
                onTap: () => addFamilyMember(context, ref),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l.profilesBackupNote,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: palette.muted,
                ),
              ),
            ]),
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.entry,
    required this.locale,
    required this.onRemove,
    required this.onTap,
  });

  final SavedProfile entry;
  final AppLocale locale;
  final VoidCallback? onRemove;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final palette = BrandPalette.of(context);
    final semantic = context.semantic;
    final dates = DateFormat.yMMMd(locale.code);
    final profile = entry.profile;
    final name = profile.name.isEmpty ? '—' : profile.name;
    final showing = entry.isSelected;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: showing ? semantic.accent : semantic.accentSurface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                String.fromCharCodes(name.runes.take(1)).toUpperCase(),
                style: BrandFonts.displayStyle(
                  context,
                  size: 20,
                  color: showing ? palette.background : semantic.accent,
                ).copyWith(height: 1),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${l.profilesBornOn(dates.format(profile.birthDate))}'
                    ' · ${profile.place.label(locale)}',
                    style: TextStyle(fontSize: 13, color: palette.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Said in words. The selection used to be a gold radio icon and
            // nothing else, while this string sat unused in the ARB files.
            if (showing)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: semantic.accentSurface,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '✓ ${l.profilesShowing}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: semantic.accent,
                  ),
                ),
              )
            else if (onRemove != null)
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: semantic.inauspicious,
                ),
                tooltip: l.profilesRemove,
                onPressed: onRemove,
              ),
          ],
        ),
      ),
    );
  }
}

class _AddMember extends StatelessWidget {
  const _AddMember({required this.owned, required this.onTap});

  final bool owned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final semantic = context.semantic;
    return BrandButton(
      tone: BrandButtonTone.outline,
      expand: true,
      onPressed: onTap,
      leading: const Icon(Icons.person_add_alt_1_rounded),
      label: l.familyAddTitle,
      // Says it is Pro before the tap, so the paywall that follows is not a
      // surprise. "Pro" is the product's name and reads the same in all three
      // languages.
      trailingWidget: owned
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: semantic.accentSurface,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                'Pro',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: semantic.accent,
                ),
              ),
            ),
    );
  }
}
