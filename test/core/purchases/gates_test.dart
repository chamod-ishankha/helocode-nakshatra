import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/purchases/entitlements.dart';
import 'package:nakshatra/core/purchases/products.dart';

/// Nothing may be sold that nothing gates (KAN-36).
///
/// ## Why this reads the source
///
/// The bug it exists to prevent is invisible to every ordinary test. The
/// paywall listed six Pro benefits; four of them were gated by no code
/// anywhere, so a user could pay for "the full daśā timeline" and get exactly
/// what they already had. Each piece compiled, every unit test passed, and the
/// only symptom was a promise the app did not keep.
///
/// There is no runtime handle on "is this feature gated" — a gate is a call
/// site, not a value — so this walks lib/ and looks for one. Crude, but it
/// fails the moment somebody adds a [PaidFeature] and forgets to check it,
/// which is exactly when it needs to.
void main() {
  /// Every .dart file under lib/, with comments stripped.
  ///
  /// Comments have to go: [PaidFeature.compatibilityReport] is named in a doc
  /// comment explaining that nothing gates it, and counting that as a gate
  /// would make this test pass on its own documentation.
  late String code;

  setUpAll(() {
    final buffer = StringBuffer();

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;

      // The enum's own declaration is not a use of it.
      if (entity.path.endsWith('entitlements.dart')) continue;

      for (final line in entity.readAsLinesSync()) {
        final stripped = line.replaceFirst(RegExp(r'//.*'), '');
        buffer.writeln(stripped);
      }
    }

    code = buffer.toString();
  });

  /// The features a user can actually hand over money for today.
  final sold = <PaidFeature>{
    for (final product in PurchaseProduct.onSale) ...product.unlocks,
  };

  test('every feature on sale is checked somewhere in the app', () {
    final ungated = <PaidFeature>[];

    for (final feature in sold) {
      if (!code.contains('PaidFeature.${feature.name}')) {
        ungated.add(feature);
      }
    }

    expect(
      ungated,
      isEmpty,
      reason:
          'These are sold but nothing reads them, so buying changes nothing: '
          '${ungated.map((f) => f.name).join(', ')}. Either gate the feature '
          'or take it off the paywall.',
    );
  });

  test('every feature in the table is on sale', () {
    // The other direction, and the cheaper mistake: a gate with no product
    // behind it locks a screen that can never be opened. It is worth catching
    // because the symptom — a permanent lock — looks like a broken purchase
    // rather than like missing configuration.
    final unreachable = PaidFeature.values.toSet().difference(sold);

    expect(
      unreachable.map((f) => f.name),
      // compatibility_report is configured in Play and RevenueCat but is
      // deliberately not sellable until the screen it opens exists, so the
      // feature it grants is knowingly out of reach.
      unorderedEquals(['compatibilityReport']),
    );
  });

  test('the paywall names as many benefits as the app gates', () {
    // Six bullets over four gates is how the original mis-sale looked from
    // the outside. This does not check the words — it checks that nobody adds
    // a seventh bullet without adding the gate that makes it true.
    final bullets = File(
      'lib/features/purchases/presentation/paywall.dart',
    ).readAsStringSync();

    final listed = RegExp(
      r'l\.paywallFeature[A-Za-z]+',
    ).allMatches(bullets).map((m) => m.group(0)).toSet();

    expect(
      listed.length,
      lessThanOrEqualTo(sold.length),
      reason:
          'The paywall lists ${listed.length} benefits — $listed — but only '
          '${sold.length} features are gated and on sale.',
    );
  });
}
