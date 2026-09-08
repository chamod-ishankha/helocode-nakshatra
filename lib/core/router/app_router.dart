import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/generated/app_localizations.dart';

import '../../features/account/presentation/account_screen.dart';
import '../../features/calendar/presentation/calendar_screen.dart';
import '../../features/chart/presentation/chart_screen.dart';
import '../../features/compatibility/presentation/compatibility_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/data/profile_repository.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/horoscope/presentation/horoscope_screen.dart';

/// Route paths, kept in one place so no screen hardcodes a string.
abstract final class Routes {
  static const String onboarding = '/onboarding';

  /// Onboarding opened deliberately, to change details that already exist.
  ///
  /// The flag is on the route rather than in a provider because the redirect
  /// runs before any screen does, and it is the redirect that has to tell the
  /// two cases apart.
  static const String editProfile = '$onboarding?edit=1';
  static const String chart = '/chart';
  static const String account = '/account';

  // Land in KAN-27, KAN-29 and KAN-30.
  static const String home = '/';
  static const String calendar = '/calendar';
  static const String compatibility = '/compatibility';
  static const String settings = '/settings';
  static const String horoscope = '/horoscope';
}

/// Goes back one screen, or home when there is nothing behind this one.
///
/// A screen is normally reached by a push and has a stack behind it. It can
/// also be landed on directly — a redirect, or a restart that restores a
/// location — and popping then would close the app instead of going back.
void popOrHome(BuildContext context) =>
    context.canPop() ? context.pop() : context.go(Routes.home);

/// Where a request for [location] should actually go.
///
/// A top-level function rather than a closure inside the router so it can be
/// tested for what it is — three rules about who may see the onboarding
/// wizard — without standing up a navigator and every screen behind it.
///
/// Returns null to allow the request through.
String? redirectFor({required String location, required bool hasProfile}) {
  final uri = Uri.parse(location);
  final onOnboarding = uri.path == Routes.onboarding;

  // Nothing to show until there is a profile, so everything funnels in.
  if (!hasProfile && !onOnboarding) return Routes.onboarding;

  // Sending a user who has a profile out of the wizard is right when they
  // landed there by accident — a restored location after a restart, a stale
  // redirect — and wrong when they asked for it. This used to be unable to
  // tell the two apart and ate both, which left Settings > "Edit birth
  // details" bouncing straight back to home and birth details uneditable,
  // onboarding being the only editor there is (KAN-61).
  final editing = uri.queryParameters['edit'] == '1';
  if (hasProfile && onOnboarding && !editing) return Routes.home;

  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  // Redirects are only re-evaluated when the router is told something
  // changed. Without this, deleting the profile left the app on a screen it
  // should no longer be on: the redirect below had already run, and nothing
  // asked it to run again. The home screen then rendered its "no data yet"
  // spinner forever, because a deleted profile never arrives.
  final profileChanged = ValueNotifier<int>(0);
  ref.listen(profileProvider, (_, _) => profileChanged.value++);
  ref.onDispose(profileChanged.dispose);

  return GoRouter(
    initialLocation: Routes.home,
    debugLogDiagnostics: true,
    refreshListenable: profileChanged,
    redirect: (context, state) => redirectFor(
      location: state.uri.toString(),
      hasProfile: ref.read(profileProvider) != null,
    ),
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
      GoRoute(
        path: Routes.horoscope,
        name: 'horoscope',
        builder: (context, state) => const HoroscopeScreen(),
      ),
      GoRoute(
        path: Routes.compatibility,
        name: 'compatibility',
        builder: (context, state) => const CompatibilityScreen(),
      ),
      GoRoute(
        path: Routes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: Routes.calendar,
        name: 'calendar',
        builder: (context, state) => const CalendarScreen(),
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
