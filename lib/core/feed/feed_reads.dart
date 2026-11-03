import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/onboarding/data/profile_repository.dart';
import '../config/app_config.dart';
import '../config/version_gate.dart';
import '../whats_new/whats_new.dart';
import 'feed.dart';
import 'feed_service.dart';

/// What the reader has seen of the feed, and so whether Home's Notices and
/// Updates buttons carry a dot.
abstract final class FeedReads {
  static const noticesSeenKey = 'feed.notices_seen_at_v1';
  static const updatesSeenKey = 'feed.updates_seen_build_v1';

  /// The bundled notes with the published ones laid over them, newest first.
  ///
  /// Published wins for a build both have: that is the corrected copy. A
  /// bundled note the feed lacks still shows, so a release whose note was
  /// never entered in the panel is not missing from the list.
  static List<ReleaseNote> mergeNotes(
    List<ReleaseNote> bundled,
    List<ReleaseNote>? published,
  ) {
    final byBuild = {
      for (final n in bundled) n.build: n,
      for (final n in published ?? const <ReleaseNote>[]) n.build: n,
    };
    return byBuild.values.toList()..sort((a, b) => b.build.compareTo(a.build));
  }

  /// A notice newer than the newest the reader had when they last opened
  /// Notices — or any notice at all, if they never have.
  static bool noticesUnread(List<Notice> notices, DateTime? seenAt) =>
      notices.isNotEmpty &&
      (seenAt == null || notices.first.publishedAt.isAfter(seenAt));

  /// An update to take, or a note for a build newer than the newest the
  /// reader has looked at.
  ///
  /// Never having opened Updates counts as having seen up to this build: a
  /// new reader is not told the history of an app they have just installed
  /// is news.
  static bool updatesUnread({
    required List<ReleaseNote> notes,
    required int? seenBuild,
    required int? currentBuild,
    required bool updateAvailable,
  }) {
    if (updateAvailable) return true;
    if (notes.isEmpty) return false;
    final seen = seenBuild ?? currentBuild;
    return seen != null && notes.first.build > seen;
  }
}

/// The notes readers see: bundled, with the published feed laid over them.
final releaseNotesProvider = Provider<List<ReleaseNote>>(
  (ref) => FeedReads.mergeNotes(
    ref.watch(bundledReleaseNotesProvider).value ?? const [],
    ref.watch(feedProvider).value?.releaseNotes,
  ),
);

final noticesProvider = Provider<List<Notice>>(
  (ref) => ref.watch(feedProvider).value?.notices ?? const [],
);

/// This build's `+N`, or null while unknown.
final currentReleaseBuildProvider = Provider<int?>((ref) {
  final code = ref.watch(buildNumberProvider).value;
  return code == null ? null : WhatsNew.releaseBuild(code);
});

class FeedSeen extends Notifier<({DateTime? noticesAt, int? updatesBuild})> {
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  ({DateTime? noticesAt, int? updatesBuild}) build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final at = prefs.getString(FeedReads.noticesSeenKey);
    return (
      noticesAt: at == null ? null : DateTime.tryParse(at),
      updatesBuild: prefs.getInt(FeedReads.updatesSeenKey),
    );
  }

  Future<void> sawNotices(List<Notice> notices) async {
    if (notices.isEmpty) return;
    final newest = notices.first.publishedAt;
    await _prefs.setString(FeedReads.noticesSeenKey, newest.toIso8601String());
    state = (noticesAt: newest, updatesBuild: state.updatesBuild);
  }

  Future<void> sawUpdates(List<ReleaseNote> notes) async {
    if (notes.isEmpty) return;
    final newest = notes.first.build;
    await _prefs.setInt(FeedReads.updatesSeenKey, newest);
    state = (noticesAt: state.noticesAt, updatesBuild: newest);
  }
}

final feedSeenProvider =
    NotifierProvider<FeedSeen, ({DateTime? noticesAt, int? updatesBuild})>(
      FeedSeen.new,
    );

final noticesUnreadProvider = Provider<bool>(
  (ref) => FeedReads.noticesUnread(
    ref.watch(noticesProvider),
    ref.watch(feedSeenProvider).noticesAt,
  ),
);

final updatesUnreadProvider = Provider<bool>(
  (ref) => FeedReads.updatesUnread(
    notes: ref.watch(releaseNotesProvider),
    seenBuild: ref.watch(feedSeenProvider).updatesBuild,
    currentBuild: ref.watch(currentReleaseBuildProvider),
    updateAvailable:
        ref.watch(gateVerdictProvider) == GateVerdict.updateAvailable,
  ),
);
