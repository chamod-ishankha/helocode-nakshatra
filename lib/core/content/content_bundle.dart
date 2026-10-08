import '../../features/horoscope/domain/fragment.dart';
import '../astro/published_calendar.dart';

/// A published content version, `content/{version}` (KAN-49 FRD §5.4).
///
/// Holds the horoscope copy in all three languages, and the calendar when
/// the panel has one. A bundle without a calendar means "keep the calendar
/// this build shipped with".
class ContentBundle {
  const ContentBundle({
    required this.version,
    required this.fragments,
    this.publishedAt,
    this.calendar,
  });

  final int version;
  final DateTime? publishedAt;

  /// By language code: `en`, `si`, `ta`.
  final Map<String, List<Fragment>> fragments;

  /// Gazetted poya days and announced festivals, or null to use the bundled
  /// calendar.
  final PublishedCalendar? calendar;

  static const languages = ['en', 'si', 'ta'];

  /// The copy for [language], or null when this bundle has none for it.
  List<Fragment>? fragmentsFor(String language) => fragments[language];

  /// Parses and checks a bundle as strictly as the app's own content tests
  /// check the bundled files.
  ///
  /// Throws [FormatException] on anything those tests would fail. A bundle
  /// that parses but disagrees with itself — a Sinhala line with different
  /// conditions from its English one — would make two readers on the same
  /// day get different predictions, so it is refused whole rather than
  /// patched line by line. The bundled copy stays in force instead.
  factory ContentBundle.fromJson(Map<String, dynamic> json) {
    final version = json['version'];
    if (version is! int || version <= 0) {
      throw FormatException('Content bundle has no version: $version');
    }

    final raw = json['fragments'];
    if (raw is! Map) {
      throw const FormatException('Content bundle has no fragments');
    }

    final parsed = <String, List<Fragment>>{};
    for (final lang in languages) {
      final list = raw[lang];
      if (list is! List || list.isEmpty) {
        throw FormatException('Content bundle has no $lang copy');
      }
      final fragments = [
        for (final f in list)
          Fragment.fromJson(Map<String, dynamic>.from(f as Map)),
      ];
      final ids = fragments.map((f) => f.id).toSet();
      if (ids.length != fragments.length) {
        throw FormatException('Content bundle repeats an id in $lang');
      }
      parsed[lang] = fragments;
    }

    final en = {for (final f in parsed['en']!) f.id: f};
    for (final lang in ['si', 'ta']) {
      final other = parsed[lang]!;
      if (other.length != en.length) {
        throw FormatException(
          'Content bundle $lang has a different set of lines',
        );
      }
      for (final f in other) {
        final reference = en[f.id];
        if (reference == null ||
            reference.category != f.category ||
            !_sameSet(reference.requires, f.requires) ||
            !_sameSet(reference.excludes, f.excludes)) {
          throw FormatException(
            'Content bundle $lang disagrees with en on ${f.id}',
          );
        }
      }
    }

    // A category with no lines would silently drop a section from every
    // reading.
    for (final c in HoroscopeCategory.values) {
      if (!en.values.any((f) => f.category == c)) {
        throw FormatException('Content bundle has no ${c.name} lines');
      }
    }

    // A wrong religious date is worse than none: a calendar that fails its
    // checks takes the whole bundle down with it, copy included, and the
    // phone keeps what it had.
    final hasCalendar = json['poyaDays'] != null || json['festivals'] != null;
    final calendar = hasCalendar
        ? PublishedCalendar.fromJson(json['poyaDays'], json['festivals'])
        : null;

    final stamp = json['publishedAt'];
    return ContentBundle(
      version: version,
      publishedAt: stamp is String ? DateTime.tryParse(stamp) : null,
      fragments: parsed,
      calendar: calendar,
    );
  }

  static bool _sameSet(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);
}
