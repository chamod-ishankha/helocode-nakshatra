import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/astro/dasha.dart';
import 'package:nakshatra/core/astro/models.dart';

/// Vimśottarī daśā (KAN-18).
///
/// Pure arithmetic on a chart, so it runs on the host with no ephemeris. The
/// chart is built by hand: what matters to a daśā is the Moon's longitude and
/// the birth instant, and fabricating those directly lets a case be reasoned
/// about on paper.
void main() {
  /// Julian day for 2000-01-01 12:00 UT, the J2000 epoch.
  const j2000 = 2451545.0;

  BirthChart chartWithMoonAt(double longitude, {double jd = j2000}) {
    GrahaPosition at(Graha g, double lon) => GrahaPosition(
      graha: g,
      longitude: lon,
      latitude: 0,
      speed: 1,
      house: 1,
    );

    return BirthChart(
      julianDayUt: jd,
      ascendant: 0,
      midheaven: 0,
      ayanamsa: 23.85,
      positions: {
        for (final g in Graha.values) g: at(g, 0),
        Graha.moon: at(Graha.moon, longitude),
      },
    );
  }

  group('the cycle itself', () {
    test('the nine lords account for exactly 120 years', () {
      final total = Vimshottari.cycle.fold<int>(0, (sum, e) => sum + e.$2);
      expect(total, Vimshottari.totalYears);
      expect(Vimshottari.cycle.length, 9);
    });

    test('the order is the traditional one', () {
      // Not alphabetical and not the weekday order — sub-periods run in this
      // sequence too, so getting it wrong misplaces every antardaśā.
      expect(Vimshottari.lords, [
        Graha.ketu,
        Graha.venus,
        Graha.sun,
        Graha.moon,
        Graha.mars,
        Graha.rahu,
        Graha.jupiter,
        Graha.saturn,
        Graha.mercury,
      ]);
    });

    test('each lord has its canonical allocation', () {
      expect(Vimshottari.yearsOf(Graha.ketu), 7);
      expect(Vimshottari.yearsOf(Graha.venus), 20);
      expect(Vimshottari.yearsOf(Graha.sun), 6);
      expect(Vimshottari.yearsOf(Graha.moon), 10);
      expect(Vimshottari.yearsOf(Graha.mars), 7);
      expect(Vimshottari.yearsOf(Graha.rahu), 18);
      expect(Vimshottari.yearsOf(Graha.jupiter), 16);
      expect(Vimshottari.yearsOf(Graha.saturn), 19);
      expect(Vimshottari.yearsOf(Graha.mercury), 17);
    });
  });

  group('nakṣatra lords', () {
    test('the first nine run Ketu to Mercury', () {
      expect(Vimshottari.lordOf(Nakshatra.ashwini), Graha.ketu);
      expect(Vimshottari.lordOf(Nakshatra.bharani), Graha.venus);
      expect(Vimshottari.lordOf(Nakshatra.krittika), Graha.sun);
      expect(Vimshottari.lordOf(Nakshatra.rohini), Graha.moon);
      expect(Vimshottari.lordOf(Nakshatra.mrigashira), Graha.mars);
      expect(Vimshottari.lordOf(Nakshatra.ardra), Graha.rahu);
      expect(Vimshottari.lordOf(Nakshatra.punarvasu), Graha.jupiter);
      expect(Vimshottari.lordOf(Nakshatra.pushya), Graha.saturn);
      expect(Vimshottari.lordOf(Nakshatra.ashlesha), Graha.mercury);
    });

    test('the pattern repeats every nine', () {
      // Maghā and Mūla restart the sequence at Ketu; Revatī closes it.
      expect(Vimshottari.lordOf(Nakshatra.magha), Graha.ketu);
      expect(Vimshottari.lordOf(Nakshatra.mula), Graha.ketu);
      expect(Vimshottari.lordOf(Nakshatra.jyeshtha), Graha.mercury);
      expect(Vimshottari.lordOf(Nakshatra.revati), Graha.mercury);
    });

    test('every nakṣatra maps to one of the nine', () {
      for (final n in Nakshatra.values) {
        expect(Vimshottari.lords, contains(Vimshottari.lordOf(n)));
      }
    });
  });

  group('balance at birth', () {
    test('a Moon at the very start of a nakṣatra owes the full period', () {
      // 0° is the first instant of Aśvinī, so no part of Ketu is spent.
      final balance = Vimshottari.balanceAtBirth(chartWithMoonAt(0));
      expect(
        balance.inDays,
        closeTo(7 * Vimshottari.daysPerYear, 1),
      );
    });

    test('a Moon halfway through a nakṣatra owes half the period', () {
      // Half of Bharaṇī: Venus rules 20 years, so 10 remain.
      final half = Nakshatra.span * 1.5;
      final balance = Vimshottari.balanceAtBirth(chartWithMoonAt(half));
      expect(
        balance.inDays,
        closeTo(10 * Vimshottari.daysPerYear, 1),
      );
    });

    test('a Moon at the very end of a nakṣatra owes almost nothing', () {
      final nearlyDone = Nakshatra.span * 0.9999;
      final balance = Vimshottari.balanceAtBirth(chartWithMoonAt(nearlyDone));
      expect(balance.inDays, lessThan(1));
      expect(balance.isNegative, isFalse);
    });
  });

  group('the mahādaśā sequence', () {
    test('starts with the lord of the birth nakṣatra', () {
      final timeline = Vimshottari.forChart(chartWithMoonAt(Nakshatra.span * 5.5));
      // Sixth nakṣatra is Ārdrā, ruled by Rahu.
      expect(timeline.first.lord, Graha.rahu);
      expect(timeline.first.level, DashaLevel.maha);
    });

    test('runs all nine lords in order from there', () {
      final timeline = Vimshottari.forChart(chartWithMoonAt(0));
      expect(timeline.map((p) => p.lord).toList(), Vimshottari.lords);
    });

    test('periods tile with no gap and no overlap', () {
      final timeline = Vimshottari.forChart(chartWithMoonAt(Nakshatra.span * 3.3));

      for (var i = 1; i < timeline.length; i++) {
        expect(
          timeline[i].start,
          timeline[i - 1].end,
          reason: 'gap or overlap between period ${i - 1} and $i',
        );
      }
    });

    test('nothing is dated before birth', () {
      final birth = utcFromJulianDay(j2000);
      final timeline = Vimshottari.forChart(chartWithMoonAt(Nakshatra.span * 2.7));

      for (final maha in timeline) {
        expect(maha.start.isBefore(birth), isFalse, reason: '$maha');
        for (final antara in maha.children) {
          expect(antara.start.isBefore(birth), isFalse, reason: '$antara');
        }
      }
      expect(timeline.first.start, birth);
    });

    test('the first period is shortened to the balance', () {
      final timeline = Vimshottari.forChart(chartWithMoonAt(Nakshatra.span * 1.5));
      final first = timeline.first;

      expect(first.lord, Graha.venus);
      // Venus rules 20 years but half of Bharaṇī is already spent.
      expect(first.duration.inDays, closeTo(10 * Vimshottari.daysPerYear, 1));
    });

    test('every later period gets its full allocation', () {
      final timeline = Vimshottari.forChart(chartWithMoonAt(Nakshatra.span * 1.5));

      for (final maha in timeline.skip(1)) {
        expect(
          maha.duration.inDays,
          closeTo(Vimshottari.yearsOf(maha.lord) * Vimshottari.daysPerYear, 1),
          reason: '${maha.lord.en} was not its full length',
        );
      }
    });
  });

  group('antardaśā', () {
    test('a mahādaśā opens with a sub-period of its own lord', () {
      final timeline = Vimshottari.forChart(chartWithMoonAt(0));
      final venus = timeline[1];

      expect(venus.lord, Graha.venus);
      expect(venus.children.first.lord, Graha.venus);
      expect(venus.children.map((c) => c.lord).toList(), [
        Graha.venus,
        Graha.sun,
        Graha.moon,
        Graha.mars,
        Graha.rahu,
        Graha.jupiter,
        Graha.saturn,
        Graha.mercury,
        Graha.ketu,
      ]);
    });

    test('sub-periods fill their parent exactly', () {
      final timeline = Vimshottari.forChart(chartWithMoonAt(0));

      for (final maha in timeline) {
        expect(maha.children.first.start, maha.start);
        expect(maha.children.last.end, maha.end);
      }
    });

    test('a sub-period takes its lord\'s share of the parent', () {
      final timeline = Vimshottari.forChart(chartWithMoonAt(0));
      final ketu = timeline.first;

      // Ketu mahādaśā is 7 years; Venus takes 20/120 of it, so 1.1667 years.
      final venusInKetu =
          ketu.children.firstWhere((c) => c.lord == Graha.venus);
      expect(
        venusInKetu.duration.inHours / 24,
        closeTo(7 * 20 / 120 * Vimshottari.daysPerYear, 1),
      );
    });

    test('the first mahādaśā\'s sub-periods are measured from its true start',
        () {
      // The mistake this guards: dividing the *balance* into nine
      // sub-periods. It looks right — the numbers still fill the visible
      // span — but every boundary in the first period lands in the wrong
      // place, and the first period is the one a new user actually reads.
      final timeline =
          Vimshottari.forChart(chartWithMoonAt(Nakshatra.span * 1.5));
      final first = timeline.first;

      // Half of Venus's 20 years is spent, so the sub-periods covering the
      // first ten years are gone. Venus/Venus (20/120 of 20 years = 3.33y)
      // and Venus/Sun and Venus/Moon all ended before birth.
      expect(first.children.first.lord, isNot(Graha.venus),
          reason: 'sub-periods were divided from the balance, not the whole');

      // Whichever sub-period contains birth is truncated to start at it.
      expect(first.children.first.start, first.start);
    });
  });

  group('pratyantardaśā', () {
    test('a third level is generated when asked for', () {
      final timeline = Vimshottari.forChart(chartWithMoonAt(0));
      final antara = timeline.first.children.first;

      expect(antara.level, DashaLevel.antara);
      expect(antara.children, isNotEmpty);
      expect(antara.children.first.level, DashaLevel.pratyantara);
      expect(antara.children.first.lord, antara.lord);
    });

    test('depth 1 and 2 stop where told', () {
      final maha = Vimshottari.forChart(chartWithMoonAt(0), depth: 1);
      expect(maha.first.children, isEmpty);

      final two = Vimshottari.forChart(chartWithMoonAt(0), depth: 2);
      expect(two.first.children, isNotEmpty);
      expect(two.first.children.first.children, isEmpty);
    });

    test('the third level fills its parent exactly', () {
      final timeline = Vimshottari.forChart(chartWithMoonAt(0));
      final antara = timeline[2].children[3];

      expect(antara.children.first.start, antara.start);
      expect(antara.children.last.end, antara.end);
    });
  });

  group('finding the running period', () {
    test('birth itself falls in the first period', () {
      final birth = utcFromJulianDay(j2000);
      final timeline = Vimshottari.forChart(chartWithMoonAt(0));

      final snapshot = Vimshottari.at(timeline, birth);
      expect(snapshot, isNotNull);
      expect(snapshot!.maha.lord, Graha.ketu);
      expect(snapshot.antara, isNotNull);
      expect(snapshot.pratyantara, isNotNull);
    });

    test('a date decades later lands in the right mahādaśā', () {
      final birth = utcFromJulianDay(j2000);
      final timeline = Vimshottari.forChart(chartWithMoonAt(0));

      // Ketu 7 + Venus 20 = 27 years, so year 30 is inside the Sun period.
      final later = birth.add(
        Duration(days: (30 * Vimshottari.daysPerYear).round()),
      );
      expect(Vimshottari.at(timeline, later)!.maha.lord, Graha.sun);
    });

    test('before birth and past the cycle there is nothing', () {
      final birth = utcFromJulianDay(j2000);
      final timeline = Vimshottari.forChart(chartWithMoonAt(0));

      expect(
        Vimshottari.at(timeline, birth.subtract(const Duration(days: 1))),
        isNull,
      );
      expect(
        Vimshottari.at(
          timeline,
          birth.add(const Duration(days: 121 * 366)),
        ),
        isNull,
      );
    });

    test('the label names all three levels', () {
      final birth = utcFromJulianDay(j2000);
      final timeline = Vimshottari.forChart(chartWithMoonAt(0));

      final snapshot = Vimshottari.at(timeline, birth)!;
      expect(snapshot.label, 'Ketu / Ketu / Ketu');
    });

    test('a local-time instant is matched correctly', () {
      // Boundaries are UTC; a caller passing a Colombo DateTime must not be
      // silently five and a half hours out.
      final birth = utcFromJulianDay(j2000);
      final timeline = Vimshottari.forChart(chartWithMoonAt(0));

      final local = birth.add(const Duration(days: 400)).toLocal();
      expect(Vimshottari.at(timeline, local), isNotNull);
    });
  });

  group('Julian day conversion', () {
    test('J2000 is 2000-01-01 12:00 UT', () {
      final t = utcFromJulianDay(j2000);
      expect(t.isUtc, isTrue);
      expect(t.year, 2000);
      expect(t.month, 1);
      expect(t.day, 1);
      expect(t.hour, 12);
      expect(t.minute, 0);
    });

    test('the Unix epoch round-trips', () {
      final t = utcFromJulianDay(2440587.5);
      expect(t.millisecondsSinceEpoch, 0);
    });

    test('half a day really is twelve hours', () {
      final a = utcFromJulianDay(j2000);
      final b = utcFromJulianDay(j2000 + 0.5);
      expect(b.difference(a), const Duration(hours: 12));
    });
  });
}
