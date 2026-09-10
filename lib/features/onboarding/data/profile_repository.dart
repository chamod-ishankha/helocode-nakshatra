import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/app_locale.dart';
import '../../../core/config/chart_style.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/profile_store.dart';
import '../../../core/notifications/notification_prefs.dart';
import '../../../core/config/theme_preference.dart';
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
  ProfileRepository(this._prefs, {ProfileStore? store, BirthProfile? initial})
    : _store = store,
      _cached = initial;

  final SharedPreferences _prefs;

  /// The database, once it is open. Null in tests that only need preferences.
  final ProfileStore? _store;

  /// The profile as the database had it at startup, kept in memory so [load]
  /// can stay synchronous.
  ///
  /// The router decides where to send the user before the first frame, from
  /// whether a profile exists. An async read there would turn that decision
  /// into a race with itself, so the one read happens in bootstrap and the
  /// answer is handed in.
  BirthProfile? _cached;

  static const _profileKey = 'birth_profile_v1';
  static const _localeKey = 'app_locale_v1';
  static const _chartStyleKey = 'chart_style_v1';
  static const _themeKey = 'theme_preference_v1';
  static const _notificationsKey = 'notification_prefs_v1';

  BirthProfile? load() {
    // The database wins once it has been read. Preferences are only consulted
    // on the very first launch after upgrading, before the migration has run.
    final cached = _cached;
    if (cached != null) return cached;

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

  /// Saves to the database, and mirrors to preferences.
  ///
  /// The mirror is deliberate. It is not a second source of truth — [load]
  /// never prefers it once the database has been read — it is the only way
  /// back if the database file is ever lost, and it costs a few hundred
  /// bytes. Leaving a *stale* copy there would be worse than none: a restore
  /// would silently hand the user a birth time they corrected months ago.
  Future<void> save(BirthProfile profile) async {
    _cached = profile;
    await _store?.upsertSelected(profile);
    await _saveToPrefs(profile);
  }

  Future<void> clear() async {
    _cached = null;
    await _store?.clear();
    await _prefs.remove(_profileKey);
  }

  Future<void> _saveToPrefs(BirthProfile profile) =>
      _prefs.setString(_profileKey, jsonEncode(profile.toJson()));

  /// The saved language, or the device's if the user has not chosen yet.
  ///
  /// Defaulting to English would show an English first screen to a Sinhala
  /// phone, which is the wrong first impression for this audience. The picker
  /// in onboarding then confirms rather than introduces the choice.
  AppLocale loadLocale() {
    final saved = _prefs.getString(_localeKey);
    if (saved != null) return AppLocale.fromCode(saved);
    return AppLocale.fromCode(PlatformDispatcher.instance.locale.languageCode);
  }

  Future<void> saveLocale(AppLocale locale) =>
      _prefs.setString(_localeKey, locale.code);

  /// What the user asked to be notified about.
  ///
  /// A corrupt value reads as "nothing enabled" rather than throwing: the
  /// alternative is an app that will not start because of a preference.
  NotificationPrefs loadNotificationPrefs() {
    final raw = _prefs.getString(_notificationsKey);
    if (raw == null) return const NotificationPrefs();

    try {
      return NotificationPrefs.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } on Object {
      return const NotificationPrefs();
    }
  }

  Future<void> saveNotificationPrefs(NotificationPrefs prefs) =>
      _prefs.setString(_notificationsKey, jsonEncode(prefs.toJson()));

  ChartStyle loadChartStyle() =>
      ChartStyle.fromName(_prefs.getString(_chartStyleKey));

  Future<void> saveChartStyle(ChartStyle style) =>
      _prefs.setString(_chartStyleKey, style.name);

  ThemePreference loadTheme() =>
      ThemePreference.fromName(_prefs.getString(_themeKey));

  Future<void> saveTheme(ThemePreference p) =>
      _prefs.setString(_themeKey, p.name);
}

/// Overridden at startup with the real instance, once SharedPreferences has
/// loaded. Reading it before then is a programmer error, not a runtime state.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

/// The open database, or null when there is not one.
///
/// Nullable rather than throwing like [sharedPreferencesProvider], because the
/// two are not the same kind of dependency. Preferences are mandatory; the
/// database is an upgrade the repository can do without — a build that cannot
/// open it falls back to preferences and the user keeps their profile. Tests
/// that do not care about storage get null rather than an exception from a
/// provider they never asked for.
final appDatabaseProvider = Provider<AppDatabase?>((ref) => null);

final profileStoreProvider = Provider<ProfileStore?>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db == null ? null : ProfileStore(db);
});

/// What the database held at startup, after any migration.
///
/// Null on a fresh install, and null in tests that do not stand up a database
/// — in which case the repository falls back to preferences, which is exactly
/// what every existing test expects.
final initialProfileProvider = Provider<BirthProfile?>((ref) => null);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(
    ref.watch(sharedPreferencesProvider),
    store: ref.watch(profileStoreProvider),
    initial: ref.watch(initialProfileProvider),
  ),
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

  /// Erases the profile locally and in the backup.
  ///
  /// The backup delete is awaited, unlike the push in [save]. A push happens
  /// on the way to somewhere else and must not hold up navigation; a deletion
  /// is the thing the user is waiting for, and reporting success before it
  /// lands would be a lie.
  Future<void> clear() async {
    await ref.read(profileRepositoryProvider).clear();
    await ref.read(profileSyncProvider).clear();
    state = null;
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

/// Light, dark or system. Persisted so a choice made outdoors survives a
/// restart.
class ThemeNotifier extends Notifier<ThemePreference> {
  @override
  ThemePreference build() => ref.watch(profileRepositoryProvider).loadTheme();

  Future<void> set(ThemePreference p) async {
    await ref.read(profileRepositoryProvider).saveTheme(p);
    state = p;
  }
}

final themePreferenceProvider =
    NotifierProvider<ThemeNotifier, ThemePreference>(ThemeNotifier.new);
