import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../config/version_gate.dart';
import '../theme/brand_palette.dart';
import '../theme/semantic_colors.dart';
import 'notification_coordinator.dart';
import 'notification_prefs.dart';
import 'reminder_prompt.dart';

/// Home's request to allow reminders, in the app's own card ([ReminderPrompt]).
class ReminderPermissionCard extends ConsumerStatefulWidget {
  const ReminderPermissionCard({super.key});

  @override
  ConsumerState<ReminderPermissionCard> createState() =>
      _ReminderPermissionCardState();
}

class _ReminderPermissionCardState
    extends ConsumerState<ReminderPermissionCard> {
  late final AppLifecycleListener _lifecycle;
  bool _neverAgain = false;

  @override
  void initState() {
    super.initState();
    // Back from system settings, or from turning notifications on there
    // without the app: the card should go the moment it is no longer true.
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(notificationsAllowedProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _enable() async {
    if (await ref.read(reminderPromptProvider).enable()) {
      // The week was scheduled before Android would show any of it; arm it
      // again now that it will.
      ref.invalidate(notificationRefreshProvider);
    }
    ref.invalidate(notificationsAllowedProvider);
  }

  Future<void> _close() async {
    await ref.read(reminderPromptProvider).close(neverAgain: _neverAgain);
    ref.read(reminderPromptClosedProvider.notifier).close();
  }

  @override
  Widget build(BuildContext context) {
    final prompt = ref.watch(reminderPromptProvider);
    final show = prompt.shouldShow(
      remindersOn: ref.watch(notificationPrefsProvider).anyEnabled,
      // Until the answer is in, no card: one that appears and vanishes on
      // every launch for readers who already allowed it is worse than one
      // that appears a moment late.
      allowed: ref.watch(notificationsAllowedProvider).value ?? true,
      closedThisLaunch: ref.watch(reminderPromptClosedProvider),
    );
    if (!show) return const SizedBox.shrink();

    final l = L10n.of(context);
    final palette = BrandPalette.of(context);
    return NoticeCard(
      icon: Icons.notifications_active_outlined,
      title: l.reminderPromptTitle,
      body: l.reminderPromptBody,
      actionLabel: l.reminderPromptEnable,
      onAction: () => unawaited(_enable()),
      onDismiss: _close,
      footer: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _neverAgain = !_neverAgain),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: _neverAgain,
              activeColor: context.semantic.accent,
              visualDensity: VisualDensity.compact,
              onChanged: (v) => setState(() => _neverAgain = v ?? false),
            ),
            Flexible(
              child: Text(
                l.reminderPromptNeverAsk,
                style: TextStyle(fontSize: 13, color: palette.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
