import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/chart/presentation/chart_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/data/profile_repository.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';

/// Route paths, kept in one place so no screen hardcodes a string.
abstract final class Routes {
  static const String onboarding = '/onboarding';
  static const String chart = '/chart';

  // Land in KAN-27, KAN-29 and KAN-30.
  static const String home = '/';
  static const String calendar = '/calendar';
  static const String compatibility = '/compatibility';
  static const String settings = '/settings';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.home,
    debugLogDiagnostics: true,
    // A user with no saved profile has nothing to show, so every route
    // redirects into onboarding until one exists. Reading the profile through
    // the provider means completing onboarding re-evaluates this immediately.
    redirect: (context, state) {
      final hasProfile = ref.read(profileProvider) != null;
      final onOnboarding = state.matchedLocation == Routes.onboarding;

      if (!hasProfile && !onOnboarding) return Routes.onboarding;
      if (hasProfile && onOnboarding) return Routes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: Routes.chart,
        name: 'chart',
        builder: (context, state) => const ChartScreen(),
      ),
    ],
    errorBuilder: (context, state) => _RouteErrorScreen(error: state.error),
  );
});

class _RouteErrorScreen extends StatelessWidget {
  const _RouteErrorScreen({this.error});

  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text(
                'Page not found',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '${error ?? 'Unknown route'}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go(Routes.home),
                child: const Text('Go home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
