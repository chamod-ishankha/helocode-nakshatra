import 'package:flutter_test/flutter_test.dart';
import 'package:nakshatra/core/astro/calendar_models.dart';
import 'package:nakshatra/core/astro/official_poya_days.dart';
import 'package:nakshatra/core/astro/published_calendar.dart';
import 'package:nakshatra/core/astro/sri_lankan_calendar.dart';

/// The calendar the admin panel publishes (KAN-49 FRD §4.5, §8.5): checked
/// as strictly as the bundled table, and laid over it year by year.
void main() {
  Map<String, Object> asJson(Map<String, ({PoyaMonth month, bool isAdhi})> t) =>
      {
        for (final e in t.entries)
          e.key: {'month': e.value.month.name, 'isAdhi': e.value.isAdhi},
      };

  Map<String, Object?> deepavali({
    String? ta = 'தீபாவளி',
    String source = 'Gazette 2026/41',
  }) => {
    'year': 2026,
    'date': '2026-11-08',
    'kind': 'announced',
    'name': {'en': 'Deepavali', 'si': 'දීපවාලි', 'ta': ta},
    'source': source,
  };

  tearDown(() => SriLankanCalendar.usePublished(null));

  group('parsing', () {
    test('the bundled table passes as a published one', () {
      // The panel seeds its table from this file, so its first publish is
      // exactly this.
      final c = PublishedCalendar.fromJson(asJson(officialPoyaDays), const []);
      expect(c.poyaDays, officialPoyaDays);
    });

    test('a date a week off is refused', () {
      final t = Map.of(officialPoyaDays)
        ..remove('2026-10-25')
        ..['2026-11-02'] = (month: PoyaMonth.vap, isAdhi: false);
      expect(
        () => PublishedCalendar.fromJson(asJson(t), null),
        throwsFormatException,
      );
    });

    test('Adhi followed by the wrong month is refused', () {
      final t = Map.of(officialPoyaDays)
        ..['2026-06-29'] = (month: PoyaMonth.esala, isAdhi: false);
      expect(
        () => PublishedCalendar.fromJson(asJson(t), null),
        throwsFormatException,
      );
    });

    test('an unknown month or an impossible date is refused', () {
      expect(
        () => PublishedCalendar.fromJson({
          '2026-10-25': {'month': 'october'},
        }, null),
        throwsFormatException,
      );
      expect(
        () => PublishedCalendar.fromJson({
          '2026-02-30': {'month': 'navam'},
        }, null),
        throwsFormatException,
      );
    });

    test('an announced holiday needs all three names and a source', () {
      expect(
        PublishedCalendar.fromJson(null, [deepavali()]).festivals.single.en,
        'Deepavali',
      );
      expect(
        () => PublishedCalendar.fromJson(null, [deepavali(ta: ' ')]),
        throwsFormatException,
      );
      expect(
        () => PublishedCalendar.fromJson(null, [deepavali(source: '')]),
        throwsFormatException,
      );
    });
  });

  group('lunar months', () {
    test('an Adhi month counts as one either side', () {
      const vesak = (month: PoyaMonth.vesak, isAdhi: false);
      const adhiPoson = (month: PoyaMonth.poson, isAdhi: true);
      const poson = (month: PoyaMonth.poson, isAdhi: false);
      expect(PublishedCalendar.monthsBetween(vesak, adhiPoson), 1);
      expect(PublishedCalendar.monthsBetween(adhiPoson, poson), 1);
      expect(PublishedCalendar.monthsBetween(vesak, poson), 1);
      expect(
        PublishedCalendar.monthsBetween(
          (month: PoyaMonth.unduvap, isAdhi: false),
          (month: PoyaMonth.duruthu, isAdhi: false),
        ),
        1,
      );
    });
  });

  group('laid over the bundled table', () {
    test('a published year replaces that year whole, and only that year', () {
      // 2026 published with Vap removed: it must not survive from the
      // bundled table underneath.
      final y2026 = {
        for (final e in officialPoyaDays.entries)
          if (e.key.startsWith('2026-') && e.key != '2026-10-25')
            e.key: e.value,
      };
      final merged = PublishedCalendar(
        poyaDays: y2026,
        festivals: const [],
      ).over(officialPoyaDays);
      expect(merged.containsKey('2026-10-25'), isFalse);
      expect(merged['2027-10-15'], officialPoyaDays['2027-10-15']);
      expect(merged['2026-05-30'], (month: PoyaMonth.poson, isAdhi: true));
    });

    test('the official lookup reads the table it is given', () {
      final moved = {'2026-10-26': (month: PoyaMonth.vap, isAdhi: false)};
      expect(
        officialPoyaNear(DateTime(2026, 10, 26), table: moved)!.date,
        DateTime(2026, 10, 26),
      );
      expect(
        officialPoyaNear(DateTime(2026, 10, 26))!.date,
        DateTime(2026, 10, 25),
      );
    });
  });

  group('announced holidays', () {
    test('are named until published, then not', () {
      expect(SriLankanCalendar.unannouncedIn(2026), contains('Deepavali'));
      SriLankanCalendar.usePublished(
        PublishedCalendar.fromJson(null, [deepavali()]),
      );
      expect(
        SriLankanCalendar.unannouncedIn(2026),
        isNot(contains('Deepavali')),
      );
      expect(SriLankanCalendar.unannouncedIn(2026), contains('Eid al-Fitr'));
      // A date for 2026 says nothing about 2027.
      expect(SriLankanCalendar.unannouncedIn(2027), contains('Deepavali'));
    });

    test('become festivals of their own kind, carrying the source', () {
      final f = PublishedCalendar.fromJson(null, [
        deepavali(),
      ]).festivals.single.toFestival();
      expect(f.kind, FestivalKind.announced);
      expect(f.date, DateTime(2026, 11, 8));
      expect(f.ta, 'தீபாவளி');
      expect(f.note, contains('Gazette 2026/41'));
    });
  });
}
