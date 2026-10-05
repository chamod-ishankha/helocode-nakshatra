import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/features/onboarding/data/place_repository.dart';

/// Which country the place picker starts on, and where Sri Lanka sits in it.
void main() {
  const countries = [
    Country(code: 'IN', en: 'India', placeCount: 10),
    Country(code: 'LK', en: 'Sri Lanka', placeCount: 10),
    Country(code: 'US', en: 'United States', placeCount: 10),
  ];

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [countryListProvider.overrideWith((_) async => countries)],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('opens on Sri Lanka, whatever the phone region', () async {
    // It followed the region, and Sri Lankan phones are very often set to
    // the US: the first place search was scoped to America.
    final c = container();
    await c.read(countryListProvider.future);
    expect(c.read(effectiveCountryProvider).value, 'LK');
  });

  test('keeps the country the reader picks', () async {
    final c = container();
    await c.read(countryListProvider.future);
    c.read(pickerCountryProvider.notifier).select('IN');
    expect(c.read(effectiveCountryProvider).value, 'IN');
  });

  test('lists Sri Lanka first and leaves the rest in order', () {
    expect(homeCountryFirst(countries).map((c) => c.code), ['LK', 'IN', 'US']);
  });

  test('drops nothing when Sri Lanka is missing', () {
    final rest = countries.where((c) => c.code != 'LK').toList();
    expect(homeCountryFirst(rest).map((c) => c.code), ['IN', 'US']);
  });
}
