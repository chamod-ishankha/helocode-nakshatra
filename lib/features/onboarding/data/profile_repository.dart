import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/app_locale.dart';
import '../../../core/config/chart_style.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/sync/profile_sync.dart';
import '../domain/birth_profile.dart';

/// Local storage for the saved profile and language choice.
///
/// Interim implementation on SharedPreferences. Drift/SQLite replaces this in
/// KAN-19, which is also when multiple saved profiles arrive — this class
/// deliberately stores a single profile and nothing else.
///
/// Local storage is the source of truth. Firestore holds a backup copy
/// (KAN-47), pushed after every save and read only when this device has
/// nothing — the app never waits on the network to show a chart.
///
/// Birth details are backed up to Firestore under an anonymous account so they
/// survive a reinstall. Everything else — charts, nekath, the almanac — is
/// computed on-device and nothing about app usage is stored.
class ProfileRepository {
  ProfileRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _profileKey = 'birth_profile_v1';
  static const _localeKey = 'app_locale_v1';
  static const _chartStyleKey = 'chart_style_v1';

  BirthProfile? load() {
    final raw = _prefs.getString(_profileKey);
    if (raw == null) return null;
    try {
      return BirthProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object catch (e, s) {
      // A stored profile that will not parse is more likely a schema change
      // than corruption. Losing it sends the user back through onboarding,
      // which is recoverable; crashing on launch is not.
      AppLogger.error('Discarding unreadable saved profile', e, s);
      _prefs.remove(_profileKey);
      return null;
    }
  }

  Future<void> save(BirthProfile profile) =>
      _prefs.setString(_profileKey, jsonEncode(profile.toJson()));

  Future<void> clear() => _prefs.remove(_profileKey);

  AppLocale loadLocale() => AppLocale.fromCode(_prefs.getString(_localeKey));

  Future<void> saveLocale(AppLocale locale) =>
      _prefs.setString(_localeKey, locale.code);

  ChartStyle loadChartStyle() =>
      ChartStyle.fromName(_prefs.getString(_chartStyleKey));

  Future<void> saveChartStyle(ChartStyle style) =>
      _prefs.setString(_chartStyleKey, style.name);
}

/// Overridden at startup with the real instance, once SharedPreferences has
/// loaded. Reading it before then is a programmer error, not a runtime state.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(sharedPreferencesProvider)),
);

/// The saved profile, or null when onboarding has not been completed.
class ProfileNotifier extends Notifier<BirthProfile?> {
  @override
  BirthProfile? build() => ref.watch(profileRepositoryProvider).load();

  Future<void> save(BirthProfile profile) async {
    await ref.read(profileRepositoryProvider).save(profile);
    state = profile;
    // Deliberately not awaited: a slow or absent network must not hold up the
    // navigation to the user's chart.
    unawaited(ref.read(profileSyncProvider).push(profile));
  }

  Future<void> clear() async {
    await ref.read(profileRepositoryProvider).clear();
    state = null;
    unawaited(ref.read(profileSyncProvider).clear());
  }

  /// Restores a backed-up profile when this device has none.
  ///
  /// Called once at startup. Returns true if something was recovered, which is
  /// what lets a reinstall skip onboarding entirely.
  Future<bool> restoreFromBackup() async {
    if (state != null) return false;

    final remote = await ref.read(profileSyncProvider).pull();
    if (remote == null) return false;

    await ref.read(profileRepositoryProvider).save(remote);
    state = remote;
    AppLogger.info('Birth profile restored from backup');
    return true;
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, BirthProfile?>(
  ProfileNotifier.new,
);

class LocaleNotifier extends Notifier<AppLocale> {
  @override
  AppLocale build() => ref.watch(profileRepositoryProvider).loadLocale();

  Future<void> set(AppLocale locale) async {
    await ref.read(profileRepositoryProvider).saveLocale(locale);
    state = locale;
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, AppLocale>(
  LocaleNotifier.new,
);

/// Persisted so the choice survives a restart — a user who reads North Indian
/// charts should never have to re-pick it.
class ChartStyleNotifier extends Notifier<ChartStyle> {
  @override
  ChartStyle build() => ref.watch(profileRepositoryProvider).loadChartStyle();

  Future<void> set(ChartStyle style) async {
    await ref.read(profileRepositoryProvider).saveChartStyle(style);
    state = style;
  }

  Future<void> toggle() => set(
    state == ChartStyle.southIndian
        ? ChartStyle.northIndian
        : ChartStyle.southIndian,
  );
}

final chartStyleProvider = NotifierProvider<ChartStyleNotifier, ChartStyle>(
  ChartStyleNotifier.new,
);
