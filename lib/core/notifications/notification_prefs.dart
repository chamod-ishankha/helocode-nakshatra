import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/onboarding/data/profile_repository.dart';

/// What the user has asked to be told about.
///
/// A switch each, rather than one. A reader who wants the morning nekath does
/// not necessarily want to be told about a poya four weeks out, and someone
/// who only cares about poya days should not have to take a notification every
/// morning to get one.
///
/// All five are **on** by default. They used to be off, reachable only from
/// Settings, and almost nobody found them: in November 2026 one monthly user
/// in five came back within a week, for an app whose reason to exist is
/// today's rāhu kālaya. The morning reminder is what brings a reader back,
/// so the owner turned them on.
///
/// "On" is a default, not a decision taken for the reader. Android 13 will
/// not deliver anything until the reader grants the permission, so Home
/// carries a card asking for it ([ReminderPrompt]) for as long as it is
/// missing. Anyone who has ever saved a choice keeps it — only the
/// never-touched default moved.
class NotificationPrefs {
  const NotificationPrefs({
    this.daily = true,
    this.poya = true,
    this.festival = true,
    this.dasha = true,
    this.transit = true,
    this.hour = 6,
    this.minute = 30,
  });

  /// The morning nekath summary — the reminder that matters most.
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

  /// The day a slow graha changes rāśi (KAN-65).
  ///
  /// Free, unlike most of what the app added around it. A sign change is the
  /// thing a reader here already follows by name — සෙනසුරු මාරුව is discussed
  /// on the news — so it earns its place by bringing people back to the app
  /// rather than by being withheld from them.
  ///
  /// Only the four slow grahas; see [Ingress.slow] for why the Moon and
  /// Mercury are not an event.
  final bool transit;

  final int hour;
  final int minute;

  bool get anyEnabled => daily || poya || festival || dasha || transit;

  NotificationPrefs copyWith({
    bool? daily,
    bool? poya,
    bool? festival,
    bool? dasha,
    bool? transit,
    int? hour,
    int? minute,
  }) => NotificationPrefs(
    daily: daily ?? this.daily,
    poya: poya ?? this.poya,
    festival: festival ?? this.festival,
    dasha: dasha ?? this.dasha,
    transit: transit ?? this.transit,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
  );

  Map<String, Object> toJson() => {
    'daily': daily,
    'poya': poya,
    'festival': festival,
    'dasha': dasha,
    'transit': transit,
    'hour': hour,
    'minute': minute,
  };

  static NotificationPrefs fromJson(Map<String, dynamic> json) =>
      NotificationPrefs(
        daily: json['daily'] as bool? ?? false,
        poya: json['poya'] as bool? ?? false,
        // Absent in anything written before KAN-63, and absent means off.
        // A stored record is a reader's own choice, made when this kind did
        // not exist; the on-by-default applies only to readers who never
        // saved one.
        festival: json['festival'] as bool? ?? false,
        dasha: json['dasha'] as bool? ?? false,
        // Likewise absent before KAN-65, and likewise off.
        transit: json['transit'] as bool? ?? false,
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
      other.transit == transit &&
      other.hour == hour &&
      other.minute == minute;

  @override
  int get hashCode =>
      Object.hash(daily, poya, festival, dasha, transit, hour, minute);

  @override
  String toString() =>
      'NotificationPrefs(daily: $daily, poya: $poya, '
      'festival: $festival, dasha: $dasha, transit: $transit, '
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

  Future<void> setTransit(bool on) => set(state.copyWith(transit: on));

  Future<void> setTime(int hour, int minute) =>
      set(state.copyWith(hour: hour, minute: minute));
}

final notificationPrefsProvider =
    NotifierProvider<NotificationPrefsNotifier, NotificationPrefs>(
      NotificationPrefsNotifier.new,
    );
