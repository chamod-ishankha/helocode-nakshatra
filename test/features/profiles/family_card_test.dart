import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/features/profiles/presentation/add_family_member.dart';

/// When Home offers "Add a family member" (KAN-74).
///
/// The rule is small and every branch of it matters: a card that shows with
/// no database leads to a switcher that cannot switch, and a card that shows
/// in a build that cannot sell leads to a paywall with nothing on it.
void main() {
  group('the family card on Home', () {
    test('shows for one saved chart when Pro can be bought', () {
      expect(
        showFamilyCard(savedCharts: 1, ownsFeature: false, canBuy: true),
        isTrue,
      );
    });

    test('shows for a Pro holder with one chart, who goes straight in', () {
      // A build that cannot reach the store still lets somebody who already
      // owns the feature use it.
      expect(
        showFamilyCard(savedCharts: 1, ownsFeature: true, canBuy: false),
        isTrue,
      );
    });

    test('hides when there is no way through it', () {
      // Nothing owned, nothing sellable: the tap would open an empty paywall.
      expect(
        showFamilyCard(savedCharts: 1, ownsFeature: false, canBuy: false),
        isFalse,
      );
    });

    test('hides with no saved charts, where a second cannot be kept', () {
      // A build with no database reports zero saved charts and holds its one
      // profile in preferences — adding would have nowhere to go.
      for (final owns in [true, false]) {
        for (final canBuy in [true, false]) {
          expect(
            showFamilyCard(savedCharts: 0, ownsFeature: owns, canBuy: canBuy),
            isFalse,
          );
        }
      }
    });

    test('hides once the family is already there', () {
      // Home is the daily screen. Somebody using the feature does not need it
      // advertised to them every morning.
      for (final charts in [2, 3, 10]) {
        expect(
          showFamilyCard(savedCharts: charts, ownsFeature: true, canBuy: true),
          isFalse,
        );
      }
    });
  });
}
