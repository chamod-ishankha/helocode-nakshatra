import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/feed/feed.dart';
import 'package:nakshatra/core/feed/feed_reads.dart';
import 'package:nakshatra/core/feed/feed_service.dart';
import 'package:nakshatra/core/whats_new/whats_new.dart';

/// The notices and release notes the admin panel publishes, and what Home
/// makes of them.
void main() {
  Map<String, dynamic> notice(
    String id,
    String at, {
    Map<String, dynamic>? banner,
    String? en = 'Hello',
  }) => {
    'id': id,
    'publishedAt': at,
    'title': {'en': en, 'si': 'ආයුබෝවන්', 'ta': 'வணக்கம்'},
    'body': {'en': 'Body', 'si': '', 'ta': ''},
    'link': 'https://helocode.top/nakshatra',
    'banner': ?banner,
  };
  Map<String, dynamic> note(int build, {String version = '1.0.1'}) => {
    'build': build,
    'version': version,
    'notes': {
      'en': ['First $build.', 'Second.'],
      'si': ['පළමු.'],
      'ta': <String>[],
    },
  };
  Map<String, dynamic> feed(int version, {List<Object>? notices}) => {
    'version': version,
    'notices': notices ?? [notice('a', '2026-10-01T00:00:00Z')],
    'releaseNotes': [note(7), note(8)],
  };

  group('the feed', () {
    test('notices newest first, notes newest build first', () {
      final f = Feed.fromJson(
        feed(
          3,
          notices: [
            notice('old', '2026-09-01T00:00:00Z'),
            notice('new', '2026-10-01T00:00:00Z'),
          ],
        ),
      );
      expect(f.notices.map((n) => n.id), ['new', 'old']);
      expect(f.releaseNotes.map((n) => n.build), [8, 7]);
    });

    test('one bad notice is dropped, not the feed', () {
      final f = Feed.fromJson(
        feed(
          3,
          notices: [
            notice('good', '2026-10-01T00:00:00Z'),
            notice('no-english', '2026-10-02T00:00:00Z', en: ''),
            notice('', '2026-10-03T00:00:00Z'),
            'not a notice',
          ],
        ),
      );
      expect(f.notices.map((n) => n.id), ['good']);
    });

    test('a document that is not a feed is refused', () {
      expect(() => Feed.fromJson({'version': 0}), throwsFormatException);
      expect(
        () => Feed.fromJson({'version': 2, 'notices': []}),
        throwsFormatException,
      );
    });

    test('a release note needs a build, a version and English', () {
      expect(ReleaseNote.fromJson(note(8))!.paragraphs['ta'], isNull);
      expect(ReleaseNote.fromJson(note(8, version: 'v1')), isNull);
      expect(ReleaseNote.fromJson(note(0)), isNull);
      expect(
        ReleaseNote.fromJson(
          note(8)
            ..['notes'] = {
              'si': ['පළමු.'],
            },
        ),
        isNull,
      );
    });
  });

  group('the banner on Home', () {
    final f = Feed.fromJson(
      feed(
        3,
        notices: [
          notice('plain', '2026-10-05T00:00:00Z'),
          notice(
            'older-banner',
            '2026-10-01T00:00:00Z',
            banner: {
              'from': '2026-10-01T00:00:00Z',
              'until': '2026-11-01T00:00:00Z',
            },
          ),
          notice(
            'newer-banner',
            '2026-10-03T00:00:00Z',
            banner: {
              'from': '2026-10-03T00:00:00Z',
              'until': '2026-10-10T00:00:00Z',
              'dismissible': false,
            },
          ),
          notice(
            'backwards',
            '2026-10-04T00:00:00Z',
            banner: {
              'from': '2026-10-09T00:00:00Z',
              'until': '2026-10-04T00:00:00Z',
            },
          ),
        ],
      ),
    );

    test('the newest notice whose window is open', () {
      expect(f.bannerAt(DateTime.utc(2026, 10, 5))?.id, 'newer-banner');
    });

    test('once that window closes, the next one still open', () {
      expect(f.bannerAt(DateTime.utc(2026, 10, 10))?.id, 'older-banner');
    });

    test('a dismissed banner gives way, unless it cannot be dismissed', () {
      expect(
        f.bannerAt(DateTime.utc(2026, 10, 12), dismissedId: 'older-banner'),
        isNull,
      );
      expect(
        f.bannerAt(DateTime.utc(2026, 10, 5), dismissedId: 'newer-banner')?.id,
        'newer-banner',
      );
    });

    test('a window that cannot open is no banner, but still a notice', () {
      expect(f.notices.any((n) => n.id == 'backwards'), isTrue);
      expect(f.notices.firstWhere((n) => n.id == 'backwards').banner, isNull);
    });

    test('nothing outside every window', () {
      expect(f.bannerAt(DateTime.utc(2026, 12, 1)), isNull);
    });
  });

  group('the dots on Home', () {
    ReleaseNote n(int build) => ReleaseNote.fromJson(note(build))!;
    final notices = Feed.fromJson(
      feed(1, notices: [notice('a', '2026-10-01T00:00:00Z')]),
    ).notices;

    test('a notice is unread until Notices is opened past it', () {
      expect(FeedReads.noticesUnread(notices, null), isTrue);
      expect(
        FeedReads.noticesUnread(notices, DateTime.utc(2026, 10, 1)),
        isFalse,
      );
      expect(
        FeedReads.noticesUnread(notices, DateTime.utc(2026, 9, 1)),
        isTrue,
      );
      expect(FeedReads.noticesUnread(const [], null), isFalse);
    });

    bool unread({
      List<ReleaseNote>? notes,
      int? seenBuild = 8,
      int? current = 8,
      int? offered,
      int? seenOffer,
    }) => FeedReads.updatesUnread(
      notes: notes ?? [n(8)],
      seenBuild: seenBuild,
      currentBuild: current,
      offeredUpdate: offered,
      seenOffer: seenOffer,
    );

    test('an update on offer lights Updates until it has been looked at', () {
      expect(unread(offered: 10001009), isTrue);
      expect(unread(offered: 10001009, seenOffer: 10001009), isFalse);
    });

    test('a higher offer lights it again', () {
      expect(unread(offered: 10001010, seenOffer: 10001009), isTrue);
    });

    test('a new reader is not told the history is news', () {
      expect(unread(notes: [n(8), n(7)], seenBuild: null), isFalse);
    });

    test('a note for a build newer than the last one looked at', () {
      expect(unread(notes: [n(9), n(8)]), isTrue);
    });

    test('the update card speaks only of a build ahead of this one', () {
      expect(FeedReads.noteAhead([n(9), n(8)], 8)?.build, 9);
      expect(FeedReads.noteAhead([n(8), n(7)], 8), isNull);
      expect(FeedReads.noteAhead([n(9)], null), isNull);
      expect(FeedReads.noteAhead(const [], 8), isNull);
    });

    test('the bell opens on whichever tab has something new', () {
      InboxTab tab(bool notices, bool updates) =>
          FeedReads.tabToOpen(noticesUnread: notices, updatesUnread: updates);
      expect(tab(false, true), InboxTab.updates);
      expect(tab(true, false), InboxTab.notices);
      expect(tab(true, true), InboxTab.notices);
      expect(tab(false, false), InboxTab.notices);
    });
  });

  test('published notes replace bundled ones build by build', () {
    ReleaseNote bundled(int b) => ReleaseNote.parse(
      'assets/release-notes/1.0.1+$b.txt',
      '<en-US>\nBundled $b.\n</en-US>',
    )!;
    final merged = FeedReads.mergeNotes(
      [bundled(6), bundled(7), bundled(8)],
      [ReleaseNote.fromJson(note(7))!, ReleaseNote.fromJson(note(9))!],
    );
    expect(merged.map((n) => n.build), [9, 8, 7, 6]);
    expect(
      merged.firstWhere((n) => n.build == 7).paragraphs['en']!.first,
      'First 7.',
    );
    expect(
      merged.firstWhere((n) => n.build == 8).paragraphs['en']!.first,
      'Bundled 8.',
    );
  });

  group('fetching', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('feed_test'));
    tearDown(() => dir.deleteSync(recursive: true));

    FeedService service(
      Map<int, Map<String, dynamic>?> published, {
      List<int>? asked,
      bool offline = false,
    }) => FeedService(
      directory: () async => dir,
      fetch: (v) async {
        asked?.add(v);
        if (offline) throw const SocketException('offline');
        return published[v];
      },
    );

    test('a newer feed replaces, and is there next launch', () async {
      final s = service({2: feed(2)});
      expect((await s.update(2))?.version, 2);
      expect((await s.loadStored())?.version, 2);
    });

    test('an older or equal one is not even fetched', () async {
      final asked = <int>[];
      final s = service({2: feed(2)}, asked: asked);
      final held = Feed.fromJson(feed(3));
      expect(await s.update(3, held: held), isNull);
      expect(await s.update(2, held: held), isNull);
      expect(await s.update(0), isNull);
      expect(asked, isEmpty);
    });

    test('offline or refused keeps the last good one', () async {
      await service({2: feed(2)}).update(2);
      expect(
        await service(
          {},
          offline: true,
        ).update(3, held: Feed.fromJson(feed(2))),
        isNull,
      );
      expect(
        await service({
          3: {'version': 3},
        }).update(3),
        isNull,
      );
      expect((await service({}).loadStored())?.version, 2);
    });

    test('a feed claiming another version than asked is refused', () async {
      expect(await service({4: feed(3)}).update(4), isNull);
    });

    test('a corrupt stored file is discarded, not fatal', () async {
      File('${dir.path}/feed.json').writeAsStringSync('{"version": 2, "no');
      expect(await service({}).loadStored(), isNull);
      expect(File('${dir.path}/feed.json').existsSync(), isFalse);
    });

    test('what is stored is what was published', () async {
      await service({2: feed(2)}).update(2);
      final stored = jsonDecode(
        File('${dir.path}/feed.json').readAsStringSync(),
      );
      expect(stored, feed(2));
    });
  });
}
