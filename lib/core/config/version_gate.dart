import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/onboarding/data/profile_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import '../logging/app_logger.dart';
import '../theme/brand_palette.dart';
import '../ui/state_views.dart';
import 'app_config.dart';
import 'app_config_service.dart';
import 'flavor.dart';

/// This build's Android versionCode. Null until known, and null under test.
///
/// Read once: it cannot change while the process runs.
final buildNumberProvider = FutureProvider<int?>((ref) async {
  try {
    final info = await PackageInfo.fromPlatform();
    return int.tryParse(info.buildNumber);
  } on Object catch (e) {
    AppLogger.warn('Build number unavailable: $e');
    return null;
  }
});

/// The verdict for this build under the config in force.
///
/// [GateVerdict.current] while the build number is unknown: a gate must
/// never fire on a guess.
final gateVerdictProvider = Provider<GateVerdict>((ref) {
  final build = ref.watch(buildNumberProvider).value;
  if (build == null) return GateVerdict.current;
  return ref
      .watch(appConfigProvider)
      .gateFor(FlavorConfig.current.flavor)
      .verdictFor(build);
});

/// Blocks a build below the published minimum (KAN-49 §8.2).
///
/// The one place the "always a whole app offline" rule yields, and on
/// purpose: a minimum is set only for a build the owner has judged harmful —
/// one printing the wrong poya, say. The almanac is still computed
/// underneath; it is simply not shown. Nothing on the phone is lost.
///
/// Wrapped around the router rather than placed as a route, so no
/// navigation — deep link, back button, notification tap — can get past it.
class VersionGateGuard extends ConsumerWidget {
  const VersionGateGuard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(gateVerdictProvider) != GateVerdict.blocked) return child;
    final gate = ref
        .watch(appConfigProvider)
        .gateFor(FlavorConfig.current.flavor);
    return _BlockedScreen(gate: gate);
  }
}

class _BlockedScreen extends ConsumerWidget {
  const _BlockedScreen({required this.gate});

  final VersionGate gate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L10n.of(context);
    final palette = BrandPalette.of(context);
    final locale = ref.watch(localeProvider);
    final message = gate.message?.of(locale);

    return Scaffold(
      backgroundColor: palette.background,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: palette.backdrop),
        child: SafeArea(
          child: StatusView(
            icon: Icons.system_update_rounded,
            title: l.updateRequiredTitle,
            body: (message == null || message.isEmpty)
                ? l.updateRequiredBody
                : message,
            action: (
              label: l.updateOpenStore,
              onPressed: () => _openStore(gate.storeUrl),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _openStore(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on Object catch (e) {
    AppLogger.warn('Could not open the store: $e');
  }
}

/// "A newer version is available", once per published latest build.
///
/// A card, not a dialog: it sits under the date row on Home and is read in
/// passing. Dismissing it remembers the build it was for, so the next
/// publish with a higher latest shows it again.
class UpdateAvailableCard extends ConsumerWidget {
  const UpdateAvailableCard({super.key});

  static const _dismissedKey = 'update_available.dismissed_build';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(gateVerdictProvider) != GateVerdict.updateAvailable) {
      return const SizedBox.shrink();
    }
    final gate = ref
        .watch(appConfigProvider)
        .gateFor(FlavorConfig.current.flavor);
    final prefs = ref.watch(sharedPreferencesProvider);
    if (prefs.getInt(_dismissedKey) == gate.latestBuild) {
      return const SizedBox.shrink();
    }

    final l = L10n.of(context);
    return NoticeCard(
      icon: Icons.system_update_rounded,
      title: l.updateAvailableTitle,
      body: l.updateAvailableBody,
      actionLabel: l.updateOpenStore,
      onAction: () => _openStore(gate.storeUrl),
      onDismiss: () async {
        await prefs.setInt(_dismissedKey, gate.latestBuild);
        ref.invalidate(gateVerdictProvider);
      },
    );
  }
}

/// A dismissible notice on Home: the update suggestion and the announcement
/// share it, so the two look like the same kind of thing.
class NoticeCard extends StatelessWidget {
  const NoticeCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Future<void> Function()? onDismiss;

  @override
  Widget build(BuildContext context) {
    final palette = BrandPalette.of(context);
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      body,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: palette.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => onDismiss!(),
                ),
            ],
          ),
          if (actionLabel != null)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(foregroundColor: accent),
                child: Text(actionLabel!),
              ),
            ),
        ],
      ),
    );
  }
}
