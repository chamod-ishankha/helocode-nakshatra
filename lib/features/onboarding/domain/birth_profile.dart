import '../../../core/config/app_locale.dart';

/// A birth place with the coordinates and timezone a chart needs.
class Place {
  const Place({
    required this.en,
    required this.si,
    required this.ta,
    required this.latitude,
    required this.longitude,
    required this.district,
    String? districtSi,
    String? districtTa,
    this.timezone = 'Asia/Colombo',
  }) : _districtSi = districtSi,
       _districtTa = districtTa;

  final String en;
  final String si;
  final String ta;
  final double latitude;
  final double longitude;

  /// The district in English, which is also its key in the data file.
  final String district;

  /// Null only for a profile saved before the translations existed; a place
  /// coming from `sl_places.json` always has both.
  final String? _districtSi;
  final String? _districtTa;

  /// IANA zone, which carries Sri Lanka's 1996-2006 offset changes. A fixed
  /// offset would silently corrupt every chart from that decade.
  final String timezone;

  String label(AppLocale locale) => switch (locale) {
    AppLocale.si => si,
    AppLocale.ta => ta,
    AppLocale.en => en,
  };

  /// The district in the reader's language.
  ///
  /// Falls back to English rather than to nothing: a profile stored by an
  /// older build has no translation, and an empty subtitle under a place is
  /// worse than an English one.
  String districtLabel(AppLocale locale) => switch (locale) {
    AppLocale.si => _districtSi ?? district,
    AppLocale.ta => _districtTa ?? district,
    AppLocale.en => district,
  };

  /// Text matched by place search. Includes all three scripts so a user typing
  /// Sinhala finds the same row as one typing English.
  String get searchable =>
      '$en $si $ta $district ${_districtSi ?? ''} ${_districtTa ?? ''}'
          .toLowerCase();

  factory Place.fromJson(Map<String, dynamic> json) => Place(
    en: json['en'] as String,
    si: json['si'] as String,
    ta: json['ta'] as String,
    latitude: (json['lat'] as num).toDouble(),
    longitude: (json['lon'] as num).toDouble(),
    district: json['district'] as String,
    districtSi: json['districtSi'] as String?,
    districtTa: json['districtTa'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'en': en,
    'si': si,
    'ta': ta,
    'lat': latitude,
    'lon': longitude,
    'district': district,
    if (_districtSi != null) 'districtSi': _districtSi,
    if (_districtTa != null) 'districtTa': _districtTa,
    'timezone': timezone,
  };
}

/// Everything needed to compute a chart, plus who it belongs to.
class BirthProfile {
  const BirthProfile({
    required this.name,
    required this.birthDate,
    required this.birthTime,
    required this.place,
    required this.birthTimeKnown,
  });

  final String name;

  /// Calendar date of birth. Time-of-day is carried separately in
  /// [birthTime] so an unknown time stays visibly distinct from midnight.
  final DateTime birthDate;

  /// Wall-clock time in the birth place's timezone.
  final Duration birthTime;

  final Place place;

  /// False when the user did not know their birth time and we substituted a
  /// default. House placements and the ascendant are then approximate, and the
  /// UI must say so rather than presenting them as fact.
  final bool birthTimeKnown;

  /// Used when the birth time is unknown.
  ///
  /// Sunrise is the traditional fallback and roughly places the lagna on the
  /// Sun's sign. It is a convention, not a computation — the real ascendant
  /// moves through all twelve rāśi in a day, so it cannot be recovered.
  static const Duration defaultUnknownTime = Duration(hours: 6);

  /// Local wall clock, as the ephemeris expects it.
  DateTime get localWallClock => DateTime(
    birthDate.year,
    birthDate.month,
    birthDate.day,
    birthTime.inHours,
    birthTime.inMinutes % 60,
  );

  BirthProfile copyWith({
    String? name,
    DateTime? birthDate,
    Duration? birthTime,
    Place? place,
    bool? birthTimeKnown,
  }) => BirthProfile(
    name: name ?? this.name,
    birthDate: birthDate ?? this.birthDate,
    birthTime: birthTime ?? this.birthTime,
    place: place ?? this.place,
    birthTimeKnown: birthTimeKnown ?? this.birthTimeKnown,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'birthDate': birthDate.toIso8601String(),
    'birthTimeMinutes': birthTime.inMinutes,
    'place': place.toJson(),
    'birthTimeKnown': birthTimeKnown,
  };

  factory BirthProfile.fromJson(Map<String, dynamic> json) => BirthProfile(
    name: json['name'] as String,
    birthDate: DateTime.parse(json['birthDate'] as String),
    birthTime: Duration(minutes: json['birthTimeMinutes'] as int),
    place: Place.fromJson(json['place'] as Map<String, dynamic>),
    birthTimeKnown: json['birthTimeKnown'] as bool? ?? true,
  );
}
