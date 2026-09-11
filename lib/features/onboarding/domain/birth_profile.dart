import '../../../core/config/app_locale.dart';

/// A birth place with the coordinates and timezone a chart needs.
class Place {
  const Place({
    required this.en,
    required this.latitude,
    required this.longitude,
    required this.district,
    required this.timezone,
    String? si,
    String? ta,
    String? districtSi,
    String? districtTa,
    this.countryCode,
  }) : _si = si,
       _ta = ta,
       _districtSi = districtSi,
       _districtTa = districtTa;

  final String en;
  final double latitude;
  final double longitude;

  /// The district in English, which is also its key in the data file.
  final String district;

  /// ISO 3166-1 alpha-2, or null for a profile saved before the place list
  /// went worldwide. Those are all Sri Lankan, but the null is left as null
  /// rather than backfilled to `LK` — see [Place.fromJson].
  final String? countryCode;

  /// Null wherever no translation exists, which is most of the world.
  ///
  /// Sinhala and Tamil are carried for Sri Lanka, Tamil for India, and nothing
  /// elsewhere. GeoNames has a Sinhala name for about two thirds of Sri Lankan
  /// towns and a Tamil one for a fifth of Tamil Nadu, so the gaps exist inside
  /// those two markets as well.
  ///
  /// Deliberately not filled with the English name: that would record "the
  /// Sinhala for Chennai is Chennai" as a fact, and a later release could
  /// never tell a real translation from a filled-in one.
  final String? _si;
  final String? _ta;

  /// Null only for a profile saved before the translations existed; a place
  /// coming from the bundled data always has both or neither.
  final String? _districtSi;
  final String? _districtTa;

  /// The stored translations, exactly as saved — null included.
  ///
  /// [label] falls back to English, which is right on screen and wrong when
  /// persisting, for the reason on [_si].
  String? get siOrNull => _si;
  String? get taOrNull => _ta;
  String? get districtSiOrNull => _districtSi;
  String? get districtTaOrNull => _districtTa;

  /// IANA zone. Required, with no default.
  ///
  /// This used to default to `Asia/Colombo`, which was correct while every
  /// place in the app was Sri Lankan and catastrophic the moment one was not:
  /// a wrong zone moves the chart by hours, which moves the lagna by whole
  /// signs, and nothing on screen says so. Callers must now say which zone
  /// they mean, so the compiler catches anyone who does not know.
  final String timezone;

  /// The place name in the reader's language, falling back to English.
  String label(AppLocale locale) => switch (locale) {
    AppLocale.si => _si ?? en,
    AppLocale.ta => _ta ?? en,
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

  /// Text matched by place search. Includes every script the place has, so a
  /// user typing Sinhala finds the same row as one typing English.
  String get searchable =>
      '$en ${_si ?? ''} ${_ta ?? ''} $district '
              '${_districtSi ?? ''} ${_districtTa ?? ''}'
          .toLowerCase();

  factory Place.fromJson(Map<String, dynamic> json) => Place(
    en: json['en'] as String,
    si: json['si'] as String?,
    ta: json['ta'] as String?,
    latitude: (json['lat'] as num).toDouble(),
    longitude: (json['lon'] as num).toDouble(),
    district: json['district'] as String,
    districtSi: json['districtSi'] as String?,
    districtTa: json['districtTa'] as String?,
    countryCode: json['cc'] as String?,
    // Absent only in a profile written before this field was read back, and
    // every place that existed then was Sri Lankan. Reading it is the whole
    // point: the old code wrote this key and never read it, so the zone was
    // silently reset to Colombo on every restart and every sync (KAN-67).
    timezone: json['timezone'] as String? ?? 'Asia/Colombo',
  );

  Map<String, dynamic> toJson() => {
    'en': en,
    if (_si != null) 'si': _si,
    if (_ta != null) 'ta': _ta,
    'lat': latitude,
    'lon': longitude,
    'district': district,
    if (_districtSi != null) 'districtSi': _districtSi,
    if (_districtTa != null) 'districtTa': _districtTa,
    if (countryCode != null) 'cc': countryCode,
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
