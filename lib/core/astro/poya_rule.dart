import 'calendar_models.dart';

/// Which calendar day a full moon's poya is kept on, and what it is called
/// (KAN-96).
///
/// Pure: every astronomical moment is passed in, so the rule can be tested
/// without the ephemeris.
///
/// ## Why not "the day of the full moon"
///
/// That was the rule until KAN-96, and it matched the official Sri Lankan
/// calendar on 21 of 61 poya days in 2023–2027. Vap 2026 is the case that was
/// reported: the Moon is full at 9:41 on the morning of the 26th, and the poya
/// is the 25th. A poya is kept on the day of pūrṇimā — the tithi that runs up
/// to the full moon — and is observed into the evening, so the day that counts
/// is the one whose sunset falls inside it.
///
/// Measured against those 61 official dates:
///
/// * pūrṇimā current at sunset, the later day if two are: **59 of 61**
/// * otherwise, pūrṇimā current at noon, which covers a tithi that falls
///   entirely between two sunsets
///
/// The two it misses are a tithi that begins one minute after sunset, and one
/// the almanac rounds the other way. No astronomical rule reproduces the
/// official calendar exactly, because it is set from a traditional almanac
/// whose tithi times differ from the ephemeris by minutes to hours. Which is
/// why the published dates are carried as data and win wherever they exist
/// (see `officialPoyaDays`); this rule is for the years they do not cover.
DateTime poyaDayFor({
  required DateTime purnimaStart,
  required DateTime fullMoon,
  required DateTime Function(DateTime day) sunsetOn,
  required DateTime Function(DateTime day) noonOn,
}) {
  bool inPurnima(DateTime t) =>
      !t.isBefore(purnimaStart) && t.isBefore(fullMoon);

  // Pūrṇimā lasts about a day, so it touches two or three calendar days.
  final first = DateTime(
    purnimaStart.year,
    purnimaStart.month,
    purnimaStart.day,
  );
  final days = [
    for (var i = 0; i < 3; i++)
      DateTime(first.year, first.month, first.day + i),
  ];

  final atSunset = days.where((d) => inPurnima(sunsetOn(d))).toList();
  if (atSunset.isNotEmpty) return atSunset.last;

  // A tithi with no sunset in it lies between two sunsets, so it holds at most
  // one noon — and, being longer than the eighteen hours from one sunset to
  // the next noon, always at least one.
  for (final d in days) {
    if (inPurnima(noonOn(d))) return d;
  }
  return DateTime(fullMoon.year, fullMoon.month, fullMoon.day);
}

/// The poya month of a full moon, from the sidereal sign the Sun is in at the
/// new moons either side of it (0 = Mēṣa … 11 = Mīna).
///
/// A lunar month is named for the sign the Sun enters during it: the month in
/// which it enters Mēṣa is Bak, Vṛṣabha Vesak, and so on round the year. A
/// month in which it enters no sign is intercalary, and takes the name of the
/// month after it with "Adhi" in front — Adhi Poson in May 2026, between Vesak
/// and Poson.
///
/// It used to be decided by the Gregorian month, the first of two full moons
/// in one month being the Adhi one. That named 1 May 2026 "Adhi Vesak" and
/// 31 May "Vesak"; officially they are Vesak and Adhi Poson.
///
/// Matches 59 of the 61 official names in 2023–2027. The two it misses are
/// 2023, where Sri Lanka kept the intercalary month as Adhi Esala while the
/// astronomy — and India's calendar — put it a month later. The published
/// names win where they exist.
({PoyaMonth month, bool isAdhi}) poyaMonthFor({
  required int sunSignAtNewMoonBefore,
  required int sunSignAtNewMoonAfter,
}) {
  if (sunSignAtNewMoonBefore == sunSignAtNewMoonAfter) {
    return (
      month: _bySignEntered[(sunSignAtNewMoonAfter + 1) % 12],
      isAdhi: true,
    );
  }
  return (month: _bySignEntered[sunSignAtNewMoonAfter], isAdhi: false);
}

/// The poya month whose lunar month contains the Sun's entry into each sign.
const _bySignEntered = [
  PoyaMonth.bak, // Mēṣa
  PoyaMonth.vesak, // Vṛṣabha
  PoyaMonth.poson, // Mithuna
  PoyaMonth.esala, // Kaṭaka
  PoyaMonth.nikini, // Siṃha
  PoyaMonth.binara, // Kanyā
  PoyaMonth.vap, // Tulā
  PoyaMonth.il, // Vṛścika
  PoyaMonth.unduvap, // Dhanus
  PoyaMonth.duruthu, // Makara
  PoyaMonth.navam, // Kumbha
  PoyaMonth.medin, // Mīna
];
