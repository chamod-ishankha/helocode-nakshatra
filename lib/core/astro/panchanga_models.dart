/// The thirty tithi (lunar days) of a lunar month.
///
/// A tithi is the time the Moon takes to gain 12° on the Sun, so its length
/// varies between roughly 19 and 26 hours. It is not a clock day, and a
/// calendar date can contain two of them or none at all.
enum Tithi {
  pratipada('Pratipada'),
  dwitiya('Dwitiya'),
  tritiya('Tritiya'),
  chaturthi('Chaturthi'),
  panchami('Panchami'),
  shashthi('Shashthi'),
  saptami('Saptami'),
  ashtami('Ashtami'),
  navami('Navami'),
  dashami('Dashami'),
  ekadashi('Ekadashi'),
  dwadashi('Dwadashi'),
  trayodashi('Trayodashi'),
  chaturdashi('Chaturdashi'),
  purnimaAmavasya('Purnima/Amavasya');

  const Tithi(this.en);
  final String en;
}

/// Waxing or waning half of the lunar month.
enum Paksha {
  shukla('Shukla', 'waxing'),
  krishna('Krishna', 'waning');

  const Paksha(this.en, this.description);
  final String en;
  final String description;
}

/// Weekday, reckoned sunrise to sunrise rather than midnight to midnight.
///
/// This is the source of the most common off-by-one in panchanga code: between
/// midnight and sunrise the vāra is still the *previous* day's.
enum Vara {
  ravi('Sunday', 'ඉරිදා', 'ஞாயிறு'),
  soma('Monday', 'සඳුදා', 'திங்கள்'),
  mangala('Tuesday', 'අඟහරුවාදා', 'செவ்வாய்'),
  budha('Wednesday', 'බදාදා', 'புதன்'),
  guru('Thursday', 'බ්‍රහස්පතින්දා', 'வியாழன்'),
  shukra('Friday', 'සිකුරාදා', 'வெள்ளி'),
  shani('Saturday', 'සෙනසුරාදා', 'சனி');

  const Vara(this.en, this.si, this.ta);
  final String en;
  final String si;
  final String ta;
}

/// The 27 yoga, from the combined longitude of Sun and Moon.
enum Yoga {
  vishkambha('Vishkambha'),
  priti('Priti'),
  ayushman('Ayushman'),
  saubhagya('Saubhagya'),
  shobhana('Shobhana'),
  atiganda('Atiganda'),
  sukarma('Sukarma'),
  dhriti('Dhriti'),
  shula('Shula'),
  ganda('Ganda'),
  vriddhi('Vriddhi'),
  dhruva('Dhruva'),
  vyaghata('Vyaghata'),
  harshana('Harshana'),
  vajra('Vajra'),
  siddhi('Siddhi'),
  vyatipata('Vyatipata'),
  variyan('Variyan'),
  parigha('Parigha'),
  shiva('Shiva'),
  siddha('Siddha'),
  sadhya('Sadhya'),
  shubha('Shubha'),
  shukla('Shukla'),
  brahma('Brahma'),
  indra('Indra'),
  vaidhriti('Vaidhriti');

  const Yoga(this.en);
  final String en;
}

/// Karana — half a tithi. Sixty per lunar month, drawn from eleven names.
enum Karana {
  bava('Bava'),
  balava('Balava'),
  kaulava('Kaulava'),
  taitila('Taitila'),
  gara('Gara'),
  vanija('Vanija'),
  vishti('Vishti'),
  shakuni('Shakuni'),
  chatushpada('Chatushpada'),
  naga('Naga'),
  kimstughna('Kimstughna');

  const Karana(this.en);
  final String en;

  /// Vishti (also called Bhadra) is treated as inauspicious and is avoided for
  /// starting anything of consequence.
  bool get isInauspicious => this == Karana.vishti;
}

/// A window of time, used for both auspicious and inauspicious periods.
class TimeWindow {
  const TimeWindow({
    required this.start,
    required this.end,
    required this.name,
    this.auspicious = false,
  });

  final DateTime start;
  final DateTime end;
  final String name;
  final bool auspicious;

  Duration get duration => end.difference(start);

  bool contains(DateTime t) => !t.isBefore(start) && t.isBefore(end);

  @override
  String toString() => '$name ${_hm(start)}-${_hm(end)}';

  static String _hm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';
}

/// A value that runs until a given moment.
///
/// Tithi, nakṣatra, yoga and karana all change partway through a day, and an
/// almanac always prints when. Showing only "today's tithi" without its end
/// time is the difference between useful and decorative.
class PanchangaElement<T> {
  const PanchangaElement({required this.value, required this.endsAt});

  final T value;

  /// When this element gives way to the next. Null if it could not be resolved
  /// within the search window.
  final DateTime? endsAt;
}

/// The five limbs of the almanac, plus the day's solar times.
class Panchanga {
  const Panchanga({
    required this.date,
    required this.vara,
    required this.tithi,
    required this.paksha,
    required this.nakshatra,
    required this.yoga,
    required this.karana,
    required this.sunrise,
    required this.sunset,
    this.moonrise,
    this.moonset,
  });

  final DateTime date;
  final Vara vara;
  final PanchangaElement<Tithi> tithi;
  final Paksha paksha;
  final PanchangaElement<String> nakshatra;
  final PanchangaElement<Yoga> yoga;
  final PanchangaElement<Karana> karana;

  final DateTime sunrise;
  final DateTime sunset;
  final DateTime? moonrise;
  final DateTime? moonset;

  Duration get dayLength => sunset.difference(sunrise);
}
