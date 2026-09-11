// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProfilesTable extends Profiles with TableInfo<$ProfilesTable, Profile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _birthDateMeta = const VerificationMeta(
    'birthDate',
  );
  @override
  late final GeneratedColumn<DateTime> birthDate = GeneratedColumn<DateTime>(
    'birth_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _birthTimeMinutesMeta = const VerificationMeta(
    'birthTimeMinutes',
  );
  @override
  late final GeneratedColumn<int> birthTimeMinutes = GeneratedColumn<int>(
    'birth_time_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _birthTimeKnownMeta = const VerificationMeta(
    'birthTimeKnown',
  );
  @override
  late final GeneratedColumn<bool> birthTimeKnown = GeneratedColumn<bool>(
    'birth_time_known',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("birth_time_known" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _placeEnMeta = const VerificationMeta(
    'placeEn',
  );
  @override
  late final GeneratedColumn<String> placeEn = GeneratedColumn<String>(
    'place_en',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _placeSiMeta = const VerificationMeta(
    'placeSi',
  );
  @override
  late final GeneratedColumn<String> placeSi = GeneratedColumn<String>(
    'place_si',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _placeTaMeta = const VerificationMeta(
    'placeTa',
  );
  @override
  late final GeneratedColumn<String> placeTa = GeneratedColumn<String>(
    'place_ta',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _districtMeta = const VerificationMeta(
    'district',
  );
  @override
  late final GeneratedColumn<String> district = GeneratedColumn<String>(
    'district',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _districtSiMeta = const VerificationMeta(
    'districtSi',
  );
  @override
  late final GeneratedColumn<String> districtSi = GeneratedColumn<String>(
    'district_si',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _districtTaMeta = const VerificationMeta(
    'districtTa',
  );
  @override
  late final GeneratedColumn<String> districtTa = GeneratedColumn<String>(
    'district_ta',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timezoneMeta = const VerificationMeta(
    'timezone',
  );
  @override
  late final GeneratedColumn<String> timezone = GeneratedColumn<String>(
    'timezone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countryCodeMeta = const VerificationMeta(
    'countryCode',
  );
  @override
  late final GeneratedColumn<String> countryCode = GeneratedColumn<String>(
    'country_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSelectedMeta = const VerificationMeta(
    'isSelected',
  );
  @override
  late final GeneratedColumn<bool> isSelected = GeneratedColumn<bool>(
    'is_selected',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_selected" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    birthDate,
    birthTimeMinutes,
    birthTimeKnown,
    placeEn,
    placeSi,
    placeTa,
    district,
    districtSi,
    districtTa,
    latitude,
    longitude,
    timezone,
    countryCode,
    isSelected,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<Profile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('birth_date')) {
      context.handle(
        _birthDateMeta,
        birthDate.isAcceptableOrUnknown(data['birth_date']!, _birthDateMeta),
      );
    } else if (isInserting) {
      context.missing(_birthDateMeta);
    }
    if (data.containsKey('birth_time_minutes')) {
      context.handle(
        _birthTimeMinutesMeta,
        birthTimeMinutes.isAcceptableOrUnknown(
          data['birth_time_minutes']!,
          _birthTimeMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_birthTimeMinutesMeta);
    }
    if (data.containsKey('birth_time_known')) {
      context.handle(
        _birthTimeKnownMeta,
        birthTimeKnown.isAcceptableOrUnknown(
          data['birth_time_known']!,
          _birthTimeKnownMeta,
        ),
      );
    }
    if (data.containsKey('place_en')) {
      context.handle(
        _placeEnMeta,
        placeEn.isAcceptableOrUnknown(data['place_en']!, _placeEnMeta),
      );
    } else if (isInserting) {
      context.missing(_placeEnMeta);
    }
    if (data.containsKey('place_si')) {
      context.handle(
        _placeSiMeta,
        placeSi.isAcceptableOrUnknown(data['place_si']!, _placeSiMeta),
      );
    }
    if (data.containsKey('place_ta')) {
      context.handle(
        _placeTaMeta,
        placeTa.isAcceptableOrUnknown(data['place_ta']!, _placeTaMeta),
      );
    }
    if (data.containsKey('district')) {
      context.handle(
        _districtMeta,
        district.isAcceptableOrUnknown(data['district']!, _districtMeta),
      );
    } else if (isInserting) {
      context.missing(_districtMeta);
    }
    if (data.containsKey('district_si')) {
      context.handle(
        _districtSiMeta,
        districtSi.isAcceptableOrUnknown(data['district_si']!, _districtSiMeta),
      );
    }
    if (data.containsKey('district_ta')) {
      context.handle(
        _districtTaMeta,
        districtTa.isAcceptableOrUnknown(data['district_ta']!, _districtTaMeta),
      );
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('timezone')) {
      context.handle(
        _timezoneMeta,
        timezone.isAcceptableOrUnknown(data['timezone']!, _timezoneMeta),
      );
    } else if (isInserting) {
      context.missing(_timezoneMeta);
    }
    if (data.containsKey('country_code')) {
      context.handle(
        _countryCodeMeta,
        countryCode.isAcceptableOrUnknown(
          data['country_code']!,
          _countryCodeMeta,
        ),
      );
    }
    if (data.containsKey('is_selected')) {
      context.handle(
        _isSelectedMeta,
        isSelected.isAcceptableOrUnknown(data['is_selected']!, _isSelectedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Profile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Profile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      birthDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}birth_date'],
      )!,
      birthTimeMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}birth_time_minutes'],
      )!,
      birthTimeKnown: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}birth_time_known'],
      )!,
      placeEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}place_en'],
      )!,
      placeSi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}place_si'],
      ),
      placeTa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}place_ta'],
      ),
      district: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}district'],
      )!,
      districtSi: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}district_si'],
      ),
      districtTa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}district_ta'],
      ),
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      timezone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timezone'],
      )!,
      countryCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}country_code'],
      ),
      isSelected: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_selected'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }
}

class Profile extends DataClass implements Insertable<Profile> {
  final int id;
  final String name;

  /// Midnight on the birth date, local time.
  final DateTime birthDate;

  /// Minutes after midnight, so it survives a timezone the phone did not have
  /// when it was saved. A DateTime here would carry an offset that is only
  /// correct on the device that wrote it.
  final int birthTimeMinutes;

  /// False when the user said they do not know. The lagna is then a
  /// convention rather than a computation, and every screen must say so.
  final bool birthTimeKnown;
  final String placeEn;

  /// Null where the place has no translation, which is most of the world.
  /// Not backfilled with the English name: that would record "the Sinhala for
  /// Chennai is Chennai" and no later release could tell it from a real one.
  final String? placeSi;
  final String? placeTa;
  final String district;
  final String? districtSi;
  final String? districtTa;
  final double latitude;
  final double longitude;
  final String timezone;

  /// ISO 3166-1 alpha-2. Null for rows saved before the place list went
  /// worldwide; those are Sri Lankan, but see the migration for why they are
  /// left null rather than stamped `LK`.
  final String? countryCode;

  /// Which profile the app is showing. Exactly one row is true; the store
  /// enforces it, because two would make "whose chart is this" unanswerable.
  final bool isSelected;

  /// Oldest first, so a list keeps the order they were added in.
  final DateTime createdAt;
  const Profile({
    required this.id,
    required this.name,
    required this.birthDate,
    required this.birthTimeMinutes,
    required this.birthTimeKnown,
    required this.placeEn,
    this.placeSi,
    this.placeTa,
    required this.district,
    this.districtSi,
    this.districtTa,
    required this.latitude,
    required this.longitude,
    required this.timezone,
    this.countryCode,
    required this.isSelected,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['birth_date'] = Variable<DateTime>(birthDate);
    map['birth_time_minutes'] = Variable<int>(birthTimeMinutes);
    map['birth_time_known'] = Variable<bool>(birthTimeKnown);
    map['place_en'] = Variable<String>(placeEn);
    if (!nullToAbsent || placeSi != null) {
      map['place_si'] = Variable<String>(placeSi);
    }
    if (!nullToAbsent || placeTa != null) {
      map['place_ta'] = Variable<String>(placeTa);
    }
    map['district'] = Variable<String>(district);
    if (!nullToAbsent || districtSi != null) {
      map['district_si'] = Variable<String>(districtSi);
    }
    if (!nullToAbsent || districtTa != null) {
      map['district_ta'] = Variable<String>(districtTa);
    }
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['timezone'] = Variable<String>(timezone);
    if (!nullToAbsent || countryCode != null) {
      map['country_code'] = Variable<String>(countryCode);
    }
    map['is_selected'] = Variable<bool>(isSelected);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      name: Value(name),
      birthDate: Value(birthDate),
      birthTimeMinutes: Value(birthTimeMinutes),
      birthTimeKnown: Value(birthTimeKnown),
      placeEn: Value(placeEn),
      placeSi: placeSi == null && nullToAbsent
          ? const Value.absent()
          : Value(placeSi),
      placeTa: placeTa == null && nullToAbsent
          ? const Value.absent()
          : Value(placeTa),
      district: Value(district),
      districtSi: districtSi == null && nullToAbsent
          ? const Value.absent()
          : Value(districtSi),
      districtTa: districtTa == null && nullToAbsent
          ? const Value.absent()
          : Value(districtTa),
      latitude: Value(latitude),
      longitude: Value(longitude),
      timezone: Value(timezone),
      countryCode: countryCode == null && nullToAbsent
          ? const Value.absent()
          : Value(countryCode),
      isSelected: Value(isSelected),
      createdAt: Value(createdAt),
    );
  }

  factory Profile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Profile(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      birthDate: serializer.fromJson<DateTime>(json['birthDate']),
      birthTimeMinutes: serializer.fromJson<int>(json['birthTimeMinutes']),
      birthTimeKnown: serializer.fromJson<bool>(json['birthTimeKnown']),
      placeEn: serializer.fromJson<String>(json['placeEn']),
      placeSi: serializer.fromJson<String?>(json['placeSi']),
      placeTa: serializer.fromJson<String?>(json['placeTa']),
      district: serializer.fromJson<String>(json['district']),
      districtSi: serializer.fromJson<String?>(json['districtSi']),
      districtTa: serializer.fromJson<String?>(json['districtTa']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      timezone: serializer.fromJson<String>(json['timezone']),
      countryCode: serializer.fromJson<String?>(json['countryCode']),
      isSelected: serializer.fromJson<bool>(json['isSelected']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'birthDate': serializer.toJson<DateTime>(birthDate),
      'birthTimeMinutes': serializer.toJson<int>(birthTimeMinutes),
      'birthTimeKnown': serializer.toJson<bool>(birthTimeKnown),
      'placeEn': serializer.toJson<String>(placeEn),
      'placeSi': serializer.toJson<String?>(placeSi),
      'placeTa': serializer.toJson<String?>(placeTa),
      'district': serializer.toJson<String>(district),
      'districtSi': serializer.toJson<String?>(districtSi),
      'districtTa': serializer.toJson<String?>(districtTa),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'timezone': serializer.toJson<String>(timezone),
      'countryCode': serializer.toJson<String?>(countryCode),
      'isSelected': serializer.toJson<bool>(isSelected),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Profile copyWith({
    int? id,
    String? name,
    DateTime? birthDate,
    int? birthTimeMinutes,
    bool? birthTimeKnown,
    String? placeEn,
    Value<String?> placeSi = const Value.absent(),
    Value<String?> placeTa = const Value.absent(),
    String? district,
    Value<String?> districtSi = const Value.absent(),
    Value<String?> districtTa = const Value.absent(),
    double? latitude,
    double? longitude,
    String? timezone,
    Value<String?> countryCode = const Value.absent(),
    bool? isSelected,
    DateTime? createdAt,
  }) => Profile(
    id: id ?? this.id,
    name: name ?? this.name,
    birthDate: birthDate ?? this.birthDate,
    birthTimeMinutes: birthTimeMinutes ?? this.birthTimeMinutes,
    birthTimeKnown: birthTimeKnown ?? this.birthTimeKnown,
    placeEn: placeEn ?? this.placeEn,
    placeSi: placeSi.present ? placeSi.value : this.placeSi,
    placeTa: placeTa.present ? placeTa.value : this.placeTa,
    district: district ?? this.district,
    districtSi: districtSi.present ? districtSi.value : this.districtSi,
    districtTa: districtTa.present ? districtTa.value : this.districtTa,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    timezone: timezone ?? this.timezone,
    countryCode: countryCode.present ? countryCode.value : this.countryCode,
    isSelected: isSelected ?? this.isSelected,
    createdAt: createdAt ?? this.createdAt,
  );
  Profile copyWithCompanion(ProfilesCompanion data) {
    return Profile(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      birthDate: data.birthDate.present ? data.birthDate.value : this.birthDate,
      birthTimeMinutes: data.birthTimeMinutes.present
          ? data.birthTimeMinutes.value
          : this.birthTimeMinutes,
      birthTimeKnown: data.birthTimeKnown.present
          ? data.birthTimeKnown.value
          : this.birthTimeKnown,
      placeEn: data.placeEn.present ? data.placeEn.value : this.placeEn,
      placeSi: data.placeSi.present ? data.placeSi.value : this.placeSi,
      placeTa: data.placeTa.present ? data.placeTa.value : this.placeTa,
      district: data.district.present ? data.district.value : this.district,
      districtSi: data.districtSi.present
          ? data.districtSi.value
          : this.districtSi,
      districtTa: data.districtTa.present
          ? data.districtTa.value
          : this.districtTa,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      timezone: data.timezone.present ? data.timezone.value : this.timezone,
      countryCode: data.countryCode.present
          ? data.countryCode.value
          : this.countryCode,
      isSelected: data.isSelected.present
          ? data.isSelected.value
          : this.isSelected,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Profile(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('birthDate: $birthDate, ')
          ..write('birthTimeMinutes: $birthTimeMinutes, ')
          ..write('birthTimeKnown: $birthTimeKnown, ')
          ..write('placeEn: $placeEn, ')
          ..write('placeSi: $placeSi, ')
          ..write('placeTa: $placeTa, ')
          ..write('district: $district, ')
          ..write('districtSi: $districtSi, ')
          ..write('districtTa: $districtTa, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('timezone: $timezone, ')
          ..write('countryCode: $countryCode, ')
          ..write('isSelected: $isSelected, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    birthDate,
    birthTimeMinutes,
    birthTimeKnown,
    placeEn,
    placeSi,
    placeTa,
    district,
    districtSi,
    districtTa,
    latitude,
    longitude,
    timezone,
    countryCode,
    isSelected,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Profile &&
          other.id == this.id &&
          other.name == this.name &&
          other.birthDate == this.birthDate &&
          other.birthTimeMinutes == this.birthTimeMinutes &&
          other.birthTimeKnown == this.birthTimeKnown &&
          other.placeEn == this.placeEn &&
          other.placeSi == this.placeSi &&
          other.placeTa == this.placeTa &&
          other.district == this.district &&
          other.districtSi == this.districtSi &&
          other.districtTa == this.districtTa &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.timezone == this.timezone &&
          other.countryCode == this.countryCode &&
          other.isSelected == this.isSelected &&
          other.createdAt == this.createdAt);
}

class ProfilesCompanion extends UpdateCompanion<Profile> {
  final Value<int> id;
  final Value<String> name;
  final Value<DateTime> birthDate;
  final Value<int> birthTimeMinutes;
  final Value<bool> birthTimeKnown;
  final Value<String> placeEn;
  final Value<String?> placeSi;
  final Value<String?> placeTa;
  final Value<String> district;
  final Value<String?> districtSi;
  final Value<String?> districtTa;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<String> timezone;
  final Value<String?> countryCode;
  final Value<bool> isSelected;
  final Value<DateTime> createdAt;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.birthDate = const Value.absent(),
    this.birthTimeMinutes = const Value.absent(),
    this.birthTimeKnown = const Value.absent(),
    this.placeEn = const Value.absent(),
    this.placeSi = const Value.absent(),
    this.placeTa = const Value.absent(),
    this.district = const Value.absent(),
    this.districtSi = const Value.absent(),
    this.districtTa = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.timezone = const Value.absent(),
    this.countryCode = const Value.absent(),
    this.isSelected = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ProfilesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required DateTime birthDate,
    required int birthTimeMinutes,
    this.birthTimeKnown = const Value.absent(),
    required String placeEn,
    this.placeSi = const Value.absent(),
    this.placeTa = const Value.absent(),
    required String district,
    this.districtSi = const Value.absent(),
    this.districtTa = const Value.absent(),
    required double latitude,
    required double longitude,
    required String timezone,
    this.countryCode = const Value.absent(),
    this.isSelected = const Value.absent(),
    required DateTime createdAt,
  }) : name = Value(name),
       birthDate = Value(birthDate),
       birthTimeMinutes = Value(birthTimeMinutes),
       placeEn = Value(placeEn),
       district = Value(district),
       latitude = Value(latitude),
       longitude = Value(longitude),
       timezone = Value(timezone),
       createdAt = Value(createdAt);
  static Insertable<Profile> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<DateTime>? birthDate,
    Expression<int>? birthTimeMinutes,
    Expression<bool>? birthTimeKnown,
    Expression<String>? placeEn,
    Expression<String>? placeSi,
    Expression<String>? placeTa,
    Expression<String>? district,
    Expression<String>? districtSi,
    Expression<String>? districtTa,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<String>? timezone,
    Expression<String>? countryCode,
    Expression<bool>? isSelected,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (birthDate != null) 'birth_date': birthDate,
      if (birthTimeMinutes != null) 'birth_time_minutes': birthTimeMinutes,
      if (birthTimeKnown != null) 'birth_time_known': birthTimeKnown,
      if (placeEn != null) 'place_en': placeEn,
      if (placeSi != null) 'place_si': placeSi,
      if (placeTa != null) 'place_ta': placeTa,
      if (district != null) 'district': district,
      if (districtSi != null) 'district_si': districtSi,
      if (districtTa != null) 'district_ta': districtTa,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (timezone != null) 'timezone': timezone,
      if (countryCode != null) 'country_code': countryCode,
      if (isSelected != null) 'is_selected': isSelected,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ProfilesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<DateTime>? birthDate,
    Value<int>? birthTimeMinutes,
    Value<bool>? birthTimeKnown,
    Value<String>? placeEn,
    Value<String?>? placeSi,
    Value<String?>? placeTa,
    Value<String>? district,
    Value<String?>? districtSi,
    Value<String?>? districtTa,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<String>? timezone,
    Value<String?>? countryCode,
    Value<bool>? isSelected,
    Value<DateTime>? createdAt,
  }) {
    return ProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      birthTimeMinutes: birthTimeMinutes ?? this.birthTimeMinutes,
      birthTimeKnown: birthTimeKnown ?? this.birthTimeKnown,
      placeEn: placeEn ?? this.placeEn,
      placeSi: placeSi ?? this.placeSi,
      placeTa: placeTa ?? this.placeTa,
      district: district ?? this.district,
      districtSi: districtSi ?? this.districtSi,
      districtTa: districtTa ?? this.districtTa,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timezone: timezone ?? this.timezone,
      countryCode: countryCode ?? this.countryCode,
      isSelected: isSelected ?? this.isSelected,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (birthDate.present) {
      map['birth_date'] = Variable<DateTime>(birthDate.value);
    }
    if (birthTimeMinutes.present) {
      map['birth_time_minutes'] = Variable<int>(birthTimeMinutes.value);
    }
    if (birthTimeKnown.present) {
      map['birth_time_known'] = Variable<bool>(birthTimeKnown.value);
    }
    if (placeEn.present) {
      map['place_en'] = Variable<String>(placeEn.value);
    }
    if (placeSi.present) {
      map['place_si'] = Variable<String>(placeSi.value);
    }
    if (placeTa.present) {
      map['place_ta'] = Variable<String>(placeTa.value);
    }
    if (district.present) {
      map['district'] = Variable<String>(district.value);
    }
    if (districtSi.present) {
      map['district_si'] = Variable<String>(districtSi.value);
    }
    if (districtTa.present) {
      map['district_ta'] = Variable<String>(districtTa.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (timezone.present) {
      map['timezone'] = Variable<String>(timezone.value);
    }
    if (countryCode.present) {
      map['country_code'] = Variable<String>(countryCode.value);
    }
    if (isSelected.present) {
      map['is_selected'] = Variable<bool>(isSelected.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('birthDate: $birthDate, ')
          ..write('birthTimeMinutes: $birthTimeMinutes, ')
          ..write('birthTimeKnown: $birthTimeKnown, ')
          ..write('placeEn: $placeEn, ')
          ..write('placeSi: $placeSi, ')
          ..write('placeTa: $placeTa, ')
          ..write('district: $district, ')
          ..write('districtSi: $districtSi, ')
          ..write('districtTa: $districtTa, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('timezone: $timezone, ')
          ..write('countryCode: $countryCode, ')
          ..write('isSelected: $isSelected, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [profiles];
}

typedef $$ProfilesTableCreateCompanionBuilder =
    ProfilesCompanion Function({
      Value<int> id,
      required String name,
      required DateTime birthDate,
      required int birthTimeMinutes,
      Value<bool> birthTimeKnown,
      required String placeEn,
      Value<String?> placeSi,
      Value<String?> placeTa,
      required String district,
      Value<String?> districtSi,
      Value<String?> districtTa,
      required double latitude,
      required double longitude,
      required String timezone,
      Value<String?> countryCode,
      Value<bool> isSelected,
      required DateTime createdAt,
    });
typedef $$ProfilesTableUpdateCompanionBuilder =
    ProfilesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<DateTime> birthDate,
      Value<int> birthTimeMinutes,
      Value<bool> birthTimeKnown,
      Value<String> placeEn,
      Value<String?> placeSi,
      Value<String?> placeTa,
      Value<String> district,
      Value<String?> districtSi,
      Value<String?> districtTa,
      Value<double> latitude,
      Value<double> longitude,
      Value<String> timezone,
      Value<String?> countryCode,
      Value<bool> isSelected,
      Value<DateTime> createdAt,
    });

class $$ProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get birthDate => $composableBuilder(
    column: $table.birthDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get birthTimeMinutes => $composableBuilder(
    column: $table.birthTimeMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get birthTimeKnown => $composableBuilder(
    column: $table.birthTimeKnown,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get placeEn => $composableBuilder(
    column: $table.placeEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get placeSi => $composableBuilder(
    column: $table.placeSi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get placeTa => $composableBuilder(
    column: $table.placeTa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get district => $composableBuilder(
    column: $table.district,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get districtSi => $composableBuilder(
    column: $table.districtSi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get districtTa => $composableBuilder(
    column: $table.districtTa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get countryCode => $composableBuilder(
    column: $table.countryCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSelected => $composableBuilder(
    column: $table.isSelected,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get birthDate => $composableBuilder(
    column: $table.birthDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get birthTimeMinutes => $composableBuilder(
    column: $table.birthTimeMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get birthTimeKnown => $composableBuilder(
    column: $table.birthTimeKnown,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get placeEn => $composableBuilder(
    column: $table.placeEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get placeSi => $composableBuilder(
    column: $table.placeSi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get placeTa => $composableBuilder(
    column: $table.placeTa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get district => $composableBuilder(
    column: $table.district,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get districtSi => $composableBuilder(
    column: $table.districtSi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get districtTa => $composableBuilder(
    column: $table.districtTa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get countryCode => $composableBuilder(
    column: $table.countryCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSelected => $composableBuilder(
    column: $table.isSelected,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get birthDate =>
      $composableBuilder(column: $table.birthDate, builder: (column) => column);

  GeneratedColumn<int> get birthTimeMinutes => $composableBuilder(
    column: $table.birthTimeMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get birthTimeKnown => $composableBuilder(
    column: $table.birthTimeKnown,
    builder: (column) => column,
  );

  GeneratedColumn<String> get placeEn =>
      $composableBuilder(column: $table.placeEn, builder: (column) => column);

  GeneratedColumn<String> get placeSi =>
      $composableBuilder(column: $table.placeSi, builder: (column) => column);

  GeneratedColumn<String> get placeTa =>
      $composableBuilder(column: $table.placeTa, builder: (column) => column);

  GeneratedColumn<String> get district =>
      $composableBuilder(column: $table.district, builder: (column) => column);

  GeneratedColumn<String> get districtSi => $composableBuilder(
    column: $table.districtSi,
    builder: (column) => column,
  );

  GeneratedColumn<String> get districtTa => $composableBuilder(
    column: $table.districtTa,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<String> get timezone =>
      $composableBuilder(column: $table.timezone, builder: (column) => column);

  GeneratedColumn<String> get countryCode => $composableBuilder(
    column: $table.countryCode,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSelected => $composableBuilder(
    column: $table.isSelected,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfilesTable,
          Profile,
          $$ProfilesTableFilterComposer,
          $$ProfilesTableOrderingComposer,
          $$ProfilesTableAnnotationComposer,
          $$ProfilesTableCreateCompanionBuilder,
          $$ProfilesTableUpdateCompanionBuilder,
          (Profile, BaseReferences<_$AppDatabase, $ProfilesTable, Profile>),
          Profile,
          PrefetchHooks Function()
        > {
  $$ProfilesTableTableManager(_$AppDatabase db, $ProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> birthDate = const Value.absent(),
                Value<int> birthTimeMinutes = const Value.absent(),
                Value<bool> birthTimeKnown = const Value.absent(),
                Value<String> placeEn = const Value.absent(),
                Value<String?> placeSi = const Value.absent(),
                Value<String?> placeTa = const Value.absent(),
                Value<String> district = const Value.absent(),
                Value<String?> districtSi = const Value.absent(),
                Value<String?> districtTa = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<String> timezone = const Value.absent(),
                Value<String?> countryCode = const Value.absent(),
                Value<bool> isSelected = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ProfilesCompanion(
                id: id,
                name: name,
                birthDate: birthDate,
                birthTimeMinutes: birthTimeMinutes,
                birthTimeKnown: birthTimeKnown,
                placeEn: placeEn,
                placeSi: placeSi,
                placeTa: placeTa,
                district: district,
                districtSi: districtSi,
                districtTa: districtTa,
                latitude: latitude,
                longitude: longitude,
                timezone: timezone,
                countryCode: countryCode,
                isSelected: isSelected,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required DateTime birthDate,
                required int birthTimeMinutes,
                Value<bool> birthTimeKnown = const Value.absent(),
                required String placeEn,
                Value<String?> placeSi = const Value.absent(),
                Value<String?> placeTa = const Value.absent(),
                required String district,
                Value<String?> districtSi = const Value.absent(),
                Value<String?> districtTa = const Value.absent(),
                required double latitude,
                required double longitude,
                required String timezone,
                Value<String?> countryCode = const Value.absent(),
                Value<bool> isSelected = const Value.absent(),
                required DateTime createdAt,
              }) => ProfilesCompanion.insert(
                id: id,
                name: name,
                birthDate: birthDate,
                birthTimeMinutes: birthTimeMinutes,
                birthTimeKnown: birthTimeKnown,
                placeEn: placeEn,
                placeSi: placeSi,
                placeTa: placeTa,
                district: district,
                districtSi: districtSi,
                districtTa: districtTa,
                latitude: latitude,
                longitude: longitude,
                timezone: timezone,
                countryCode: countryCode,
                isSelected: isSelected,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfilesTable,
      Profile,
      $$ProfilesTableFilterComposer,
      $$ProfilesTableOrderingComposer,
      $$ProfilesTableAnnotationComposer,
      $$ProfilesTableCreateCompanionBuilder,
      $$ProfilesTableUpdateCompanionBuilder,
      (Profile, BaseReferences<_$AppDatabase, $ProfilesTable, Profile>),
      Profile,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
}
