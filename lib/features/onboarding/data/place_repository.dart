import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/birth_profile.dart';

/// One country in the picker.
class Country {
  const Country({
    required this.code,
    required this.en,
    required this.placeCount,
    String? si,
    String? ta,
  }) : _si = si,
       _ta = ta;

  final String code;
  final String en;
  final int placeCount;

  /// Only Sri Lanka and India carry these. Every other country shows in
  /// English, which is what a country list normally does.
  final String? _si;
  final String? _ta;

  String label(bool sinhala, bool tamil) {
    if (sinhala && _si != null) return _si;
    if (tamil && _ta != null) return _ta;
    return en;
  }

  /// Matched by the country search box, across whatever scripts it has.
  String get searchable => '$code $en ${_si ?? ''} ${_ta ?? ''}'.toLowerCase();

  factory Country.fromJson(Map<String, dynamic> json) => Country(
    code: json['cc'] as String,
    en: json['en'] as String,
    si: json['si'] as String?,
    ta: json['ta'] as String?,
    placeCount: json['n'] as int,
  );
}

/// Offline birth-place lookup, one country at a time.
///
/// Bundled as an asset rather than fetched: onboarding must complete with no
/// network at all, and a geocoding API would also mean sending a birth place to
/// a third party, which the privacy policy promises we do not do.
///
/// Split per country rather than kept in one file because the picker chooses a
/// country before it searches, so only that country is ever decoded. The whole
/// world is 34,000 places; parsing all of them to show one country's worth
/// would cost a cheap phone a visible pause during onboarding.
///
/// Data from GeoNames under CC BY 4.0, merged with the hand-checked Sri Lankan
/// list. See `assets/data/places/README.md`.
class PlaceRepository {
  PlaceRepository(this._bundle);

  final AssetBundle _bundle;

  List<Country>? _countries;
  final Map<String, List<Place>> _places = {};

  static const String _dir = 'assets/data/places';

  Future<List<Country>> countries() async {
    if (_countries != null) return _countries!;
    final raw = await _bundle.loadString('$_dir/index.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return _countries = (json['countries'] as List)
        .map((e) => Country.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// How many countries stay decoded at once.
  ///
  /// Caching matters — someone entering two birth places flips between
  /// countries, and re-decoding India each time would be felt. Caching
  /// *everything* is the other failure: India alone is 3,779 `Place` objects,
  /// and a user browsing the picker could pin most of the world in memory on a
  /// phone that has little. Three covers the real pattern (their country,
  /// their partner's, and the one they just looked at) and bounds the rest.
  static const int _maxCachedCountries = 3;

  /// Every place in one country.
  Future<List<Place>> inCountry(String code) async {
    final cached = _places[code];
    if (cached != null) {
      // Re-insert so the most recently used country is last out.
      _places.remove(code);
      return _places[code] = cached;
    }

    final raw = await _bundle.loadString('$_dir/$code.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    // The country code is written once at the top of the file rather than
    // repeated on all 3,779 Indian rows, and stamped onto each place here.
    final places = (json['places'] as List)
        .map(
          (e) => Place.fromJson({...e as Map<String, dynamic>, 'cc': code}),
        )
        .toList(growable: false);

    // Dart maps iterate in insertion order, so the first key is the least
    // recently used.
    while (_places.length >= _maxCachedCountries) {
      _places.remove(_places.keys.first);
    }
    return _places[code] = places;
  }

  /// Matches across English, Sinhala, Tamil and district, within one country.
  ///
  /// Prefix matches sort first so typing a city name surfaces the city itself
  /// above places that merely contain the term; ties break alphabetically.
  Future<List<Place>> search(String countryCode, String query) async {
    final places = await inCountry(countryCode);
    final trimmed = query.trim();
    final q = trimmed.toLowerCase();
    if (q.isEmpty) return places;

    bool startsWith(Place p) =>
        p.en.toLowerCase().startsWith(q) ||
        (p.siOrNull?.startsWith(trimmed) ?? false) ||
        (p.taOrNull?.startsWith(trimmed) ?? false);

    final matches = places.where((p) => p.searchable.contains(q)).toList();
    matches.sort((a, b) {
      final aStarts = startsWith(a);
      final bStarts = startsWith(b);
      if (aStarts != bStarts) return aStarts ? -1 : 1;
      return _byName(a, b);
    });
    return matches;
  }

  static int _byName(Place a, Place b) => a.en.compareTo(b.en);
}

final placeRepositoryProvider = Provider<PlaceRepository>(
  (ref) => PlaceRepository(rootBundle),
);

final countryListProvider = FutureProvider<List<Country>>(
  (ref) => ref.watch(placeRepositoryProvider).countries(),
);

/// The country the user has picked, or null while they have not picked one.
class PickerCountry extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String code) => state = code;
}

final pickerCountryProvider = NotifierProvider<PickerCountry, String?>(
  PickerCountry.new,
);

/// Which country the place picker is showing.
///
/// Defaults to the device's region, because the overwhelmingly common case is
/// being born in the country the phone is set up for. Falls back to `LK` when
/// the device region is missing, or names a country the data has no cities for
/// — `PlaceRepository.inCountry` would throw on a missing asset, and a region
/// like `AQ` or a bare `419` must not turn the first screen of the app into a
/// load failure. This is a Sri Lankan app first, and a wrong guess costs one
/// tap.
final effectiveCountryProvider = Provider<AsyncValue<String>>((ref) {
  final chosen = ref.watch(pickerCountryProvider);
  return ref.watch(countryListProvider).whenData((countries) {
    if (chosen != null) return chosen;
    final region = ui.PlatformDispatcher.instance.locale.countryCode;
    final known = countries.any((c) => c.code == region);
    return known ? region! : 'LK';
  });
});

/// A place search, scoped to a country.
typedef PlaceQuery = ({String countryCode, String query});

final placeSearchProvider = FutureProvider.family<List<Place>, PlaceQuery>(
  (ref, q) =>
      ref.watch(placeRepositoryProvider).search(q.countryCode, q.query),
);
