import 'package:timezone/timezone.dart' as tz;

/// The arithmetic behind the date and time wheels (KAN-82).
///
/// Kept out of the widgets because every rule here produces a plausible wrong
/// answer rather than an obvious one: a 31st of February that quietly becomes
/// the 3rd of March, a 12 PM that becomes midnight, a birth date in the
/// future. Any of them gives a confidently wrong chart.
abstract final class BirthWheels {
  /// The ephemeris is validated from here on; the old date dialog used the
  /// same floor, and a birth before it is refused rather than miscalculated.
  static final DateTime earliest = DateTime(1900);

  static int daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  /// The years the year wheel offers, oldest first.
  static List<int> years(DateTime today) => [
    for (var y = earliest.year; y <= today.year; y++) y,
  ];

  /// Months that exist and are not in the future, for [year].
  static int monthCount(int year, DateTime today) =>
      year == today.year ? today.month : 12;

  /// Days that exist and are not in the future, for [year] and [month].
  static int dayCount(int year, int month, DateTime today) =>
      year == today.year && month == today.month
      ? today.day
      : daysInMonth(year, month);

  /// What three wheels say, made into a real date that can have been a birth.
  ///
  /// Each wheel moves on its own, so the combination can be impossible: the
  /// 31st with February, or a month later this year. The day is held to the
  /// month rather than overflowing into the next one — `DateTime(1995, 2, 31)`
  /// is the 3rd of March, which is a different nakṣatra and nothing on screen
  /// would say so.
  static DateTime settle({
    required int year,
    required int month,
    required int day,
    required DateTime today,
  }) {
    final y = year.clamp(earliest.year, today.year);
    final m = month.clamp(1, monthCount(y, today));
    final d = day.clamp(1, dayCount(y, m, today));
    return DateTime(y, m, d);
  }

  /// The three time wheels — 1..12, 0..59, morning or afternoon — as a time of
  /// day.
  ///
  /// 12 is the trap: 12 AM is midnight, 12 PM is noon, and both of the obvious
  /// formulas get one of them wrong.
  static Duration timeOf({
    required int hour12,
    required int minute,
    required bool pm,
  }) => Duration(hours: hour12 % 12 + (pm ? 12 : 0), minutes: minute);

  /// The reverse, to put an existing birth time back on the wheels.
  static ({int hour12, int minute, bool pm}) wheelsFor(Duration time) {
    final hour = time.inHours % 24;
    return (
      hour12: hour % 12 == 0 ? 12 : hour % 12,
      minute: time.inMinutes % 60,
      pm: hour >= 12,
    );
  }

  /// The offset from UTC that [zone] had at that local date and time, or null
  /// if the zone is unknown or the database is not loaded.
  ///
  /// From the timezone database, never a fixed offset: Sri Lanka was +6:30
  /// and then +6:00 between 1996 and 2006, and a chart from that decade read
  /// at +5:30 has its lagna half a sign out.
  static Duration? offsetAt(String zone, DateTime date, Duration time) {
    try {
      final location = tz.getLocation(zone);
      return tz.TZDateTime(
        location,
        date.year,
        date.month,
        date.day,
        time.inHours % 24,
        time.inMinutes % 60,
      ).timeZoneOffset;
    } on Object {
      return null;
    }
  }

  /// "UTC+5:30", "UTC−3", "UTC". The minus is the real minus sign.
  static String offsetLabel(Duration offset) {
    if (offset == Duration.zero) return 'UTC';
    final minutes = offset.inMinutes.abs();
    final h = minutes ~/ 60, m = minutes % 60;
    final sign = offset.isNegative ? '−' : '+';
    return m == 0 ? 'UTC$sign$h' : 'UTC$sign$h:${m.toString().padLeft(2, '0')}';
  }
}
