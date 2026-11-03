import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_locale.dart';
import '../logging/app_logger.dart';

/// One release's "What's new", from `assets/release-notes/{version}.txt`.
///
/// The file is the one pasted into the Play Console, in Play's tagged format,
/// so the store and the app say the same words and nobody writes them twice.
class ReleaseNote {
  const ReleaseNote({
    required this.version,
    required this.build,
    required this.paragraphs,
  });

  /// `1.0.1`, as the reader sees it in Settings.
  final String version;

  /// The `+N` of `pubspec.yaml`. Releases are ordered by it.
  final int build;

  /// By language code, each a list of paragraphs.
  final Map<String, List<String>> paragraphs;

  static const _tags = {'en': 'en-US', 'si': 'si-LK', 'ta': 'ta-IN'};

  /// The paragraphs in [locale], or English when this release has none in
  /// it — better a note in English than none.
  List<String> forLocale(AppLocale locale) =>
      paragraphs[locale.code] ?? paragraphs['en'] ?? const [];

  /// Parses `1.0.1+8.txt`. Null for anything that is not a release file, such
  /// as the folder's README.
  static ReleaseNote? parse(String fileName, String text) {
    final name = RegExp(r'(\d+\.\d+\.\d+)\+(\d+)\.txt$').firstMatch(fileName);
    if (name == null) return null;

    final paragraphs = <String, List<String>>{};
    for (final MapEntry(key: code, value: tag) in _tags.entries) {
      final body = RegExp(
        '<$tag>\\s*(.*?)\\s*</$tag>',
        dotAll: true,
      ).firstMatch(text)?.group(1);
      if (body == null || body.isEmpty) continue;
      paragraphs[code] = [
        for (final p in body.split(RegExp(r'\n\s*\n')))
          if (p.trim().isNotEmpty) p.trim(),
      ];
    }
    if (paragraphs.isEmpty) return null;
    return ReleaseNote(
      version: name.group(1)!,
      build: int.parse(name.group(2)!),
      paragraphs: paragraphs,
    );
  }

  /// One note from the admin panel's feed: `{build, version, notes: {en:
  /// [paragraphs], si, ta}}`. Null when it cannot be shown — no build, no
  /// version, or no English to fall back on.
  static ReleaseNote? fromJson(Map<String, dynamic> json) {
    final build = json['build'];
    final version = json['version'];
    final notes = json['notes'];
    if (build is! int ||
        build <= 0 ||
        version is! String ||
        !RegExp(r'^\d+\.\d+\.\d+$').hasMatch(version) ||
        notes is! Map) {
      return null;
    }
    final paragraphs = <String, List<String>>{};
    for (final code in _tags.keys) {
      final list = notes[code];
      if (list is! List) continue;
      final kept = [
        for (final p in list)
          if (p is String && p.trim().isNotEmpty) p.trim(),
      ];
      if (kept.isNotEmpty) paragraphs[code] = kept;
    }
    if (!paragraphs.containsKey('en')) return null;
    return ReleaseNote(version: version, build: build, paragraphs: paragraphs);
  }
}

/// When to show "What's new" on Home: once, on the first launch after an
/// update.
///
/// Not after a fresh install. Someone who has just installed the app has
/// nothing to compare against, and a list of changes is the wrong first thing
/// to read.
abstract final class WhatsNew {
  /// The build whose notes the reader has been shown, or would have been.
  static const seenKey = 'whats_new.seen_build_v1';

  /// The `+N` from an Android versionCode. Play builds encode the version in
  /// it (1.0.1+8 is 10001008) and `flutter run` builds are the bare `N`; the
  /// last three digits are `N` in both.
  static int releaseBuild(int versionCode) => versionCode % 1000;

  /// Called once at launch, before the first frame. Returns the builds whose
  /// notes to show on Home this launch, newest first, and records them as
  /// seen — so closing the app without looking is the reader's one chance,
  /// as asked.
  ///
  /// [hadProfile] tells an update from a fresh install the first time this
  /// runs: the release that adds it has no record of what came before, and
  /// a profile already on the phone means the app was in use.
  static Future<List<int>> noteLaunch(
    SharedPreferences prefs, {
    required int? build,
    required bool hadProfile,
  }) async {
    if (build == null) return const [];
    final seen = prefs.getInt(seenKey) ?? (hadProfile ? build - 1 : build);
    await prefs.setInt(seenKey, build);
    if (build <= seen) return const [];
    return [for (var b = build; b > seen; b--) b];
  }

  /// Every release note bundled with the app, newest first.
  static Future<List<ReleaseNote>> load(AssetBundle bundle) async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(bundle);
      final notes = <ReleaseNote>[];
      for (final path in manifest.listAssets()) {
        if (!path.startsWith('assets/release-notes/')) continue;
        final note = ReleaseNote.parse(path, await bundle.loadString(path));
        if (note != null) notes.add(note);
      }
      return notes..sort((a, b) => b.build.compareTo(a.build));
    } on Object catch (e) {
      AppLogger.warn('Release notes unavailable: $e');
      return const [];
    }
  }

  /// This build's `+N`, or null when it cannot be read.
  static Future<int?> currentBuild() async {
    try {
      final code = int.tryParse((await PackageInfo.fromPlatform()).buildNumber);
      return code == null ? null : releaseBuild(code);
    } on Object catch (e) {
      AppLogger.warn('Build number unavailable: $e');
      return null;
    }
  }
}

/// The builds whose notes Home shows this launch, from [WhatsNew.noteLaunch].
/// Overridden in bootstrap; empty everywhere else, tests included.
final whatsNewThisLaunchProvider = Provider<List<int>>((ref) => const []);

/// The notes this build shipped with. What readers see is these with the
/// published feed laid over them (`releaseNotesProvider`, lib/core/feed).
final bundledReleaseNotesProvider = FutureProvider<List<ReleaseNote>>(
  (ref) => WhatsNew.load(rootBundle),
);

/// Closed for the rest of this launch. It is not coming back on the next one
/// either: [WhatsNew.noteLaunch] has already recorded it as seen.
final whatsNewClosedProvider = NotifierProvider<WhatsNewClosed, bool>(
  WhatsNewClosed.new,
);

class WhatsNewClosed extends Notifier<bool> {
  @override
  bool build() => false;

  void close() => state = true;
}
