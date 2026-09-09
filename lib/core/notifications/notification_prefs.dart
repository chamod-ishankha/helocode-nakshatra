import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/onboarding/data/profile_repository.dart';

/// What the user has asked to be told about.
///
/// Two switches rather than one. A reader who wants the morning nekath does
/// not necessarily want to be told about a poya four weeks out, and someone
/// who only cares about poya days should not have to take a notification every
/// morning to get one.
class NotificationPrefs {
  const NotificationPrefs({
    this.daily = false,
    this.poya = false,
    this.hour = 6,
    this.minute = 30,
  });

  /// The morning nekath summary.
  ///
  /// Off by default. A notification the user did not ask for is the fastest
  /// way to be uninstalled, and Android 13 will not deliver one until they
  /// have granted the permission anyway.
  final bool daily;

  /// The evening before a poya.
  final bool poya;

  final int hour;
  final int minute;

  bool get anyEnabled => daily || poya;

  NotificationPrefs copyWith({
    bool? daily,
    bool? poya,
    int? hour,
    int? minute,
  }) => NotificationPrefs(
    daily: daily ?? this.daily,
    poya: poya ?? this.poya,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
  );

  Map<String, Object> toJson() => {
    'daily': daily,
    'poya': poya,
    'hour': hour,
    'minute': minute,
  };

  static NotificationPrefs fromJson(Map<String, dynamic> json) =>
      NotificationPrefs(
        daily: json['daily'] as bool? ?? false,
        poya: json['poya'] as bool? ?? false,
        // Clamped rather than trusted: a corrupt or hand-edited value would
        // otherwise throw inside the scheduler, where the failure is far from
        // the cause.
        hour: ((json['hour'] as int?) ?? 6).clamp(0, 23),
        minute: ((json['minute'] as int?) ?? 30).clamp(0, 59),
      );

  @override
  bool operator ==(Object other) =>
      other is NotificationPrefs &&
      other.daily == daily &&
      other.poya == poya &&
      other.hour == hour &&
      other.minute == minute;

  @override
  int get hashCode => Object.hash(daily, poya, hour, minute);

  @override
  String toString() =>
      'NotificationPrefs(daily: $daily, poya: $poya, '
      '${hour.toString().padLeft(2, '0')}:'
      '${minute.toString().padLeft(2, '0')})';
}

class NotificationPrefsNotifier extends Notifier<NotificationPrefs> {
  @override
  NotificationPrefs build() =>
      ref.watch(profileRepositoryProvider).loadNotificationPrefs();

  Future<void> set(NotificationPrefs prefs) async {
    await ref.read(profileRepositoryProvider).saveNotificationPrefs(prefs);
    state = prefs;
  }

  Future<void> setDaily(bool on) => set(state.copyWith(daily: on));

  Future<void> setPoya(bool on) => set(state.copyWith(poya: on));

  Future<void> setTime(int hour, int minute) =>
      set(state.copyWith(hour: hour, minute: minute));
}

final notificationPrefsProvider =
    NotifierProvider<NotificationPrefsNotifier, NotificationPrefs>(
      NotificationPrefsNotifier.new,
    );
