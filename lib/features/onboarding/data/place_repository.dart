import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/birth_profile.dart';

/// Offline birth-place lookup.
///
/// Bundled as an asset rather than fetched: onboarding must complete with no
/// network at all, and a geocoding API would also mean sending a birth place to
/// a third party, which the privacy policy promises we do not do.
class PlaceRepository {
  PlaceRepository(this._bundle);

  final AssetBundle _bundle;
  List<Place>? _cache;

  Future<List<Place>> all() async {
    if (_cache != null) return _cache!;
    final raw = await _bundle.loadString('assets/data/sl_places.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _cache = (json['places'] as List)
        .map((e) => Place.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cache!;
  }

  /// Matches across English, Sinhala, Tamil and district.
  ///
  /// Prefix matches sort first so typing a city name surfaces the city itself
  /// above places that merely contain the term.
  Future<List<Place>> search(String query) async {
    final places = await all();
    final trimmed = query.trim();
    final q = trimmed.toLowerCase();
    if (q.isEmpty) return places;

    bool startsWith(Place p) =>
        p.en.toLowerCase().startsWith(q) ||
        p.si.startsWith(trimmed) ||
        p.ta.startsWith(trimmed);

    final matches = places.where((p) => p.searchable.contains(q)).toList();
    matches.sort((a, b) {
      final aStarts = startsWith(a);
      final bStarts = startsWith(b);
      if (aStarts != bStarts) return aStarts ? -1 : 1;
      return a.en.compareTo(b.en);
    });
    return matches;
  }
}

final placeRepositoryProvider = Provider<PlaceRepository>(
  (ref) => PlaceRepository(rootBundle),
);

final placeSearchProvider = FutureProvider.family<List<Place>, String>(
  (ref, query) => ref.watch(placeRepositoryProvider).search(query),
);
