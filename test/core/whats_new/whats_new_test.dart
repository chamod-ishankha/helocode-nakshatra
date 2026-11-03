import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/config/app_locale.dart';
import 'package:nakshatra/core/whats_new/whats_new.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// "What's new": once on Home after an update, never after a fresh install,
/// and from the same files the Play Console is given.
void main() {
  group('when Home shows it', () {
    late SharedPreferences prefs;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('not after a fresh install', () async {
      expect(
        await WhatsNew.noteLaunch(prefs, build: 8, hadProfile: false),
        isEmpty,
      );
    });

    test(
      'after the update that brings it, for a reader already here',
      () async {
        // The first release with What's new has no record of the build before;
        // a profile on the phone is the sign of an update.
        expect(await WhatsNew.noteLaunch(prefs, build: 8, hadProfile: true), [
          8,
        ]);
      },
    );

    test('once: the next launch of the same build shows nothing', () async {
      await WhatsNew.noteLaunch(prefs, build: 8, hadProfile: true);
      expect(
        await WhatsNew.noteLaunch(prefs, build: 8, hadProfile: true),
        isEmpty,
      );
    });

    test('a later update shows every release since, newest first', () async {
      await WhatsNew.noteLaunch(prefs, build: 8, hadProfile: false);
      expect(await WhatsNew.noteLaunch(prefs, build: 10, hadProfile: true), [
        10,
        9,
      ]);
    });

    test('nothing when the build cannot be read', () async {
      expect(
        await WhatsNew.noteLaunch(prefs, build: null, hadProfile: true),
        isEmpty,
      );
    });

    test('the release number from a Play versionCode or a dev build', () {
      expect(WhatsNew.releaseBuild(10001008), 8);
      expect(WhatsNew.releaseBuild(8), 8);
    });
  });

  group('the notes', () {
    test('a file is read in each language, paragraph by paragraph', () {
      final note = ReleaseNote.parse('assets/release-notes/1.2.3+14.txt', '''
<en-US>
First.

Second
over two lines.
</en-US>
<si-LK>
පළමු.
</si-LK>
''')!;
      expect(note.version, '1.2.3');
      expect(note.build, 14);
      expect(note.forLocale(AppLocale.en), [
        'First.',
        'Second\nover two lines.',
      ]);
      expect(note.forLocale(AppLocale.si), ['පළමු.']);
      // No Tamil: English rather than nothing.
      expect(note.forLocale(AppLocale.ta), note.forLocale(AppLocale.en));
    });

    test('the README is not a release', () {
      expect(
        ReleaseNote.parse('assets/release-notes/README.md', '# x'),
        isNull,
      );
    });

    // The same files go to the Play Console. One that does not parse would
    // show nothing in the app; one over 500 characters is cut off by Play.
    final files = Directory(
      'assets/release-notes',
    ).listSync().whereType<File>().where((f) => f.path.endsWith('.txt'));
    for (final file in files) {
      test('${file.uri.pathSegments.last} has all three languages, '
          'each within Play\'s limit', () {
        final text = file.readAsStringSync();
        final note = ReleaseNote.parse(file.path, text);
        expect(note, isNotNull);
        expect(note!.paragraphs.keys, unorderedEquals(['en', 'si', 'ta']));
        for (final m in RegExp(
          r'<([a-z]{2}-[A-Z]{2})>\n(.*?)\n</\1>',
          dotAll: true,
        ).allMatches(text)) {
          expect(
            m.group(2)!.length,
            lessThanOrEqualTo(500),
            reason: m.group(1),
          );
        }
      });
    }
  });
}
