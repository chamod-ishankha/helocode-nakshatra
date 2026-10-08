import 'calendar_models.dart';

/// Poya days as Sri Lanka publishes them (KAN-96).
///
/// The government gazettes each year's poya days in advance, set from a
/// traditional almanac. No astronomical rule reproduces them exactly — see
/// `poyaDayFor` — so where a date has been published it is carried here and
/// wins over anything computed. A religious date that disagrees with the
/// calendar on the wall is worse than useless.
///
/// Sources: the Central Bank of Sri Lanka's bank holiday lists for 2023, 2024
/// and 2025, and the published public holiday list for 2026 and 2027.
/// 2023's Navam poya is absent from the Central Bank list and so from here;
/// that one month is computed. 2028 is not here: the list in circulation
/// places Navam 44 days after Duruthu, which cannot be right, and it waits for
/// the gazette.
///
/// To add a year, copy it from the gazette and run the device test in
/// integration_test/calendar_test.dart, which checks every entry against the
/// full moons and against the computed rule.
const Map<String, ({PoyaMonth month, bool isAdhi})> officialPoyaDays = {
  // 2023
  '2023-01-06': (month: PoyaMonth.duruthu, isAdhi: false),
  '2023-03-06': (month: PoyaMonth.medin, isAdhi: false),
  '2023-04-05': (month: PoyaMonth.bak, isAdhi: false),
  '2023-05-05': (month: PoyaMonth.vesak, isAdhi: false),
  '2023-06-03': (month: PoyaMonth.poson, isAdhi: false),
  '2023-07-03': (month: PoyaMonth.esala, isAdhi: true),
  '2023-08-01': (month: PoyaMonth.esala, isAdhi: false),
  '2023-08-30': (month: PoyaMonth.nikini, isAdhi: false),
  '2023-09-29': (month: PoyaMonth.binara, isAdhi: false),
  '2023-10-28': (month: PoyaMonth.vap, isAdhi: false),
  '2023-11-26': (month: PoyaMonth.il, isAdhi: false),
  '2023-12-26': (month: PoyaMonth.unduvap, isAdhi: false),
  // 2024
  '2024-01-25': (month: PoyaMonth.duruthu, isAdhi: false),
  '2024-02-23': (month: PoyaMonth.navam, isAdhi: false),
  '2024-03-24': (month: PoyaMonth.medin, isAdhi: false),
  '2024-04-23': (month: PoyaMonth.bak, isAdhi: false),
  '2024-05-23': (month: PoyaMonth.vesak, isAdhi: false),
  '2024-06-21': (month: PoyaMonth.poson, isAdhi: false),
  '2024-07-20': (month: PoyaMonth.esala, isAdhi: false),
  '2024-08-19': (month: PoyaMonth.nikini, isAdhi: false),
  '2024-09-17': (month: PoyaMonth.binara, isAdhi: false),
  '2024-10-17': (month: PoyaMonth.vap, isAdhi: false),
  '2024-11-15': (month: PoyaMonth.il, isAdhi: false),
  '2024-12-14': (month: PoyaMonth.unduvap, isAdhi: false),
  // 2025
  '2025-01-13': (month: PoyaMonth.duruthu, isAdhi: false),
  '2025-02-12': (month: PoyaMonth.navam, isAdhi: false),
  '2025-03-13': (month: PoyaMonth.medin, isAdhi: false),
  '2025-04-12': (month: PoyaMonth.bak, isAdhi: false),
  '2025-05-12': (month: PoyaMonth.vesak, isAdhi: false),
  '2025-06-10': (month: PoyaMonth.poson, isAdhi: false),
  '2025-07-10': (month: PoyaMonth.esala, isAdhi: false),
  '2025-08-08': (month: PoyaMonth.nikini, isAdhi: false),
  '2025-09-07': (month: PoyaMonth.binara, isAdhi: false),
  '2025-10-06': (month: PoyaMonth.vap, isAdhi: false),
  '2025-11-05': (month: PoyaMonth.il, isAdhi: false),
  '2025-12-04': (month: PoyaMonth.unduvap, isAdhi: false),
  // 2026
  '2026-01-03': (month: PoyaMonth.duruthu, isAdhi: false),
  '2026-02-01': (month: PoyaMonth.navam, isAdhi: false),
  '2026-03-02': (month: PoyaMonth.medin, isAdhi: false),
  '2026-04-01': (month: PoyaMonth.bak, isAdhi: false),
  '2026-05-01': (month: PoyaMonth.vesak, isAdhi: false),
  '2026-05-30': (month: PoyaMonth.poson, isAdhi: true),
  '2026-06-29': (month: PoyaMonth.poson, isAdhi: false),
  '2026-07-29': (month: PoyaMonth.esala, isAdhi: false),
  '2026-08-27': (month: PoyaMonth.nikini, isAdhi: false),
  '2026-09-26': (month: PoyaMonth.binara, isAdhi: false),
  '2026-10-25': (month: PoyaMonth.vap, isAdhi: false),
  '2026-11-24': (month: PoyaMonth.il, isAdhi: false),
  '2026-12-23': (month: PoyaMonth.unduvap, isAdhi: false),
  // 2027
  '2027-01-22': (month: PoyaMonth.duruthu, isAdhi: false),
  '2027-02-20': (month: PoyaMonth.navam, isAdhi: false),
  '2027-03-21': (month: PoyaMonth.medin, isAdhi: false),
  '2027-04-20': (month: PoyaMonth.bak, isAdhi: false),
  '2027-05-20': (month: PoyaMonth.vesak, isAdhi: false),
  '2027-06-18': (month: PoyaMonth.poson, isAdhi: false),
  '2027-07-18': (month: PoyaMonth.esala, isAdhi: false),
  '2027-08-16': (month: PoyaMonth.nikini, isAdhi: false),
  '2027-09-15': (month: PoyaMonth.binara, isAdhi: false),
  '2027-10-15': (month: PoyaMonth.vap, isAdhi: false),
  '2027-11-13': (month: PoyaMonth.il, isAdhi: false),
  '2027-12-13': (month: PoyaMonth.unduvap, isAdhi: false),
};

/// The published entry for a full moon whose poya was computed to fall on
/// [computed], if one lies within two days of it.
///
/// Two days either way: the rule and the almanac disagree by a day at most
/// (KAN-96 measured), and neighbouring poyas are a month apart, so nothing
/// else can be that close.
///
/// [table] is the published table when the admin panel has sent one
/// (KAN-49), laid over this one; otherwise this one.
({DateTime date, PoyaMonth month, bool isAdhi})? officialPoyaNear(
  DateTime computed, {
  Map<String, ({PoyaMonth month, bool isAdhi})> table = officialPoyaDays,
}) {
  for (var offset = -2; offset <= 2; offset++) {
    final day = DateTime(computed.year, computed.month, computed.day + offset);
    final entry = table[_key(day)];
    if (entry != null) {
      return (date: day, month: entry.month, isAdhi: entry.isAdhi);
    }
  }
  return null;
}

String _key(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
