import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/app_locale.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/birth_profile.dart';

/// Local storage for the saved profile and language choice.
///
/// Interim implementation on SharedPreferences. Drift/SQLite replaces this in
/// KAN-19, which is also when multiple saved profiles arrive — this class
/// deliberately stores a single profile and nothing else.
///
/// Birth details never leave the device. There is no sync, no account, and no
/// backup to any server, which is what the privacy policy commits to.
class ProfileRepository {
  ProfileRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _profileKey = 'birth_profile_v1';
  static const _localeKey = 'app_locale_v1';

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
  }

  Future<void> clear() async {
    await ref.read(profileRepositoryProvider).clear();
    state = null;
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
