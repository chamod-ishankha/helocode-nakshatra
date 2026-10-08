import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/config/app_config.dart';
import 'package:nakshatra/core/config/app_locale.dart';
import 'package:nakshatra/core/config/flavor.dart';

/// The config the admin panel publishes, as the app reads it (KAN-49).
///
/// All pure: no Firestore, no widgets. What is tested is the contract —
/// what a build is told, when a notice shows, and that a document the app
/// does not fully understand can never break it.
void main() {
  const msg = {'en': 'Update', 'si': 'යාවත්කාලීන', 'ta': 'புதுப்பிக்க'};

  group('the version gate', () {
    VersionGate gate({int min = 0, int latest = 0}) => VersionGate.fromJson({
      'minimumBuild': min,
      'latestBuild': latest,
      'message': msg,
    });

    test('blocks below the minimum and passes at it', () {
      // The minimum is the oldest build still allowed, not the first
      // refused. Off by one here would block the build just released.
      final g = gate(min: 10001006, latest: 10001008);
      expect(g.verdictFor(10001005), GateVerdict.blocked);
      expect(g.verdictFor(10001006), GateVerdict.updateAvailable);
      expect(g.verdictFor(10001008), GateVerdict.current);
      expect(g.verdictFor(10001009), GateVerdict.current);
    });

    test('a gate of zero never fires', () {
      expect(gate().verdictFor(1), GateVerdict.current);
      expect(gate(latest: 5).verdictFor(1), GateVerdict.updateAvailable);
      expect(gate(latest: 5).verdictFor(5), GateVerdict.current);
    });

    test('the blocked verdict wins over the update one', () {
      expect(gate(min: 5, latest: 9).verdictFor(3), GateVerdict.blocked);
    });

    test('a negative or non-numeric build in the document means zero', () {
      expect(VersionGate.fromJson({'minimumBuild': -3}).minimumBuild, 0);
      expect(VersionGate.fromJson({'minimumBuild': 'x'}).minimumBuild, 0);
    });

    test('only web links are accepted as the store url', () {
      // A config must not be able to send the phone to an arbitrary scheme.
      expect(
        VersionGate.fromJson({'storeUrl': 'intent://x'}).storeUrl,
        VersionGate.none.storeUrl,
      );
      expect(
        VersionGate.fromJson({'storeUrl': 'https://example.com/a'}).storeUrl,
        'https://example.com/a',
      );
    });
  });

  group('the announcement', () {
    final from = DateTime.utc(2026, 10, 20);
    final until = DateTime.utc(2026, 10, 26);
    Announcement notice({bool enabled = true, bool dismissible = true}) =>
        Announcement.fromJson({
          'enabled': enabled,
          'id': 'vap-2026',
          'from': from.toIso8601String(),
          'until': until.toIso8601String(),
          'dismissible': dismissible,
          'link': null,
          'title': msg,
          'body': msg,
        })!;

    test('shows inside the window and not outside it', () {
      final n = notice();
      expect(n.isLiveAt(from.subtract(const Duration(minutes: 1))), isFalse);
      expect(n.isLiveAt(from), isTrue, reason: 'shown from the first moment');
      expect(n.isLiveAt(until.subtract(const Duration(minutes: 1))), isTrue);
      expect(n.isLiveAt(until), isFalse, reason: 'gone at until, not after it');
    });

    test('stays dismissed by id, not by text', () {
      // Editing the words of a dismissed notice must not resurface it; the
      // panel changes the id for that.
      final n = notice();
      final inside = from.add(const Duration(days: 1));
      expect(n.isLiveAt(inside, dismissedId: 'vap-2026'), isFalse);
      expect(n.isLiveAt(inside, dismissedId: 'vap-2026-v2'), isTrue);
    });

    test('a notice that cannot be dismissed ignores a dismissal', () {
      expect(
        notice(dismissible: false).isLiveAt(from, dismissedId: 'vap-2026'),
        isTrue,
      );
    });

    test('disabled is never live', () {
      expect(notice(enabled: false).isLiveAt(from), isFalse);
    });

    test(
      'without the pieces that decide whether it shows there is no notice',
      () {
        expect(
          Announcement.fromJson({'enabled': true, 'id': 'x', 'title': msg}),
          isNull,
        );
        expect(
          Announcement.fromJson({
            'enabled': true,
            'from': from.toIso8601String(),
            'until': until.toIso8601String(),
            'title': msg,
            'body': msg,
          }),
          isNull,
          reason: 'no id',
        );
      },
    );
  });

  group('parsing is forgiving', () {
    test('an empty document is the compiled-in default', () {
      final c = AppConfig.fromJson({});
      expect(c.gateFor(Flavor.prod).verdictFor(1), GateVerdict.current);
      expect(c.announcement, isNull);
      expect(c.switches.adsEnabled, isTrue);
      expect(c.contentVersion, 0);
    });

    test('a switch the document forgets stays on', () {
      // Off is a decision; silence is not. Only an explicit false switches off.
      final s = Switches.fromJson({'adsEnabled': false});
      expect(s.adsEnabled, isFalse);
      expect(s.purchasesEnabled, isTrue);
      expect(s.googleSignInEnabled, isTrue);
      // The absent key is the case that tells "!= false" from "== true":
      // an empty switches object must leave everything on.
      expect(Switches.fromJson({}).adsEnabled, isTrue);
    });

    test('a flavour the document does not mention has no gate', () {
      final c = AppConfig.fromJson({
        'versions': {
          'prod': {'minimumBuild': 99},
        },
      });
      expect(c.gateFor(Flavor.prod).verdictFor(1), GateVerdict.blocked);
      expect(c.gateFor(Flavor.dev).verdictFor(1), GateVerdict.current);
    });

    test('fields a newer panel adds are ignored, not fatal', () {
      final c = AppConfig.fromJson({
        'schema': 2,
        'somethingNew': {
          'deep': [1, 2],
        },
        'switches': {'adsEnabled': true, 'futureSwitch': false},
      });
      expect(c.switches.adsEnabled, isTrue);
    });

    test('survives a round trip through the cache', () {
      final original = AppConfig.fromJson({
        'publishedAt': '2026-10-07T18:57:05.878Z',
        'versions': {
          'prod': {
            'minimumBuild': 10001006,
            'latestBuild': 10001008,
            'storeUrl': 'https://play.google.com/x',
            'message': msg,
          },
        },
        'announcement': {
          'enabled': true,
          'id': 'a',
          'from': '2026-10-20T00:00:00Z',
          'until': '2026-10-26T00:00:00Z',
          'dismissible': false,
          'link': 'https://helocode.top',
          'title': msg,
          'body': msg,
        },
        'switches': {
          'adsEnabled': false,
          'purchasesEnabled': true,
          'googleSignInEnabled': true,
        },
        'content': {'latest': 7},
      });
      final again = AppConfig.fromJson(original.toJson());
      expect(again.toJson(), original.toJson());
      expect(
        again.gateFor(Flavor.prod).verdictFor(10001005),
        GateVerdict.blocked,
      );
      expect(again.announcement!.link.toString(), 'https://helocode.top');
      expect(again.switches.adsEnabled, isFalse);
      expect(again.contentVersion, 7);
    });
  });

  group('localised copy', () {
    test('reads in the reader\'s language and falls back to English', () {
      final l = Localised.fromJson({
        'en': 'Hello',
        'si': 'ආයුබෝවන්',
        'ta': ' ',
      });
      expect(l.of(AppLocale.si), 'ආයුබෝවන්');
      expect(l.of(AppLocale.ta), 'Hello', reason: 'blank Tamil falls back');
      expect(l.of(AppLocale.en), 'Hello');
    });
  });
}
