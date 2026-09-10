import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../logging/app_logger.dart';
import 'notification_prefs.dart';

/// The morning nekath reminder and the poya reminder (KAN-33).
///
/// ## Local, not pushed
///
/// Everything the notification says is computed on the phone, so it arrives
/// with no network and costs nothing to send. That also settles a constraint
/// the project has anyway: the Firebase project is on the Spark plan, which
/// has no Cloud Functions, so there is nothing to send a push *from*.
///
/// ## Scheduled a week ahead, refreshed on every launch
///
/// A repeating alarm can only carry fixed text, and "rāhu kālaya is 3:09 to
/// 4:40" is different every day. So seven days are scheduled individually with
/// their real times, and the window is topped up each time the app opens. A
/// user who does not open the app for a week stops being reminded, which is
/// the right failure: the alternative is a stale time, and a wrong nekath is
/// worse than none.
///
/// ## Inexact alarms, deliberately
///
/// Android 12 put exact alarms behind `SCHEDULE_EXACT_ALARM`, and Play grants
/// it to alarm clocks and calendars — not to an almanac. Asking for it risks
/// the listing. `inexactAllowWhileIdle` can drift by a few minutes and still
/// fires in Doze, which is the right trade for something a reader looks at
/// over breakfast.
abstract final class NotificationService {
  /// How many days ahead to schedule. A week is long enough that a user who
  /// opens the app most days never sees a gap, and short enough that the
  /// almanac behind it cannot drift far.
  static const int horizonDays = 7;

  static const _dailyIdBase = 1000;
  static const _poyaIdBase = 2000;
  static const _festivalIdBase = 3000;
  static const _dashaIdBase = 4000;

  static const _channel = AndroidNotificationChannel(
    'daily_nekath',
    'Daily nekath',
    description: 'The morning summary, and poya reminders.',
    importance: Importance.defaultImportance,
  );

  static FlutterLocalNotificationsPlugin? _plugin;

  /// Set in tests to capture what would have been scheduled.
  @visibleForTesting
  static NotificationSink? sink;

  static bool get isReady => _plugin != null || sink != null;

  /// Prepares the plugin and the channel. Never throws.
  static Future<void> initialize({
    void Function(String? payload)? onTap,
  }) async {
    if (sink != null) return;

    try {
      final plugin = FlutterLocalNotificationsPlugin();

      await plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
        onDidReceiveNotificationResponse: (response) =>
            onTap?.call(response.payload),
      );

      await plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel);

      _plugin = plugin;
      AppLogger.info('Notifications ready');
    } on Object catch (e, s) {
      AppLogger.warn('Notifications unavailable, continuing', e, s);
      _plugin = null;
    }
  }

  /// Asks for the Android 13 runtime permission.
  ///
  /// Called when the user turns a reminder on, not at launch. Onboarding is
  /// already the highest drop-off surface in the app; a permission dialog in
  /// front of a benefit nobody has felt yet is refused and then cannot be
  /// asked again.
  static Future<bool> requestPermission() async {
    final android = _plugin
        ?.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return sink != null;

    try {
      return await android.requestNotificationsPermission() ?? false;
    } on Object catch (e) {
      AppLogger.warn('Could not ask for notification permission: $e');
      return false;
    }
  }

  /// Replaces everything scheduled with a fresh week.
  ///
  /// Cancel-then-schedule rather than diffing: the whole set is derived from
  /// the same preferences and the same almanac, so rebuilding it is cheap and
  /// cannot leave a stale entry behind.
  static Future<void> reschedule({
    required NotificationPrefs prefs,
    required List<ScheduledNotification> notifications,
  }) async {
    await cancelAll();
    if (!prefs.anyEnabled) return;

    for (final n in notifications) {
      await _schedule(n);
    }
    AppLogger.info('Scheduled ${notifications.length} notifications');
  }

  static Future<void> _schedule(ScheduledNotification n) async {
    final capture = sink;
    if (capture != null) {
      capture.scheduled.add(n);
      return;
    }

    final plugin = _plugin;
    if (plugin == null) return;

    try {
      await plugin.zonedSchedule(
        id: n.id,
        title: n.title,
        body: n.body,
        scheduledDate: tz.TZDateTime.from(n.at, tz.local),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: _channel.importance,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: n.payload,
      );
    } on Object catch (e) {
      AppLogger.warn('Could not schedule ${n.id}: $e');
    }
  }

  static Future<void> cancelAll() async {
    final capture = sink;
    if (capture != null) {
      capture.scheduled.clear();
      return;
    }

    try {
      await _plugin?.cancelAll();
    } on Object catch (e) {
      AppLogger.warn('Could not cancel notifications: $e');
    }
  }

  /// Stable id for the daily reminder [dayOffset] days out.
  static int dailyId(int dayOffset) => _dailyIdBase + dayOffset;

  /// Stable id for a poya reminder [dayOffset] days out.
  static int poyaId(int dayOffset) => _poyaIdBase + dayOffset;

  /// Stable id for a festival reminder [dayOffset] days out.
  static int festivalId(int dayOffset) => _festivalIdBase + dayOffset;

  /// Stable id for a daśā-change reminder [dayOffset] days out.
  static int dashaId(int dayOffset) => _dashaIdBase + dayOffset;

  @visibleForTesting
  static void resetForTesting() {
    _plugin = null;
    sink = null;
  }
}

/// Collects what would have been scheduled, for tests.
class NotificationSink {
  final List<ScheduledNotification> scheduled = [];
}

/// One notification, resolved down to text and a moment.
@immutable
class ScheduledNotification {
  const ScheduledNotification({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
    this.payload,
  });

  final int id;
  final DateTime at;
  final String title;
  final String body;

  /// The date the notification is about, ISO-8601, so tapping it can open the
  /// home screen already showing that day.
  final String? payload;

  @override
  bool operator ==(Object other) =>
      other is ScheduledNotification &&
      other.id == id &&
      other.at == at &&
      other.title == title &&
      other.body == body &&
      other.payload == payload;

  @override
  int get hashCode => Object.hash(id, at, title, body, payload);

  @override
  String toString() => 'ScheduledNotification($id, $at, "$title")';
}
