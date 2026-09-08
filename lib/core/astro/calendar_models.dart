import '../config/app_locale.dart';

/// The twelve poya of the Sinhala Buddhist year.
///
/// Each is a full moon, named for the lunar month it falls in. When two full
/// moons land in the same month an intercalary "Adhi" poya is inserted.
enum PoyaMonth {
  duruthu('Duruthu', 'දුරුතු', 'துருத்து', 1),
  navam('Navam', 'නවම්', 'நவம்', 2),
  medin('Medin', 'මැදින්', 'மெதின்', 3),
  bak('Bak', 'බක්', 'பக்', 4),
  vesak('Vesak', 'වෙසක්', 'வெசாக்', 5),
  poson('Poson', 'පොසොන්', 'பொசொன்', 6),
  esala('Esala', 'ඇසළ', 'எசல', 7),
  nikini('Nikini', 'නිකිණි', 'நிக்கிணி', 8),
  binara('Binara', 'බිනර', 'பினர', 9),
  vap('Vap', 'වප්', 'வப்', 10),
  il('Il', 'ඉල්', 'இல்', 11),
  unduvap('Unduvap', 'උඳුවප්', 'உந்துவப்', 12);

  const PoyaMonth(this.en, this.si, this.ta, this.gregorianMonth);

  final String en;
  final String si;

  /// The Tamil form.
  ///
  /// These are Sinhala month names written in Tamil letters, and that is
  /// correct rather than the transliteration mistake KAN-58 was about: they
  /// are proper nouns with no separate Tamil word, the same way Colombo is
  /// கொழும்பு. What KAN-58 forbade was respelling an English *abbreviation*
  /// — "La", "Su" — which spells a sound that means nothing.
  final String ta;

  /// The Gregorian month this poya normally falls in.
  final int gregorianMonth;

  String label(AppLocale locale) => switch (locale) {
    AppLocale.si => si,
    AppLocale.ta => ta,
    AppLocale.en => en,
  };

  static PoyaMonth forGregorianMonth(int month) =>
      PoyaMonth.values.firstWhere((p) => p.gregorianMonth == month);

  /// What the day commemorates. Vesak and Poson carry the most weight in Sri
  /// Lanka — Vesak marks the birth, enlightenment and passing of the Buddha,
  /// Poson the arrival of Buddhism on the island.
  String get significance => switch (this) {
    PoyaMonth.duruthu => "The Buddha's first visit to Sri Lanka",
    PoyaMonth.navam =>
      'The first Buddhist council and the appointment of the '
          'chief disciples',
    PoyaMonth.medin => "The Buddha's visit to his family after enlightenment",
    PoyaMonth.bak => "The Buddha's second visit to Sri Lanka",
    PoyaMonth.vesak => "The Buddha's birth, enlightenment and passing",
    PoyaMonth.poson =>
      'The arrival of Buddhism in Sri Lanka with Arahat '
          'Mahinda',
    PoyaMonth.esala => 'The first sermon, and the Esala Perahera',
    PoyaMonth.nikini => 'The first Dhamma council',
    PoyaMonth.binara => 'The founding of the order of nuns',
    PoyaMonth.vap => 'The end of the rains retreat',
    PoyaMonth.il => 'The despatch of the first missionaries',
    PoyaMonth.unduvap => 'The arrival of the sacred Bo sapling with Sangamitta',
  };
}

/// What kind of day this is, which decides how it is presented and whether it
/// can be trusted as an exact date.
enum FestivalKind {
  /// A full moon. Computed exactly from lunar phase.
  poya,

  /// Derived from a solar ingress — Sinhala/Tamil New Year, Thai Pongal.
  solarIngress,

  /// A fixed Gregorian date.
  fixed,
}

class Festival {
  const Festival({
    required this.date,
    required this.name,
    required this.kind,
    this.si,
    this.ta,
    this.exactMoment,
    this.note,
    this.isPublicHoliday = true,
  });

  /// The calendar day, in Sri Lankan local time.
  final DateTime date;

  final String name;
  final String? si;
  final String? ta;
  final FestivalKind kind;

  /// The precise astronomical instant behind the day, where one exists — the
  /// moment of full moon, or of the Sun's ingress. Null for fixed dates.
  final DateTime? exactMoment;

  final String? note;
  final bool isPublicHoliday;

  /// The name in the reader's language, falling back to English.
  ///
  /// The home screen used to print `si ?? name`, which is Sinhala in a Tamil
  /// app and Sinhala in an English one (KAN-59).
  String label(AppLocale locale) => switch (locale) {
    AppLocale.si => si ?? name,
    AppLocale.ta => ta ?? name,
    AppLocale.en => name,
  };

  int daysFrom(DateTime from) => DateTime(
    date.year,
    date.month,
    date.day,
  ).difference(DateTime(from.year, from.month, from.day)).inDays;
}

/// A poya day, with the exact moment of full moon that defines it.
class PoyaDay extends Festival {
  PoyaDay({
    required super.date,
    required this.month,
    required this.isAdhi,
    required DateTime fullMoon,
  }) : super(
         name: isAdhi ? 'Adhi ${month.en} Poya' : '${month.en} Poya',
         si: isAdhi ? 'අධි ${month.si} පොහොය' : '${month.si} පොහොය',
         ta: isAdhi ? 'அதி ${month.ta} பௌர்ணமி' : '${month.ta} பௌர்ணமி',
         kind: FestivalKind.poya,
         exactMoment: fullMoon,
         note: month.significance,
       );

  final PoyaMonth month;

  /// True for the intercalary poya inserted when two full moons fall in the
  /// same Gregorian month.
  final bool isAdhi;

  /// The exact instant of full moon, in Sri Lankan local time.
  ///
  /// The poya *day* is whichever calendar day contains this moment, so a full
  /// moon just after midnight belongs to the day that is only minutes old.
  DateTime get fullMoon => exactMoment!;
}
