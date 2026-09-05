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

  /// Reconciles this device against an account that was just signed in to.
  ///
  /// Signing in to an existing account swaps the uid, so there can now be two
  /// profiles: the one on this phone and the one the account already held.
  ///
  /// Three of the four combinations settle themselves — this pushes up when
  /// the account has nothing, pulls down when the phone has nothing, and does
  /// nothing when they already agree. The fourth, two profiles that differ, is
  /// a genuine fork that only the user can decide, so it is returned rather
  /// than resolved. [keepAccountProfile] and [keepDeviceProfile] apply that
  /// decision.
  Future<BirthProfile?> reconcileAfterSignIn() async {
    final local = state;
    final remote = await ref.read(profileSyncProvider).pull();

    if (remote == null) {
      if (local != null) await ref.read(profileSyncProvider).push(local);
      return null;
    }

    if (local == null) {
      await ref.read(profileRepositoryProvider).save(remote);
      state = remote;
      return null;
    }

    return _sameProfile(local, remote) ? null : remote;
  }

  /// Takes the account's copy, replacing this device's.
  Future<void> keepAccountProfile(BirthProfile remote) async {
    await ref.read(profileRepositoryProvider).save(remote);
    state = remote;
    AppLogger.info('Kept the account profile over this device');
  }

  /// Keeps this device's copy, replacing the account's.
  Future<void> keepDeviceProfile() async {
    final local = state;
    if (local == null) return;
    await ref.read(profileSyncProvider).push(local);
    AppLogger.info('Kept this device profile over the account');
  }

  /// Compared through JSON because [BirthProfile] has no value equality and
  /// this is the only place that needs it. `toJson` writes a literal map, so
  /// the encoding is stable enough to compare.
  static bool _sameProfile(BirthProfile a, BirthProfile b) =>
      jsonEncode(a.toJson()) == jsonEncode(b.toJson());
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
