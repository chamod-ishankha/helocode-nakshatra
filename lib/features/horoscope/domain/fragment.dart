/// The sections a daily reading is built from (KAN-31).
enum HoroscopeCategory {
  general,
  career,
  money,
  love,
  health,
  advice;

  static HoroscopeCategory? byName(String name) {
    for (final c in HoroscopeCategory.values) {
      if (c.name == name) return c;
    }
    return null;
  }
}

/// One authored sentence, and the sky it belongs to.
///
/// Fragments are data, not code: KAN-32 authors hundreds of these in three
/// languages, and nobody should need to touch Dart to add one.
class Fragment {
  const Fragment({
    required this.id,
    required this.category,
    required this.text,
    this.requires = const {},
    this.excludes = const {},
  });

  /// Stable across languages: the same id in the Sinhala and Tamil files is
  /// the same sentence, so a reader who switches language mid-day sees a
  /// translation rather than a different prediction.
  final String id;

  final HoroscopeCategory category;
  final String text;

  /// Every tag here must be present for this fragment to be eligible.
  ///
  /// Empty means "always eligible" — the filler that keeps a category from
  /// coming up empty on an unremarkable day.
  final Set<String> requires;

  /// Any tag here disqualifies the fragment.
  ///
  /// Needed because requiring the absence of something is otherwise
  /// impossible: cheerful money copy must not appear during sade sati even
  /// though nothing about the money tags rules it out.
  final Set<String> excludes;

  bool matches(Set<String> tags) =>
      requires.every(tags.contains) && !excludes.any(tags.contains);

  /// How specific this fragment is. Used to prefer copy that was written for
  /// today over copy that fits any day.
  int get specificity => requires.length;

  factory Fragment.fromJson(Map<String, dynamic> json) {
    final categoryName = json['category'] as String?;
    final category = categoryName == null
        ? null
        : HoroscopeCategory.byName(categoryName);
    if (category == null) {
      throw FormatException('Unknown horoscope category: $categoryName');
    }

    final id = json['id'] as String?;
    if (id == null || id.isEmpty) {
      throw const FormatException('Fragment is missing an id');
    }

    final text = json['text'] as String?;
    if (text == null || text.trim().isEmpty) {
      throw FormatException('Fragment $id has no text');
    }

    return Fragment(
      id: id,
      category: category,
      text: text.trim(),
      requires: _tags(json['requires']),
      excludes: _tags(json['excludes']),
    );
  }

  static Set<String> _tags(Object? raw) {
    if (raw == null) return const {};
    return {for (final t in raw as List) (t as String).trim()};
  }

  @override
  String toString() => '$id (${category.name})';
}
