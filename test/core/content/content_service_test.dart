import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/content/content_bundle.dart';
import 'package:nakshatra/core/content/content_service.dart';

/// KAN-49 FRD §8.5: a newer version replaces, an older or equal one is
/// ignored, an invalid bundle is rejected, and offline keeps the last good
/// one. Built on the real bundled copy, which is exactly the shape the admin
/// panel publishes.
void main() {
  late Directory dir;
  late Map<String, dynamic> base;

  Map<String, dynamic> bundle(
    int version, {
    void Function(Map<String, dynamic> f)? edit,
  }) {
    final json = jsonDecode(jsonEncode(base)) as Map<String, dynamic>;
    json['version'] = version;
    edit?.call(json['fragments'] as Map<String, dynamic>);
    return json;
  }

  setUpAll(() {
    List<dynamic> load(String lang) =>
        (jsonDecode(
                  File(
                    'assets/content/horoscope_$lang.json',
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>)['fragments']
            as List<dynamic>;
    base = {
      'version': 1,
      'publishedAt': '2026-10-08T00:00:00Z',
      'fragments': {'en': load('en'), 'si': load('si'), 'ta': load('ta')},
    };
  });

  setUp(() => dir = Directory.systemTemp.createTempSync('content_test'));
  tearDown(() => dir.deleteSync(recursive: true));

  ContentService service(
    Map<int, Map<String, dynamic>?> published, {
    List<int>? asked,
    bool offline = false,
  }) => ContentService(
    directory: () async => dir,
    fetch: (v) async {
      asked?.add(v);
      if (offline) throw const SocketException('offline');
      return published[v];
    },
  );

  group('the bundle', () {
    test('the copy the app ships passes as a bundle', () {
      final b = ContentBundle.fromJson(bundle(1));
      expect(b.fragmentsFor('si'), hasLength(b.fragmentsFor('en')!.length));
    });

    test('a language disagreeing with English on conditions is refused', () {
      // Two readers on the same day would get different predictions.
      final bad = bundle(
        1,
        edit: (f) {
          final conditional =
              (f['ta'] as List).firstWhere(
                    (x) => (x as Map).containsKey('requires'),
                  )
                  as Map;
          conditional['requires'] = ['mood.bright'];
        },
      );
      expect(() => ContentBundle.fromJson(bad), throwsFormatException);
    });

    test('a missing language is refused', () {
      expect(
        () => ContentBundle.fromJson(bundle(1, edit: (f) => f.remove('ta'))),
        throwsFormatException,
      );
    });

    test('a language with a line the others lack is refused', () {
      expect(
        () => ContentBundle.fromJson(
          bundle(1, edit: (f) => (f['si'] as List).removeLast()),
        ),
        throwsFormatException,
      );
    });

    test('a category left empty is refused', () {
      // A whole section would vanish from every reading.
      final bad = bundle(
        1,
        edit: (f) {
          for (final lang in ContentBundle.languages) {
            (f[lang] as List).removeWhere(
              (x) => (x as Map)['category'] == 'health',
            );
          }
        },
      );
      expect(() => ContentBundle.fromJson(bad), throwsFormatException);
    });

    test('a bundle carrying a calendar keeps it', () {
      final json = bundle(1)
        ..['poyaDays'] = {
          '2026-10-25': {'month': 'vap', 'isAdhi': false},
          '2026-11-24': {'month': 'il', 'isAdhi': false},
        }
        ..['festivals'] = <Object>[];
      expect(ContentBundle.fromJson(json).calendar?.poyaDays, hasLength(2));
      expect(ContentBundle.fromJson(bundle(1)).calendar, isNull);
    });

    test('a bad calendar takes the whole bundle down, copy included', () {
      // A wrong religious date is worse than none.
      final json = bundle(1)
        ..['poyaDays'] = {
          '2026-10-25': {'month': 'vap', 'isAdhi': false},
          '2026-11-10': {'month': 'il', 'isAdhi': false},
        };
      expect(() => ContentBundle.fromJson(json), throwsFormatException);
    });

    test('a line the app cannot parse is refused', () {
      final bad = bundle(
        1,
        edit: (f) => ((f['en'] as List).first as Map)['category'] = 'weather',
      );
      expect(() => ContentBundle.fromJson(bad), throwsFormatException);
    });
  });

  group('updates', () {
    test('a newer version replaces, and is there next launch', () async {
      final s = service({2: bundle(2)});
      final got = await s.update(2);
      expect(got?.version, 2);
      expect((await s.loadStored())?.version, 2);
    });

    test('an older or equal version is not even fetched', () async {
      final asked = <int>[];
      final s = service({2: bundle(2)}, asked: asked);
      final held = ContentBundle.fromJson(bundle(3));
      expect(await s.update(3, held: held), isNull);
      expect(await s.update(2, held: held), isNull);
      expect(await s.update(0), isNull);
      expect(asked, isEmpty);
    });

    test('an invalid bundle is rejected and the last good one stays', () async {
      final s = service({
        2: bundle(2),
        3: bundle(3, edit: (f) => f.remove('si')),
      });
      await s.update(2);
      expect(await s.update(3, held: await s.loadStored()), isNull);
      expect((await s.loadStored())?.version, 2);
    });

    test(
      'a bundle claiming a different version than asked for is rejected',
      () async {
        final s = service({4: bundle(3)});
        expect(await s.update(4), isNull);
        expect(await s.loadStored(), isNull);
      },
    );

    test('offline keeps the last good one', () async {
      await service({2: bundle(2)}).update(2);
      final offline = service({}, offline: true);
      expect(await offline.update(3, held: await offline.loadStored()), isNull);
      expect((await offline.loadStored())?.version, 2);
    });

    test('a version not published yet is not an error', () async {
      expect(await service({}).update(5), isNull);
    });

    test('a corrupt stored file is discarded, not fatal', () async {
      File(
        '${dir.path}/content_bundle.json',
      ).writeAsStringSync('{"version": 2, "fragm');
      final s = service({});
      expect(await s.loadStored(), isNull);
      expect(File('${dir.path}/content_bundle.json').existsSync(), isFalse);
    });
  });
}
