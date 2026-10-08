import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/home/domain/daily_providers.dart';
import '../../features/onboarding/data/profile_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import '../logging/app_logger.dart';
import 'app_config_service.dart';
import 'version_gate.dart';

/// The notice the admin panel publishes, on Home inside its window
/// (KAN-49 §8.3). Dismissing it remembers the announcement's id.
class AnnouncementCard extends ConsumerWidget {
  const AnnouncementCard({super.key});

  static const dismissedKey = 'announcement.dismissed_id';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcement = ref.watch(appConfigProvider).announcement;
    if (announcement == null) return const SizedBox.shrink();

    final prefs = ref.watch(sharedPreferencesProvider);
    // The home clock, so the card appears and goes on the minute like the
    // rāhu banner, rather than on the next rebuild.
    final now = ref.watch(clockProvider).toUtc();
    if (!announcement.isLiveAt(
      now,
      dismissedId: prefs.getString(dismissedKey),
    )) {
      return const SizedBox.shrink();
    }

    final locale = ref.watch(localeProvider);
    final link = announcement.link;
    return NoticeCard(
      icon: Icons.campaign_outlined,
      title: announcement.title.of(locale),
      body: announcement.body.of(locale),
      actionLabel: link == null ? null : L10n.of(context).announcementOpenLink,
      onAction: link == null
          ? null
          : () async {
              try {
                await launchUrl(link, mode: LaunchMode.externalApplication);
              } on Object catch (e) {
                AppLogger.warn('Could not open announcement link: $e');
              }
            },
      onDismiss: announcement.dismissible
          ? () async {
              await prefs.setString(dismissedKey, announcement.id);
              ref.invalidate(appConfigProvider);
            }
          : null,
    );
  }
}
