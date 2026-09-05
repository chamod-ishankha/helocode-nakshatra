import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/generated/app_localizations.dart';

import '../../features/account/presentation/account_screen.dart';
import '../../features/chart/presentation/chart_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/data/profile_repository.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';

/// Route paths, kept in one place so no screen hardcodes a string.
abstract final class Routes {
  static const String onboarding = '/onboarding';
  static const String chart = '/chart';
  static const String account = '/account';

  // Land in KAN-27, KAN-29 and KAN-30.
  static const String home = '/';
  static const String calendar = '/calendar';
  static const String compatibility = '/compatibility';
  static const String settings = '/settings';
}

/// Goes back one screen, or home when there is nothing behind this one.
///
/// A screen is normally reached by a push and has a stack behind it. It can
/// also be landed on directly — a redirect, or a restart that restores a
/// location — and popping then would close the app instead of going back.
void popOrHome(BuildContext context) =>
    context.canPop() ? context.pop() : context.go(Routes.home);

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
      GoRoute(
        path: Routes.account,
        name: 'account',
        builder: (context, state) => const AccountScreen(),
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
                L10n.of(context).routeNotFound,
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
                child: Text(L10n.of(context).routeGoHome),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
