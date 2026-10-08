import 'calendar_models.dart';

/// The calendar published from the admin panel with a content bundle
/// (KAN-49 FRD §4.5, §8.5).
///
/// Holds only what the app cannot compute: the gazetted day and name of each
/// poya, and the holidays whose dates are announced rather than calculated.
class PublishedCalendar {
  const PublishedCalendar({required this.poyaDays, required this.festivals});

  /// Keyed `YYYY-MM-DD`, the same shape as `officialPoyaDays`.
  final Map<String, ({PoyaMonth month, bool isAdhi})> poyaDays;

  final List<AnnouncedFestival> festivals;

  /// Years the published table covers. Within them it is the whole truth: a
  /// poya moved or removed in the panel must not survive from the bundled
  /// table underneath.
  Set<int> get poyaYears => {
    for (final k in poyaDays.keys) int.parse(k.substring(0, 4)),
  };

  /// Parses and checks the calendar part of a bundle.
  ///
  /// Throws [FormatException] on anything the panel would have refused, so a
  /// table edited by some other route cannot put a wrong religious date on a
  /// phone.
  factory PublishedCalendar.fromJson(Object? poyaRaw, Object? festivalsRaw) {
    final poya = <String, ({PoyaMonth month, bool isAdhi})>{};
    if (poyaRaw != null) {
      if (poyaRaw is! Map) throw const FormatException('poyaDays is not a map');
      for (final e in poyaRaw.entries) {
        final key = e.key as String;
        _date(key);
        final v = e.value;
        if (v is! Map) throw FormatException('poya $key is not an object');
        final month = PoyaMonth.values
            .where((m) => m.name == v['month'])
            .firstOrNull;
        if (month == null) {
          throw FormatException('poya $key has month ${v['month']}');
        }
        poya[key] = (month: month, isAdhi: v['isAdhi'] == true);
      }
      checkPoyaSequence(poya);
    }

    final festivals = <AnnouncedFestival>[];
    if (festivalsRaw != null) {
      if (festivalsRaw is! List) {
        throw const FormatException('festivals is not a list');
      }
      for (final f in festivalsRaw) {
        festivals.add(
          AnnouncedFestival.fromJson(Map<String, dynamic>.from(f as Map)),
        );
      }
    }
    return PublishedCalendar(poyaDays: poya, festivals: festivals);
  }

  /// The checks the app's own table is held to (poya_rule_test.dart), and the
  /// panel applies before a save: consecutive poyas a whole number of lunar
  /// months apart, 28–31 days for each, with an Adhi month counted as one and
  /// followed by its own regular month.
  static void checkPoyaSequence(
    Map<String, ({PoyaMonth month, bool isAdhi})> table,
  ) {
    final keys = table.keys.toList()..sort();
    for (var i = 1; i < keys.length; i++) {
      final a = table[keys[i - 1]]!, b = table[keys[i]]!;
      final days = _date(keys[i]).difference(_date(keys[i - 1])).inDays;
      if (days > 125) continue; // a year not gazetted; a separate run
      final months = monthsBetween(a, b);
      if (months == 0 || days < 28 * months || days > 31 * months) {
        throw FormatException(
          'poya ${keys[i]} is $days days after ${keys[i - 1]}',
        );
      }
    }
  }

  /// Lunar months from [a] to [b]. An Adhi month sits half a step before its
  /// regular month, so Vesak → Adhi Poson → Poson is one month each.
  static int monthsBetween(
    ({PoyaMonth month, bool isAdhi}) a,
    ({PoyaMonth month, bool isAdhi}) b,
  ) {
    double position(({PoyaMonth month, bool isAdhi}) p) =>
        p.month.index - (p.isAdhi ? 0.5 : 0);
    final diff = ((position(b) - position(a)) % 12 + 12) % 12;
    return diff.ceil();
  }

  /// The published poya table laid over the bundled one, year by year.
  Map<String, ({PoyaMonth month, bool isAdhi})> over(
    Map<String, ({PoyaMonth month, bool isAdhi})> bundled,
  ) {
    final years = poyaYears;
    return {
      for (final e in bundled.entries)
        if (!years.contains(int.parse(e.key.substring(0, 4)))) e.key: e.value,
      ...poyaDays,
    };
  }

  List<AnnouncedFestival> festivalsIn(int year) => [
    for (final f in festivals)
      if (f.date.year == year) f,
  ];

  static DateTime _date(String key) {
    final d = DateTime.tryParse(key);
    final ok =
        d != null &&
        RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(key) &&
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}' ==
            key;
    if (!ok) throw FormatException('$key is not a date');
    return DateTime(d.year, d.month, d.day);
  }
}

/// A holiday whose date was announced, with where it was announced.
class AnnouncedFestival {
  const AnnouncedFestival({
    required this.date,
    required this.en,
    required this.si,
    required this.ta,
    required this.source,
    this.note,
  });

  final DateTime date;
  final String en;
  final String si;
  final String ta;
  final String source;
  final String? note;

  factory AnnouncedFestival.fromJson(Map<String, dynamic> json) {
    final date = PublishedCalendar._date(json['date'] as String? ?? '');
    final name = json['name'];
    String part(String lang) {
      final v = name is Map ? name[lang] : null;
      if (v is! String || v.trim().isEmpty) {
        throw FormatException('festival on $date has no $lang name');
      }
      return v.trim();
    }

    final source = json['source'];
    if (source is! String || source.trim().isEmpty) {
      throw FormatException('festival on $date has no source');
    }
    final note = json['note'];
    return AnnouncedFestival(
      date: date,
      en: part('en'),
      si: part('si'),
      ta: part('ta'),
      source: source.trim(),
      note: note is String && note.trim().isNotEmpty ? note.trim() : null,
    );
  }

  Festival toFestival() => Festival(
    date: date,
    name: en,
    si: si,
    ta: ta,
    kind: FestivalKind.announced,
    note: note ?? 'Announced: $source',
  );
}
