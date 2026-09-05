import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/onboarding/data/profile_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import '../config/app_locale.dart';

/// Switches language from anywhere, at any time.
///
/// Onboarding asks once, and someone tapping through quickly can land in a
/// language they cannot read — with no way back short of clearing app data,
/// which also destroys their chart. Households here share phones across
/// languages too, so this is not only a recovery path.
///
/// Two things make it usable to someone who is already stuck:
///
///  * the icon is a symbol, not a word, so it needs no reading
///  * every option is written in its own script. A Tamil speaker looks for
///    "தமிழ்", not for "Tamil" — and the theme's font fallbacks mean all
///    three render whatever the current language is.
///
/// Moves into settings when KAN-30 lands; this widget goes there unchanged.
class LanguageButton extends ConsumerWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider);
    final theme = Theme.of(context);

    return PopupMenuButton<AppLocale>(
      icon: const Icon(Icons.translate),
      tooltip: L10n.of(context).language,
      initialValue: current,
      // Selecting the language already showing would rewrite the same value to
      // storage for nothing.
      onSelected: (locale) {
        if (locale != current) {
          ref.read(localeProvider.notifier).set(locale);
        }
      },
      itemBuilder: (context) => [
        for (final locale in AppLocale.values)
          PopupMenuItem<AppLocale>(
            value: locale,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        locale.nativeName,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: locale == current
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: locale == current
                              ? theme.colorScheme.primary
                              : null,
                        ),
                      ),
                      // The English name under the native one, so the list is
                      // navigable by someone who reads only one of the three.
                      if (locale.nativeName != locale.englishName)
                        Text(
                          locale.englishName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (locale == current)
                  Icon(Icons.check, size: 18, color: theme.colorScheme.primary),
              ],
            ),
          ),
      ],
    );
  }
}
