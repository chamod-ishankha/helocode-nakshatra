import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/onboarding/data/profile_repository.dart';

/// What the user has asked to be told about.
///
/// A switch each, rather than one. A reader who wants the morning nekath does
/// not necessarily want to be told about a poya four weeks out, and someone
/// who only cares about poya days should not have to take a notification every
/// morning to get one.
///
/// All four are off by default, and that matters more with four than it did
/// with two: every extra kind is another reason to turn the lot off, so none
/// of them may arrive unasked.
class NotificationPrefs {
  const NotificationPrefs({
    this.daily = false,
    this.poya = false,
    this.festival = false,
    this.dasha = false,
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

  /// The evening before a festival with nekath meaning (KAN-63).
  ///
  /// Two a year — the Sinhala and Tamil New Year, and Thai Pongal. The
  /// public holidays the calendar also knows are deliberately not included;
  /// see [NotificationPlanner] for why.
  final bool festival;

  /// The day a new daśā period begins in the user's own chart.
  ///
  /// The rarest of the four — a mahādaśā turns over every few years — and the
  /// only one that is about the reader rather than about the day.
  final bool dasha;

  final int hour;
  final int minute;

  bool get anyEnabled => daily || poya || festival || dasha;

  NotificationPrefs copyWith({
    bool? daily,
    bool? poya,
    bool? festival,
    bool? dasha,
    int? hour,
    int? minute,
  }) => NotificationPrefs(
    daily: daily ?? this.daily,
    poya: poya ?? this.poya,
    festival: festival ?? this.festival,
    dasha: dasha ?? this.dasha,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
  );

  Map<String, Object> toJson() => {
    'daily': daily,
    'poya': poya,
    'festival': festival,
    'dasha': dasha,
    'hour': hour,
    'minute': minute,
  };

  static NotificationPrefs fromJson(Map<String, dynamic> json) =>
      NotificationPrefs(
        daily: json['daily'] as bool? ?? false,
        poya: json['poya'] as bool? ?? false,
        // Absent in anything written before KAN-63, and absent means off —
        // an upgrade must not start sending a kind of notification the user
        // never agreed to.
        festival: json['festival'] as bool? ?? false,
        dasha: json['dasha'] as bool? ?? false,
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
      other.festival == festival &&
      other.dasha == dasha &&
      other.hour == hour &&
      other.minute == minute;

  @override
  int get hashCode => Object.hash(daily, poya, festival, dasha, hour, minute);

  @override
  String toString() =>
      'NotificationPrefs(daily: $daily, poya: $poya, '
      'festival: $festival, dasha: $dasha, '
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

  Future<void> setFestival(bool on) => set(state.copyWith(festival: on));

  Future<void> setDasha(bool on) => set(state.copyWith(dasha: on));

  Future<void> setTime(int hour, int minute) =>
      set(state.copyWith(hour: hour, minute: minute));
}

final notificationPrefsProvider =
    NotifierProvider<NotificationPrefsNotifier, NotificationPrefs>(
      NotificationPrefsNotifier.new,
    );
