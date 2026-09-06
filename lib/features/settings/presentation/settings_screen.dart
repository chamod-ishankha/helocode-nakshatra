import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_locale.dart';
import '../../../core/config/chart_style.dart';
import '../../../core/config/theme_preference.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
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
            // form that could drift out of step with the first.
            onTap: () => context.push(Routes.onboarding),
          ),

          _Section(l.settingsSectionAppearance),
          const _ThemeTile(),
          const _LanguageTile(),
          const _ChartStyleTile(),

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
  static Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
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

    // Clears local storage and the Firestore copy together — the privacy
    // policy promises both.
    await ref.read(profileProvider.notifier).clear();
    messenger.showSnackBar(SnackBar(content: Text(l.settingsDeleted)));
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

    return ListTile(
      leading: const Icon(Icons.brightness_6_outlined),
      title: Text(l.settingsTheme),
      subtitle: Text(l.settingsThemeHint),
      trailing: DropdownButton<ThemePreference>(
        value: current,
        underline: const SizedBox.shrink(),
        onChanged: (p) {
          if (p != null) ref.read(themePreferenceProvider.notifier).set(p);
        },
        items: [
          for (final p in ThemePreference.values)
            DropdownMenuItem(value: p, child: Text(label(p))),
        ],
      ),
    );
  }
}

class _LanguageTile extends ConsumerWidget {
  const _LanguageTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider);

    return ListTile(
      leading: const Icon(Icons.translate),
      title: Text(L10n.of(context).settingsLanguage),
      trailing: DropdownButton<AppLocale>(
        value: current,
        underline: const SizedBox.shrink(),
        onChanged: (locale) {
          if (locale != null) ref.read(localeProvider.notifier).set(locale);
        },
        items: [
          for (final locale in AppLocale.values)
            // Native names, for the same reason as the header switcher: a
            // Tamil speaker looks for தமிழ், not for "Tamil".
            DropdownMenuItem(
              value: locale,
              child: Text(locale.nativeName),
            ),
        ],
      ),
    );
  }
}

class _ChartStyleTile extends ConsumerWidget {
  const _ChartStyleTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(chartStyleProvider);

    return ListTile(
      leading: const Icon(Icons.grid_on),
      title: Text(L10n.of(context).settingsChartStyle),
      trailing: DropdownButton<ChartStyle>(
        value: current,
        underline: const SizedBox.shrink(),
        onChanged: (style) {
          if (style != null) ref.read(chartStyleProvider.notifier).set(style);
        },
        items: [
          for (final style in ChartStyle.values)
            // Not localised: these name two drawing conventions, and a reader
            // who wants one knows it by this name.
            DropdownMenuItem(value: style, child: Text(style.label)),
        ],
      ),
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
                : L10n.of(context).settingsVersion(
                    '${info.version} (${info.buildNumber})',
                  ),
          ),
        );
      },
    );
  }
}
