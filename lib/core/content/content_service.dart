import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../astro/sri_lankan_calendar.dart';
import '../config/app_config_service.dart';
import '../logging/app_logger.dart';
import '../sync/firebase_service.dart';
import 'content_bundle.dart';

/// The content version shipped inside this build's assets.
///
/// Bump it to the published version whenever a release refreshes
/// `assets/content/` from the admin panel's export. A phone then ignores any
/// downloaded bundle at or below it: the copy it shipped with is as new.
const int kBundledContentVersion = 0;

/// Fetches a newer published content bundle and keeps the last good one
/// (KAN-49 FRD §8.5).
///
/// One Firestore read per published version, and only when `config/app`
/// says there is a newer one than this phone holds. Never throws: any
/// failure leaves whatever was in force before — the stored bundle, or the
/// bundled assets — so a bad publish can never break the app.
class ContentService {
  ContentService({
    required Future<Directory> Function() directory,
    required Future<Map<String, dynamic>?> Function(int version) fetch,
  }) : _directory = directory,
       _fetch = fetch;

  final Future<Directory> Function() _directory;
  final Future<Map<String, dynamic>?> Function(int version) _fetch;

  static const _fileName = 'content_bundle.json';

  Future<File> _file() async => File('${(await _directory()).path}/$_fileName');

  /// The bundle stored on this phone, if it is still newer than the build's
  /// own copy and still parses.
  Future<ContentBundle?> loadStored() async {
    final file = await _file();
    try {
      if (!await file.exists()) return null;
      final bundle = ContentBundle.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>,
      );
      if (bundle.version <= kBundledContentVersion) {
        // The app was updated past it; the bundled copy is as new or newer.
        await file.delete();
        return null;
      }
      return bundle;
    } on Object catch (e) {
      AppLogger.warn('Stored content bundle unreadable, discarding: $e');
      try {
        await file.delete();
      } on Object {
        // Nothing more to do; the next fetch overwrites it.
      }
      return null;
    }
  }

  /// Fetches [latest] if it is newer than [held], returning it once stored.
  ///
  /// Null means "keep what you have": nothing newer, offline, or a bundle
  /// that failed its checks.
  Future<ContentBundle?> update(int latest, {ContentBundle? held}) async {
    final have = held?.version ?? kBundledContentVersion;
    if (latest <= have || latest <= kBundledContentVersion) return null;

    final Map<String, dynamic>? json;
    try {
      json = await _fetch(latest);
    } on Object catch (e) {
      AppLogger.warn('Content $latest fetch failed, keeping $have: $e');
      return null;
    }
    if (json == null) {
      AppLogger.warn('Content $latest is not published, keeping $have');
      return null;
    }

    final ContentBundle bundle;
    try {
      bundle = ContentBundle.fromJson(json);
    } on FormatException catch (e) {
      AppLogger.warn('Content $latest rejected, keeping $have: ${e.message}');
      return null;
    }
    if (bundle.version != latest) {
      AppLogger.warn(
        'Content $latest claims to be ${bundle.version}; rejected',
      );
      return null;
    }

    try {
      // Written aside and renamed, so a crash mid-write leaves the old file
      // whole rather than half of the new one.
      final file = await _file();
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsString(jsonEncode(json), flush: true);
      await tmp.rename(file.path);
    } on Object catch (e) {
      // Still use it this session; it is fetched again next launch.
      AppLogger.warn('Content $latest could not be stored: $e');
    }
    AppLogger.info(
      'Content $latest in force (${bundle.fragments['en']!.length} lines)',
    );
    return bundle;
  }
}

final contentServiceProvider = Provider<ContentService>((ref) {
  final db = FirebaseService.isAvailable ? FirebaseFirestore.instance : null;
  return ContentService(
    directory: getApplicationSupportDirectory,
    fetch: (version) async {
      if (db == null) return null;
      final snapshot = await db
          .doc('content/$version')
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 15));
      final data = snapshot.data();
      return data == null ? null : AppConfigService.plainJson(data);
    },
  );
});

/// The downloaded bundle in force, or null to use the bundled assets.
///
/// Resolves from local storage alone, so nothing waits on the network. When
/// `config/app` points past what is held, the newer bundle is fetched in the
/// background and replaces this value once it has passed its checks.
class ContentBundleNotifier extends AsyncNotifier<ContentBundle?> {
  int _fetching = 0;

  @override
  Future<ContentBundle?> build() async {
    final service = ref.watch(contentServiceProvider);
    final stored = await service.loadStored();
    SriLankanCalendar.usePublished(stored?.calendar);

    ref.listen<int>(
      appConfigProvider.select((c) => c.contentVersion),
      (_, latest) => unawaited(_update(service, latest)),
    );
    // The pointer may already be ahead: fetched on an earlier launch whose
    // content download did not finish.
    final latest = ref.read(appConfigProvider).contentVersion;
    if (latest > (stored?.version ?? kBundledContentVersion)) {
      unawaited(Future(() => _update(service, latest, held: stored)));
    }
    return stored;
  }

  Future<void> _update(
    ContentService service,
    int latest, {
    ContentBundle? held,
  }) async {
    if (latest <= _fetching) return; // already on its way
    _fetching = latest;
    try {
      final next = await service.update(latest, held: held ?? state.value);
      if (next != null) {
        // Before the state changes, so every provider that recomputes on it
        // reads the new calendar.
        SriLankanCalendar.usePublished(next.calendar);
        state = AsyncData(next);
      }
    } finally {
      if (_fetching == latest) _fetching = 0;
    }
  }
}

final contentBundleProvider =
    AsyncNotifierProvider<ContentBundleNotifier, ContentBundle?>(
      ContentBundleNotifier.new,
    );
