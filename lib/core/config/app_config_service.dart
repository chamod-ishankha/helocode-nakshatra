import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/onboarding/data/profile_repository.dart';
import '../logging/app_logger.dart';
import '../sync/firebase_service.dart';
import 'app_config.dart';
import 'flavor.dart';

/// Fetches `config/app`, caches it, and never blocks a launch (KAN-49 §8.1).
///
/// The successor to `RemoteConfigService`, which Firebase moved behind the
/// Blaze plan. Same discipline: the first frame uses whatever is cached (or
/// [AppConfig.none]), the fetch runs in the background, and every failure
/// is swallowed and logged.
///
/// ## The Firestore budget
///
/// One read per fetch, and a fetch at most once a day in prod. That is the
/// one read that scales with users, and at Spark's 50k/day it is the ceiling
/// on daily active users this design can serve — see FRD §7, which names the
/// Cloudflare Pages fallback for the day that ceiling is reached.
///
/// Dev refetches every minute so a publish can be seen without reinstalling.
class AppConfigService {
  AppConfigService({
    required SharedPreferences prefs,
    required Flavor flavor,
    FirebaseFirestore? firestore,
    DateTime Function()? clock,
  }) : _prefs = prefs,
       _flavor = flavor,
       _firestore = firestore,
       _clock = clock ?? DateTime.now;

  final SharedPreferences _prefs;
  final Flavor _flavor;
  final FirebaseFirestore? _firestore;
  final DateTime Function() _clock;

  static const _docPath = 'config/app';
  static const _cacheKey = 'app_config.json';
  static const _fetchedAtKey = 'app_config.fetched_at';

  Duration get _maxAge =>
      _flavor.isDev ? const Duration(minutes: 1) : const Duration(hours: 24);

  /// What is cached on this phone, parsed. [AppConfig.none] if nothing is.
  AppConfig cached() {
    final raw = _prefs.getString(_cacheKey);
    if (raw == null) return AppConfig.none;
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return AppConfig.none;
      return AppConfig.fromJson(json);
    } on Object catch (e) {
      // A cache this process cannot read is worth nothing; drop it rather
      // than fail the same way at every launch.
      AppLogger.warn('Cached app config unreadable, discarding: $e');
      return AppConfig.none;
    }
  }

  /// Whether the cache is old enough to be worth a read.
  bool get isStale {
    final at = _prefs.getInt(_fetchedAtKey);
    if (at == null) return true;
    return _clock().difference(DateTime.fromMillisecondsSinceEpoch(at)) >
        _maxAge;
  }

  /// Fetches if stale, returning the config now in force (new or cached).
  ///
  /// Never throws. A phone with no signal gets the cache; a project with no
  /// document gets [AppConfig.none]; a document this app cannot parse is
  /// logged and ignored, leaving the last good one in place.
  Future<AppConfig> refresh({bool force = false}) async {
    final db = _firestore;
    if (db == null || (!force && !isStale)) return cached();

    try {
      final snapshot = await db
          .doc(_docPath)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 10));
      // Stamped even when the document is absent: "nothing published" is an
      // answer, and asking again every launch would spend reads on it.
      await _prefs.setInt(_fetchedAtKey, _clock().millisecondsSinceEpoch);

      final data = snapshot.data();
      if (data == null) {
        await _prefs.remove(_cacheKey);
        return AppConfig.none;
      }
      final config = AppConfig.fromJson(_plain(data));
      await _prefs.setString(_cacheKey, jsonEncode(config.toJson()));
      AppLogger.info(
        'App config ${config.publishedAt?.toIso8601String() ?? '(unstamped)'} in force',
      );
      return config;
    } on Object catch (e) {
      AppLogger.warn('App config fetch failed, using cache: $e');
      return cached();
    }
  }

  /// Firestore hands back Timestamps and nested maps of its own types; the
  /// parser wants plain JSON, and the cache has to be JSON anyway.
  static Map<String, dynamic> _plain(Map<String, dynamic> data) {
    Object? walk(Object? v) => switch (v) {
      Timestamp t => t.toDate().toUtc().toIso8601String(),
      Map m => {for (final e in m.entries) e.key.toString(): walk(e.value)},
      List l => l.map(walk).toList(),
      _ => v,
    };
    return walk(data) as Map<String, dynamic>;
  }
}

/// The config in force, updated when a fetch lands.
///
/// Reads the cache synchronously in [build], so the first frame already has
/// the last known config — a gate published yesterday holds on a phone that
/// is offline today.
class AppConfigNotifier extends Notifier<AppConfig> {
  @override
  AppConfig build() => ref.watch(appConfigServiceProvider).cached();

  /// Kicks off the background fetch. Called once from bootstrap, not awaited.
  Future<void> refresh({bool force = false}) async {
    final next = await ref.read(appConfigServiceProvider).refresh(force: force);
    state = next;
  }
}

final appConfigServiceProvider = Provider<AppConfigService>(
  (ref) => AppConfigService(
    prefs: ref.watch(sharedPreferencesProvider),
    flavor: FlavorConfig.current.flavor,
    firestore: FirebaseService.isAvailable ? FirebaseFirestore.instance : null,
  ),
);

final appConfigProvider = NotifierProvider<AppConfigNotifier, AppConfig>(
  AppConfigNotifier.new,
);

/// The switches alone, for the three seams that read them.
final switchesProvider = Provider<Switches>(
  (ref) => ref.watch(appConfigProvider).switches,
);
