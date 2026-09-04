import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/flavor.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class NakshatraApp extends ConsumerWidget {
  const NakshatraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: FlavorConfig.current.appName,
      debugShowCheckedModeBanner: !FlavorConfig.current.flavor.isProd,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
