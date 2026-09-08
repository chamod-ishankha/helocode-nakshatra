import '../config/app_locale.dart';

import 'models.dart';

/// The thirty tithi (lunar days) of a lunar month.
///
/// A tithi is the time the Moon takes to gain 12° on the Sun, so its length
/// varies between roughly 19 and 26 hours. It is not a clock day, and a
/// calendar date can contain two of them or none at all.
enum Tithi {
  pratipada('Pratipada', 'පෑලවිය', 'பிரதமை'),
  dwitiya('Dwitiya', 'දියවක', 'துவிதியை'),
  tritiya('Tritiya', 'තියවක', 'திரிதியை'),
  chaturthi('Chaturthi', 'සිව්වක', 'சதுர்த்தி'),
  panchami('Panchami', 'පස්වක', 'பஞ்சமி'),
  shashthi('Shashthi', 'සයවක', 'சஷ்டி'),
  saptami('Saptami', 'සත්වක', 'சப்தமி'),
  ashtami('Ashtami', 'අටවක', 'அஷ்டமி'),
  navami('Navami', 'නවවක', 'நவமி'),
  dashami('Dashami', 'දසවක', 'தசமி'),
  ekadashi('Ekadashi', 'එකොළොස්වක', 'ஏகாதசி'),
  dwadashi('Dwadashi', 'දොළොස්වක', 'துவாதசி'),
  trayodashi('Trayodashi', 'තෙළෙස්වක', 'திரயோதசி'),
  chaturdashi('Chaturdashi', 'තුදුස්වක', 'சதுர்த்தசி'),
  purnimaAmavasya('Purnima/Amavasya', 'පසළොස්වක/අමාවක', 'பௌர்ணமி/அமாவாசை');

  const Tithi(this.en, this.si, this.ta);

  final String en;
  final String si;
  final String ta;

  String label(AppLocale locale) => switch (locale) {
    AppLocale.si => si,
    AppLocale.ta => ta,
    AppLocale.en => en,
  };
}

/// Waxing or waning half of the lunar month.
enum Paksha {
  shukla('Shukla', 'පුර', 'வளர்பிறை', 'waxing', 'වැඩෙන', 'வளர்'),
  krishna('Krishna', 'අව', 'தேய்பிறை', 'waning', 'අඩුවෙන', 'தேய்');

  const Paksha(
    this.en,
    this.si,
    this.ta,
    this.description,
    this.descriptionSi,
    this.descriptionTa,
  );

  final String en;
  final String si;
  final String ta;

  final String description;
  final String descriptionSi;
  final String descriptionTa;

  String label(AppLocale locale) => switch (locale) {
    AppLocale.si => si,
    AppLocale.ta => ta,
    AppLocale.en => en,
  };

  /// "waxing" or "waning", for the parenthetical beside a tithi.
  String describe(AppLocale locale) => switch (locale) {
    AppLocale.si => descriptionSi,
    AppLocale.ta => descriptionTa,
    AppLocale.en => description,
  };
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

  String label(AppLocale locale) => switch (locale) {
    AppLocale.si => si,
    AppLocale.ta => ta,
    AppLocale.en => en,
  };
}

/// The 27 yoga, from the combined longitude of Sun and Moon.
enum Yoga {
  vishkambha('Vishkambha', 'විෂ්කම්භ', 'விஷ்கம்பம்'),
  priti('Priti', 'ප්‍රීති', 'பிரீதி'),
  ayushman('Ayushman', 'ආයුෂ්මාන්', 'ஆயுஷ்மான்'),
  saubhagya('Saubhagya', 'සෞභාග්‍ය', 'சௌபாக்கியம்'),
  shobhana('Shobhana', 'ශෝභන', 'சோபனம்'),
  atiganda('Atiganda', 'අතිගණ්ඩ', 'அதிகண்டம்'),
  sukarma('Sukarma', 'සුකර්ම', 'சுகர்மம்'),
  dhriti('Dhriti', 'ධෘති', 'திருதி'),
  shula('Shula', 'ශූල', 'சூலம்'),
  ganda('Ganda', 'ගණ්ඩ', 'கண்டம்'),
  vriddhi('Vriddhi', 'වෘද්ධි', 'விருத்தி'),
  dhruva('Dhruva', 'ධ්‍රැව', 'துருவம்'),
  vyaghata('Vyaghata', 'ව්‍යාඝාත', 'வியாகாதம்'),
  harshana('Harshana', 'හර්ෂණ', 'அர்ஷணம்'),
  vajra('Vajra', 'වජ්‍ර', 'வஜ்ரம்'),
  siddhi('Siddhi', 'සිද්ධි', 'சித்தி'),
  vyatipata('Vyatipata', 'ව්‍යතීපාත', 'வியதீபாதம்'),
  variyan('Variyan', 'වරීයාන්', 'வரியான்'),
  parigha('Parigha', 'පරිඝ', 'பரிகம்'),
  shiva('Shiva', 'ශිව', 'சிவம்'),
  siddha('Siddha', 'සිද්ධ', 'சித்தம்'),
  sadhya('Sadhya', 'සාධ්‍ය', 'சாத்தியம்'),
  shubha('Shubha', 'ශුභ', 'சுபம்'),
  shukla('Shukla', 'ශුක්ල', 'சுக்லம்'),
  brahma('Brahma', 'බ්‍රහ්ම', 'பிரம்மம்'),
  indra('Indra', 'ඉන්ද්‍ර', 'ஐந்திரம்'),
  vaidhriti('Vaidhriti', 'වෛධෘති', 'வைதிருதி');

  const Yoga(this.en, this.si, this.ta);

  final String en;
  final String si;
  final String ta;

  String label(AppLocale locale) => switch (locale) {
    AppLocale.si => si,
    AppLocale.ta => ta,
    AppLocale.en => en,
  };
}

/// Karana — half a tithi. Sixty per lunar month, drawn from eleven names.
enum Karana {
  bava('Bava', 'බව', 'பவம்'),
  balava('Balava', 'බාලව', 'பாலவம்'),
  kaulava('Kaulava', 'කෞලව', 'கௌலவம்'),
  taitila('Taitila', 'තෛතිල', 'தைதுலம்'),
  gara('Gara', 'ගර', 'கரசை'),
  vanija('Vanija', 'වණිජ', 'வணிசை'),
  vishti('Vishti', 'විෂ්ටි', 'விஷ்டி'),
  shakuni('Shakuni', 'ශකුනි', 'சகுனி'),
  chatushpada('Chatushpada', 'චතුෂ්පාද', 'சதுஷ்பாதம்'),
  naga('Naga', 'නාග', 'நாகவம்'),
  kimstughna('Kimstughna', 'කිංස්තුඝ්න', 'கிம்ஸ்துக்னம்');

  const Karana(this.en, this.si, this.ta);

  final String en;
  final String si;
  final String ta;

  String label(AppLocale locale) => switch (locale) {
    AppLocale.si => si,
    AppLocale.ta => ta,
    AppLocale.en => en,
  };

  /// Vishti (also called Bhadra) is treated as inauspicious and is avoided for
  /// starting anything of consequence.
  bool get isInauspicious => this == Karana.vishti;
}

/// Which period a [TimeWindow] is.
///
/// The windows used to be identified by their English name, and two screens
/// picked rāhu kālaya out of the day with `name.startsWith('Rāhu')`. That is
/// fine until the name is translated, at which point the headline card
/// silently finds nothing — so the identity is an enum and the name is only
/// something to display (KAN-59).
enum WindowKind {
  rahu('Rāhu kālaya', 'රාහු කාලය', 'ராகு காலம்'),
  yamaganda('Yamaganda', 'යමගණ්ඩ', 'யமகண்டம்'),
  gulika('Gulika kālaya', 'ගුලික කාලය', 'குளிக காலம்'),
  auspicious('Auspicious', 'සුබ වේලාව', 'சுப நேரம்');

  const WindowKind(this.en, this.si, this.ta);

  final String en;
  final String si;
  final String ta;

  String label(AppLocale locale) => switch (locale) {
    AppLocale.si => si,
    AppLocale.ta => ta,
    AppLocale.en => en,
  };
}

/// A window of time, used for both auspicious and inauspicious periods.
class TimeWindow {
  const TimeWindow({
    required this.start,
    required this.end,
    required this.kind,
    this.auspicious = false,
  });

  final DateTime start;
  final DateTime end;
  final WindowKind kind;
  final bool auspicious;

  /// The English name, for logs and `toString`. Anything a reader sees goes
  /// through [WindowKind.label] instead.
  String get name => kind.en;

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
  final PanchangaElement<Nakshatra> nakshatra;
  final PanchangaElement<Yoga> yoga;
  final PanchangaElement<Karana> karana;

  final DateTime sunrise;
  final DateTime sunset;
  final DateTime? moonrise;
  final DateTime? moonset;

  Duration get dayLength => sunset.difference(sunrise);
}
