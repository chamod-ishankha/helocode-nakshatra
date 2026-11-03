import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../config/app_config_service.dart';
import '../logging/app_logger.dart';
import '../sync/firebase_service.dart';
import 'feed.dart';

/// Fetches a newer published feed and keeps the last good one.
///
/// The content bundle's pattern (ContentService): one Firestore read per
/// published version, only when `config/app` points past what this phone
/// holds. Never throws; any failure keeps what was in force — the stored
/// feed, or none, which leaves the bundled release notes and no notices.
class FeedService {
  FeedService({
    required Future<Directory> Function() directory,
    required Future<Map<String, dynamic>?> Function(int version) fetch,
  }) : _directory = directory,
       _fetch = fetch;

  final Future<Directory> Function() _directory;
  final Future<Map<String, dynamic>?> Function(int version) _fetch;

  static const _fileName = 'feed.json';

  Future<File> _file() async => File('${(await _directory()).path}/$_fileName');

  /// The feed stored on this phone, if it still parses.
  Future<Feed?> loadStored() async {
    final file = await _file();
    try {
      if (!await file.exists()) return null;
      return Feed.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>,
      );
    } on Object catch (e) {
      AppLogger.warn('Stored feed unreadable, discarding: $e');
      try {
        await file.delete();
      } on Object {
        // The next fetch overwrites it.
      }
      return null;
    }
  }

  /// Fetches [latest] if it is newer than [held], returning it once stored.
  /// Null means "keep what you have".
  Future<Feed?> update(int latest, {Feed? held}) async {
    final have = held?.version ?? 0;
    if (latest <= have) return null;

    final Map<String, dynamic>? json;
    try {
      json = await _fetch(latest);
    } on Object catch (e) {
      AppLogger.warn('Feed $latest fetch failed, keeping $have: $e');
      return null;
    }
    if (json == null) {
      AppLogger.warn('Feed $latest is not published, keeping $have');
      return null;
    }

    final Feed feed;
    try {
      feed = Feed.fromJson(json);
    } on FormatException catch (e) {
      AppLogger.warn('Feed $latest rejected, keeping $have: ${e.message}');
      return null;
    }
    if (feed.version != latest) {
      AppLogger.warn('Feed $latest claims to be ${feed.version}; rejected');
      return null;
    }

    try {
      // Aside and renamed, so a crash mid-write leaves the old file whole.
      final file = await _file();
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsString(jsonEncode(json), flush: true);
      await tmp.rename(file.path);
    } on Object catch (e) {
      AppLogger.warn('Feed $latest could not be stored: $e');
    }
    AppLogger.info(
      'Feed $latest in force (${feed.notices.length} notices, '
      '${feed.releaseNotes.length} release notes)',
    );
    return feed;
  }
}

final feedServiceProvider = Provider<FeedService>((ref) {
  final db = FirebaseService.isAvailable ? FirebaseFirestore.instance : null;
  return FeedService(
    directory: getApplicationSupportDirectory,
    fetch: (version) async {
      if (db == null) return null;
      final snapshot = await db
          .doc('feed/$version')
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 15));
      final data = snapshot.data();
      return data == null ? null : AppConfigService.plainJson(data);
    },
  );
});

/// The feed in force, or null before the first publish reaches this phone.
///
/// Resolves from local storage alone; a newer feed is fetched in the
/// background when `config/app` points past it.
class FeedNotifier extends AsyncNotifier<Feed?> {
  int _fetching = 0;

  @override
  Future<Feed?> build() async {
    final service = ref.watch(feedServiceProvider);
    final stored = await service.loadStored();

    ref.listen<int>(
      appConfigProvider.select((c) => c.feedVersion),
      (_, latest) => unawaited(_update(service, latest)),
    );
    final latest = ref.read(appConfigProvider).feedVersion;
    if (latest > (stored?.version ?? 0)) {
      unawaited(Future(() => _update(service, latest, held: stored)));
    }
    return stored;
  }

  Future<void> _update(FeedService service, int latest, {Feed? held}) async {
    if (latest <= _fetching) return; // already on its way
    _fetching = latest;
    try {
      final next = await service.update(latest, held: held ?? state.value);
      if (next != null) state = AsyncData(next);
    } finally {
      if (_fetching == latest) _fetching = 0;
    }
  }
}

final feedProvider = AsyncNotifierProvider<FeedNotifier, Feed?>(
  FeedNotifier.new,
);
