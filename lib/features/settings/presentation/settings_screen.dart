import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_locale.dart';
import '../../../core/config/chart_style.dart';
import '../../../core/config/theme_preference.dart';
import '../../../core/licensing.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/error/result.dart';
import '../../../core/router/app_router.dart';
import '../../../core/sync/auth_service.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/ui/brand_card.dart';
import '../../../core/ui/round_icon_button.dart';
import '../../../core/theme/semantic_colors.dart';
import '../../../core/ads/ad_consent_tile.dart';
import '../../../core/ads/ad_gate.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../account/presentation/auth_messages.dart';
import '../../purchases/presentation/pro_tiles.dart';
import '../../../core/notifications/notification_coordinator.dart';
import '../../../core/notifications/notification_prefs.dart';
import '../../../core/notifications/notification_service.dart';
import '../../onboarding/data/profile_repository.dart';

/// Settings (KAN-30).
///
/// Only what actually works appears here. That rule is why reminders arrived
/// with KAN-33, restore purchases with KAN-35 and saved charts with KAN-19,
/// each when the thing behind the row existed — a row that does nothing is
/// worse than a row that is missing.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  /// Published from the helocode-site repo. Play requires the privacy policy
  /// to be reachable without installing the app, which is why these are links
  /// rather than bundled text.
  static const _privacyUrl =
      'https://chamod-ishankha.github.io/helocode-site/nakshatra/privacy.html';
  static const _termsUrl =
      'https://chamod-ishankha.github.io/helocode-site/nakshatra/terms.html';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context);
    final palette = BrandPalette.of(context);
    final accountKind =
        ref.watch(accountStatusProvider).value?.kind ?? AccountKind.none;

    return Scaffold(
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
                  Expanded(
                    child: Text(
                      l.settingsTitle,
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

              // What the reader holds, first (KAN-90). It was a row like any
              // other, halfway down.
              const ProTiles(),

              _Group(
                title: l.settingsSectionProfile,
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(l.settingsEditProfile),
                    subtitle: Text(l.settingsEditProfileHint),
                    trailing: const Icon(Icons.chevron_right),
                    // Onboarding is the only editor there is, and it already
                    // handles every field. Sending the user back through it
                    // beats a second form that could drift out of step with
                    // the first — as long as the route says it is an edit, or
                    // the redirect turns it away.
                    onTap: () => context.push(Routes.editProfile),
                  ),
                  ListTile(
                    leading: const Icon(Icons.groups_outlined),
                    title: Text(l.profilesTitle),
                    subtitle: Text(l.profilesSettingsHint),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(Routes.profiles),
                  ),
                  // Here as well as on Home, which loses its app-bar icons to
                  // the bottom navigation: the backup state belongs with the
                  // reader's other details.
                  ListTile(
                    leading: const Icon(Icons.cloud_outlined),
                    title: Text(l.accountTitle),
                    subtitle: Text(switch (accountKind) {
                      AccountKind.permanent => l.accountSavedToEmailHelp,
                      AccountKind.anonymous => l.accountPhoneOnly,
                      AccountKind.none => l.accountUnavailable,
                    }),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(Routes.account),
                  ),
                ],
              ),

              _Group(
                title: l.settingsSectionAppearance,
                children: const [
                  _ThemeTile(),
                  _LanguageTile(),
                  _ChartStyleTile(),
                ],
              ),

              _Group(
                title: l.settingsSectionReminders,
                children: const [_ReminderTiles()],
              ),

              _Group(
                title: l.settingsSectionData,
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.delete_outline,
                      color: context.semantic.inauspicious,
                    ),
                    title: Text(
                      l.settingsDeleteData,
                      style: TextStyle(color: context.semantic.inauspicious),
                    ),
                    subtitle: Text(l.settingsDeleteHint),
                    onTap: () => _confirmDelete(context, ref),
                  ),
                  // Only where UMP says consent was collected, and never for
                  // somebody who bought their way out of advertising entirely
                  // (KAN-40).
                  if (!ref.watch(adFreeEntitlementProvider))
                    const AdConsentTile(),
                ],
              ),

              _Group(
                title: l.settingsSectionAbout,
                children: [
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: Text(l.settingsPrivacy),
                    trailing: const Icon(Icons.open_in_new, size: 18),
                    onTap: () => _open(context, _privacyUrl),
                  ),
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text(l.settingsTerms),
                    trailing: const Icon(Icons.open_in_new, size: 18),
                    onTap: () => _open(context, _termsUrl),
                  ),
                  // Not a nicety. The Swiss Ephemeris is used under the AGPL,
                  // which obliges us to offer the source to whoever receives
                  // the binary, and the place data is CC BY, which makes
                  // attribution a condition of using it at all. `Licensing`
                  // has carried both facts since the start and nothing
                  // displayed them, so neither reached a user.
                  ListTile(
                    leading: const Icon(Icons.balance_outlined),
                    title: Text(l.settingsLicences),
                    subtitle: Text(l.settingsLicencesHint),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const _LicencesPage(),
                      ),
                    ),
                  ),
                  const _VersionTile(),
                ],
              ),

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
  }

  /// Deleting is irreversible and takes the backup with it, so it asks first.
  static Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l = L10n.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BrandPalette.of(context).background,
        title: Text(l.settingsDeleteTitle),
        content: Text(l.settingsDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.semantic.inauspicious,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.settingsDeleteConfirm),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Data first, then the identity. The Firestore document is filed under
    // the uid and the rules only let its owner touch it, so deleting the
    // account first would strand the document permanently out of reach.
    await ref.read(profileProvider.notifier).clear();
    final account = await ref.read(authServiceProvider).deleteAccount();

    if (!context.mounted) return;

    // Report what actually happened. Claiming success when the backup was
    // unreachable is the failure this whole change exists to stop.
    final failure = account.failureOrNull;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          failure is AuthFailure
              ? authMessage(context, failure)
              : l.settingsDeleted,
        ),
      ),
    );

    // Leave regardless. The local profile is gone either way, so every screen
    // behind this one is reading data that no longer exists. To the welcome
    // rather than straight into the questions: with nothing kept, this is a
    // new reader, and a new reader is asked for a language first (KAN-81).
    context.go(Routes.welcome);
  }

  static Future<void> _open(BuildContext context, String url) async {
    final failed = L10n.of(context).settingsLinkFailed;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final ok = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!ok) messenger.showSnackBar(SnackBar(content: Text(failed)));
    } on Object catch (e, s) {
      AppLogger.warn('Could not open $url', e, s);
      messenger.showSnackBar(SnackBar(content: Text(failed)));
    }
  }
}

/// A titled card of rows (KAN-90).
///
/// The rows stay [ListTile]s inside it: the KAN-60 layout tests measure them,
/// and a tile already handles a long Tamil title wrapping beside its icon.
class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = BrandPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 22, 6, 8),
          child: Text(
            title,
            style: TextStyle(fontSize: 13, color: palette.muted),
          ),
        ),
        BrandCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: ListTileTheme(
            data: ListTileThemeData(
              iconColor: palette.muted,
              textColor: palette.text,
              subtitleTextStyle: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: palette.muted,
              ),
            ),
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: palette.line,
                    ),
                  children[i],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ThemeTile extends ConsumerWidget {
  const _ThemeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context);
    final current = ref.watch(themePreferenceProvider);

    String label(ThemePreference p) => switch (p) {
      ThemePreference.system => l.themeSystem,
      ThemePreference.light => l.themeLight,
      ThemePreference.dark => l.themeDark,
    };

    return _ChoiceTile<ThemePreference>(
      icon: Icons.brightness_6_outlined,
      title: l.settingsTheme,
      hint: l.settingsThemeHint,
      value: current,
      values: ThemePreference.values,
      label: label,
      onChanged: (p) => ref.read(themePreferenceProvider.notifier).set(p),
    );
  }
}

class _LanguageTile extends ConsumerWidget {
  const _LanguageTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider);

    return _ChoiceTile<AppLocale>(
      icon: Icons.translate,
      title: L10n.of(context).settingsLanguage,
      value: current,
      values: AppLocale.values,
      // Native names, for the same reason as the header switcher: a Tamil
      // speaker looks for தமிழ், not for "Tamil".
      label: (locale) => locale.nativeName,
      onChanged: (locale) => ref.read(localeProvider.notifier).set(locale),
    );
  }
}

class _ChartStyleTile extends ConsumerWidget {
  const _ChartStyleTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(chartStyleProvider);

    return _ChoiceTile<ChartStyle>(
      icon: Icons.grid_on,
      title: L10n.of(context).settingsChartStyle,
      value: current,
      values: ChartStyle.values,
      label: (style) => style.label(L10n.of(context)),
      onChanged: (style) => ref.read(chartStyleProvider.notifier).set(style),
    );
  }
}

/// A settings row that picks one of a few values.
///
/// The obvious way to build this is a `DropdownButton` in `ListTile.trailing`,
/// and that is what these rows used to be. It breaks (KAN-60): a dropdown
/// sizes itself to its **widest item**, `ListTile` gives the trailing slot its
/// width before the text gets any, and so the length of one translation
/// decides how much room the title has. The Tamil for "Follow the phone" is
/// `தொலைபேசியைப் பின்பற்று`, which left the theme row's text about one
/// character wide and wrapped its hint into a vertical ribbon forty lines
/// tall.
///
/// So the value goes in the text column, where it can use the whole row, and
/// the choosing happens in a sheet where every option gets full width. Nothing
/// here is sized by the longest translation.
///
/// Capping the dropdown's width instead would have kept the layout and lost
/// the words: the Tamil option would ellipsize to something unreadable, which
/// is not better than a broken row for the reader who needs it.
class _ChoiceTile<T> extends StatelessWidget {
  const _ChoiceTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.values,
    required this.label,
    required this.onChanged,
    this.hint,
  });

  final IconData icon;
  final String title;
  final T value;
  final List<T> values;
  final String Function(T) label;
  final ValueChanged<T> onChanged;

  /// Optional explanation, shown under the current value.
  final String? hint;

  Future<void> _choose(BuildContext context) async {
    final chosen = await showModalBottomSheet<T>(
      context: context,
      // Over the tab bar, not under it (KAN-92).
      useRootNavigator: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              // 16 to match ListTile's own content padding, so the title lines
              // up with the options under it rather than sitting in from them.
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final v in values)
              ListTile(
                title: Text(label(v)),
                trailing: v == value
                    ? Icon(Icons.check, color: context.semantic.accent)
                    : null,
                onTap: () => Navigator.of(context).pop(v),
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );

    if (chosen != null && chosen != value) onChanged(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label(value),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: context.semantic.accent,
            ),
          ),
          if (hint != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(hint!, style: theme.textTheme.bodySmall),
            ),
        ],
      ),
      trailing: const Icon(Icons.expand_more),
      onTap: () => _choose(context),
    );
  }
}

/// The reminder switches (KAN-33).
///
/// The Android 13 permission is asked for **here**, when the user turns a
/// reminder on, rather than at launch. Onboarding is already the highest
/// drop-off surface in the app, and a permission dialog in front of a benefit
/// nobody has felt yet gets refused — after which Android will not ask again.
///
/// If it is refused the switch goes back to off rather than sitting on while
/// nothing arrives, and the screen says where to turn it back on.
class _ReminderTiles extends ConsumerWidget {
  const _ReminderTiles();

  /// Invalidate before awaiting: a FutureProvider that has already completed
  /// returns the old result, so without this the await is on the previous
  /// run and the change never reaches the scheduler.
  Future<void> _rearm(WidgetRef ref) async {
    ref.invalidate(notificationRefreshProvider);
    await ref.read(notificationRefreshProvider.future);
  }

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref, {
    required bool on,
    required Future<void> Function(bool) apply,
  }) async {
    if (on && !await NotificationService.requestPermission()) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(L10n.of(context).settingsNotificationsBlocked)),
      );
      return;
    }

    await apply(on);
    await _rearm(ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context);
    final prefs = ref.watch(notificationPrefsProvider);
    final notifier = ref.read(notificationPrefsProvider.notifier);

    return Column(
      children: [
        SwitchListTile(
          activeThumbColor: context.semantic.accent,
          secondary: const Icon(Icons.wb_twilight),
          title: Text(l.settingsDailyReminder),
          subtitle: Text(l.settingsDailyReminderHint),
          value: prefs.daily,
          onChanged: (on) =>
              _toggle(context, ref, on: on, apply: notifier.setDaily),
        ),
        if (prefs.daily)
          ListTile(
            leading: const SizedBox(width: AppSpacing.xl),
            title: Text(l.settingsReminderTime),
            trailing: Text(
              MaterialLocalizations.of(context).formatTimeOfDay(
                TimeOfDay(hour: prefs.hour, minute: prefs.minute),
              ),
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: context.semantic.accent),
            ),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(hour: prefs.hour, minute: prefs.minute),
              );
              if (picked == null) return;

              await notifier.setTime(picked.hour, picked.minute);
              await _rearm(ref);
            },
          ),
        SwitchListTile(
          activeThumbColor: context.semantic.accent,
          secondary: const Icon(Icons.brightness_2_outlined),
          title: Text(l.settingsPoyaReminder),
          subtitle: Text(l.settingsPoyaReminderHint),
          value: prefs.poya,
          onChanged: (on) =>
              _toggle(context, ref, on: on, apply: notifier.setPoya),
        ),
        SwitchListTile(
          activeThumbColor: context.semantic.accent,
          secondary: const Icon(Icons.celebration_outlined),
          title: Text(l.settingsFestivalReminder),
          subtitle: Text(l.settingsFestivalReminderHint),
          value: prefs.festival,
          onChanged: (on) =>
              _toggle(context, ref, on: on, apply: notifier.setFestival),
        ),
        SwitchListTile(
          activeThumbColor: context.semantic.accent,
          secondary: const Icon(Icons.timeline),
          title: Text(l.settingsDashaReminder),
          subtitle: Text(l.settingsDashaReminderHint),
          value: prefs.dasha,
          onChanged: (on) =>
              _toggle(context, ref, on: on, apply: notifier.setDasha),
        ),
        SwitchListTile(
          activeThumbColor: context.semantic.accent,
          secondary: const Icon(Icons.swap_horiz),
          title: Text(l.settingsTransitReminder),
          subtitle: Text(l.settingsTransitReminderHint),
          value: prefs.transit,
          onChanged: (on) =>
              _toggle(context, ref, on: on, apply: notifier.setTransit),
        ),
      ],
    );
  }
}

class _VersionTile extends StatelessWidget {
  const _VersionTile();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final info = snapshot.data;
        return ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text(
            info == null
                ? '—'
                : L10n.of(
                    context,
                  ).settingsVersion('${info.version} (${info.buildNumber})'),
          ),
        );
      },
    );
  }
}

/// What the AGPL and CC BY oblige us to show.
///
/// Deliberately plain: every string here is a licence fact or a proper name,
/// and translating "AGPL-3.0" or "Astrodienst AG" would make the notice less
/// useful, not more. The surrounding rows are localised; these are not.
class _LicencesPage extends StatelessWidget {
  const _LicencesPage();

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final theme = Theme.of(context);

    final palette = BrandPalette.of(context);
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
              child: Row(
                children: [
                  RoundIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l.settingsLicences,
                      style: BrandFonts.displayStyle(
                        context,
                        size: 26,
                        color: palette.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Text(Licensing.notice, style: theme.textTheme.bodyMedium),
            ),
            for (final a in Licensing.attributions)
              ListTile(
                title: Text(a.name),
                subtitle: Text(
                  a.note == null
                      ? '${a.author} · ${a.license}'
                      : '${a.author} · ${a.license}\n${a.note}',
                ),
                isThreeLine: a.note != null,
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => launchUrl(
                  Uri.parse(a.url),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ListTile(
              title: const Text('Source code'),
              subtitle: const Text(Licensing.sourceUrl),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => launchUrl(
                Uri.parse(Licensing.sourceUrl),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
