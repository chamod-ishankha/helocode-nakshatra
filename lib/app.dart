import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'core/config/flavor.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/data/profile_repository.dart';
import 'l10n/generated/app_localizations.dart';

class NakshatraApp extends ConsumerWidget {
  const NakshatraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);

    // Every DateFormat in the app is constructed without an explicit locale,
    // so they all read this. Without it a Sinhala app still prints "Tuesday,
    // 8 September 2026" - the labels translate and the dates do not.
    Intl.defaultLocale = locale.code;
    final themePreference = ref.watch(themePreferenceProvider);

    return MaterialApp.router(
      // Not localised: the brand reads the same in all three languages.
      title: FlavorConfig.current.appName,
      debugShowCheckedModeBanner: !FlavorConfig.current.flavor.isProd,
      theme: AppTheme.light(locale),
      darkTheme: AppTheme.dark(locale),
      themeMode: themePreference.mode,

      // Driven by the user's choice rather than the device, because a Sinhala
      // speaker on an English phone is the common case here, not the exception.
      locale: Locale(locale.code),
      supportedLocales: L10n.supportedLocales,
      localizationsDelegates: L10n.localizationsDelegates,

      routerConfig: router,
    );
  }
}
