import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/onboarding/data/profile_repository.dart';
import 'notification_service.dart';

/// The card on Home asking the reader to allow the reminders that are already
/// on ([ReminderPermissionCard]).
///
/// Reminders start on, but Android 13 delivers nothing until the reader
/// grants permission. The app does not fire the system dialog by itself: a
/// bare "Allow notifications?" with no reason attached is refused, and after
/// two refusals Android stops showing it for good. So the app explains first,
/// in its own card, and the system dialog appears only when the reader taps
/// Enable — by which point they have already said yes.
///
/// The card stays until permission arrives. Closing it hides it until the
/// next launch; closing it with "Don't ask again" ticked hides it for good.
class ReminderPrompt {
  ReminderPrompt({
    required SharedPreferences prefs,
    required Future<bool> Function() request,
    required Future<void> Function() openSettings,
  }) : _prefs = prefs,
       _request = request,
       _openSettings = openSettings;

  final SharedPreferences _prefs;
  final Future<bool> Function() _request;
  final Future<void> Function() _openSettings;

  static const neverAskKey = 'reminder_prompt.never_ask_v1';

  /// Faster than anyone can read a dialog and choose. A refusal that comes
  /// back sooner means Android answered without showing one.
  static const dialogShownAfter = Duration(milliseconds: 600);

  bool get neverAsk => _prefs.getBool(neverAskKey) ?? false;

  /// Whether the card belongs on Home.
  ///
  /// Not when every reminder is off: there is nothing for the permission to
  /// deliver, and the reader turned them off themselves.
  bool shouldShow({
    required bool remindersOn,
    required bool allowed,
    required bool closedThisLaunch,
  }) => remindersOn && !allowed && !closedThisLaunch && !neverAsk;

  /// The reader closed the card. Only the ticked box outlives the launch.
  Future<void> close({required bool neverAgain}) async {
    if (neverAgain) await _prefs.setBool(neverAskKey, true);
  }

  /// The reader tapped Enable: the system dialog, or — when Android will no
  /// longer show it — the app's notification page in system settings.
  ///
  /// Android does not say which happened; a refusal faster than
  /// [dialogShownAfter] is the tell. Without the fallback, Enable on a
  /// twice-refused phone would be a button that does nothing.
  Future<bool> enable() async {
    final watch = Stopwatch()..start();
    if (await _request()) return true;
    if (watch.elapsed < dialogShownAfter) await _openSettings();
    return false;
  }
}

final reminderPromptProvider = Provider<ReminderPrompt>(
  (ref) => ReminderPrompt(
    prefs: ref.watch(sharedPreferencesProvider),
    request: NotificationService.requestPermission,
    openSettings: NotificationService.openSettings,
  ),
);

/// Whether notifications reach the reader. Re-read when the app comes back to
/// the front, since the answer can change in system settings.
final notificationsAllowedProvider = FutureProvider<bool>(
  (ref) => NotificationService.areEnabled(),
);

/// Closed for this launch. Held in memory only, so the card is back the next
/// time the app starts.
final reminderPromptClosedProvider =
    NotifierProvider<ReminderPromptClosed, bool>(ReminderPromptClosed.new);

class ReminderPromptClosed extends Notifier<bool> {
  @override
  bool build() => false;

  void close() => state = true;
}
