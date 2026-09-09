import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_locale.dart';
import '../../../core/config/chart_style.dart';
import '../../../core/config/theme_preference.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/error/result.dart';
import '../../../core/router/app_router.dart';
import '../../../core/sync/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../account/presentation/auth_messages.dart';
import '../../../core/notifications/notification_coordinator.dart';
import '../../../core/notifications/notification_prefs.dart';
import '../../../core/notifications/notification_service.dart';
import '../../onboarding/data/profile_repository.dart';

/// Settings (KAN-30).
///
/// Only what actually works appears here. Multiple profiles need the storage
/// from KAN-19, notification time needs the pipeline from KAN-33, and restore
/// purchases needs RevenueCat from KAN-35 — all three are in this ticket's
/// scope and none of them are listed, because a row that does nothing is worse
/// than a row that is missing.
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.settingsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => popOrHome(context),
        ),
      ),
      body: ListView(
        children: [
          _Section(l.settingsSectionProfile),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(l.settingsEditProfile),
            subtitle: Text(l.settingsEditProfileHint),
            trailing: const Icon(Icons.chevron_right),
            // Onboarding is the only editor there is, and it already handles
            // every field. Sending the user back through it beats a second
            // form that could drift out of step with the first — as long as
            // the route says it is an edit, or the redirect turns it away.
            onTap: () => context.push(Routes.editProfile),
          ),

          _Section(l.settingsSectionAppearance),
          const _ThemeTile(),
          const _LanguageTile(),
          const _ChartStyleTile(),

          _Section(l.settingsSectionReminders),
          const _ReminderTiles(),

          _Section(l.settingsSectionData),
          ListTile(
            leading: Icon(Icons.delete_outline, color: AppColors.inauspicious),
            title: Text(
              l.settingsDeleteData,
              style: TextStyle(color: AppColors.inauspicious),
            ),
            subtitle: Text(l.settingsDeleteHint),
            onTap: () => _confirmDelete(context, ref),
          ),

          _Section(l.settingsSectionAbout),
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
          const _VersionTile(),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Text(
              l.entertainmentOnly,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
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
        title: Text(l.settingsDeleteTitle),
        content: Text(l.settingsDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.inauspicious,
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

    // Leave for onboarding regardless. The local profile is gone either way,
    // so every screen behind this one is reading data that no longer exists.
    context.go(Routes.onboarding);
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

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        title,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
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
                    ? Icon(Icons.check, color: AppColors.accent)
                    : null,
                onTap: () => Navigator.of(context).pop(v),
              ),
            const SizedBox(height: 8),
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
              color: AppColors.accent,
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
          secondary: const Icon(Icons.wb_twilight),
          title: Text(l.settingsDailyReminder),
          subtitle: Text(l.settingsDailyReminderHint),
          value: prefs.daily,
          onChanged: (on) =>
              _toggle(context, ref, on: on, apply: notifier.setDaily),
        ),
        if (prefs.daily)
          ListTile(
            leading: const SizedBox(width: 24),
            title: Text(l.settingsReminderTime),
            trailing: Text(
              MaterialLocalizations.of(context).formatTimeOfDay(
                TimeOfDay(hour: prefs.hour, minute: prefs.minute),
              ),
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.accent),
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
          secondary: const Icon(Icons.brightness_2_outlined),
          title: Text(l.settingsPoyaReminder),
          subtitle: Text(l.settingsPoyaReminderHint),
          value: prefs.poya,
          onChanged: (on) =>
              _toggle(context, ref, on: on, apply: notifier.setPoya),
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
