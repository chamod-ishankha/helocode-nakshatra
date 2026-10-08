import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Where banners may go (KAN-34, KAN-76).
///
/// A banner beside something a user taps is how an AdMob account gets banned
/// for accidental clicks, and that ban is account-wide and, in practice, not
/// appealed. The screens that carry banners compute their content with the
/// ephemeris, which does not run under `flutter test`, so this reads the
/// source instead of pumping the screens — the same approach as gates_test.
///
/// The rule it holds every screen to: a banner is the last thing on the page,
/// after the "for entertainment purposes only" line, with no tappable control
/// between that line and the ad.
void main() {
  final placements = <String, String>{};

  setUpAll(() {
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (path.endsWith('core/ads/banner_ad_slot.dart')) continue;

      final source = entity.readAsStringSync();
      if (source.contains('BannerAdSlot()')) placements[path] = source;
    }
  });

  test('banners are on exactly the screens that were decided on', () {
    // A new placement is a decision to measure, not a line to paste. KAN-76
    // added one and said "one placement, measured, before the next" — this
    // makes the next one a deliberate change to this list.
    expect(placements.keys.toSet(), {
      'lib/features/home/presentation/home_screen.dart',
      'lib/features/compatibility/presentation/compatibility_screen.dart',
    });
  });

  test('each screen carries one banner, not several', () {
    for (final MapEntry(key: path, value: source) in placements.entries) {
      expect('BannerAdSlot()'.allMatches(source), hasLength(1), reason: path);
    }
  });

  test('every banner follows the disclaimer that closes the page', () {
    for (final MapEntry(key: path, value: source) in placements.entries) {
      final banner = source.indexOf('BannerAdSlot()');
      final disclaimer = source.lastIndexOf('const Disclaimer()', banner);

      expect(
        disclaimer,
        greaterThanOrEqualTo(0),
        reason: '$path: the banner comes before the disclaimer',
      );
    }
  });

  test('nothing tappable sits between the disclaimer and the banner', () {
    // The gap is the whole point. A button slipped in here would put a
    // control directly above the ad.
    const tappable = [
      'onTap',
      'onPressed',
      'Button(',
      'InkWell',
      'GestureDetector',
      'ListTile(',
    ];

    for (final MapEntry(key: path, value: source) in placements.entries) {
      final banner = source.indexOf('BannerAdSlot()');
      final disclaimer = source.lastIndexOf('const Disclaimer()', banner);
      final between = source.substring(disclaimer, banner);

      for (final control in tappable) {
        expect(
          between.contains(control),
          isFalse,
          reason: '$path: "$control" between the disclaimer and the banner',
        );
      }
    }
  });

  test('the compatibility banner waits for a result', () {
    // Before there is a match the screen is a form, and an ad at its foot
    // sits one thumb-length from the button that fills it in.
    final source =
        placements['lib/features/compatibility/presentation/compatibility_screen.dart']!;
    final line = source
        .split('\n')
        .firstWhere((l) => l.contains('BannerAdSlot()'));

    expect(line, contains('if (match != null)'));
  });
}
