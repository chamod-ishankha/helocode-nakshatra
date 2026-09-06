import 'models.dart';
import 'nekath.dart';
import 'panchanga_models.dart';

/// What the user wants to start.
///
/// The list is deliberately short and concrete. A muhūrta table can be
/// subdivided almost without limit, and offering fifty activities would imply
/// a precision the underlying rules do not have.
enum Activity {
  travel,
  workOrStudy,
  business,
  marriage,
  houseEntry,
  vehicle,
}

/// The sevenfold classification of the nakṣatras by character.
///
/// This is the backbone of activity matching: each activity favours certain
/// classes and is warned against others.
enum NakshatraClass {
  /// Fixed. Suits anything meant to last.
  dhruva,

  /// Movable. Suits journeys and vehicles.
  chara,

  /// Fierce. Suits confrontation and demolition, little else.
  ugra,

  /// Mixed. Neither favoured nor warned against.
  mishra,

  /// Swift. Suits trade, learning and anything to be done quickly.
  kshipra,

  /// Tender. Suits marriage, friendship and the arts.
  mridu,

  /// Sharp. Suits surgery and separation.
  tikshna,
}

/// The fivefold grouping of tithis by position in the fortnight.
enum TithiGroup {
  nanda,
  bhadra,
  jaya,

  /// The 4th, 9th and 14th. Traditionally avoided for starting anything.
  rikta,
  purna,
}

/// Why a window scored as it did.
enum MuhurtaReason {
  nakshatraFavours,
  nakshatraNeutral,
  nakshatraWarnsAgainst,
  tithiRikta,
  tithiFavourable,
  yogaInauspicious,
  karanaVishti,
  varaUnfavourable,
  varaFavourable,
  shortenedByChange,
}

/// A stretch of time with a score and the reasons behind it.
class MuhurtaWindow {
  const MuhurtaWindow({
    required this.start,
    required this.end,
    required this.score,
    required this.reasons,
  });

  final DateTime start;
  final DateTime end;

  /// 0 to 100. Not a probability of anything — a ranking, so the best of a
  /// given day can be put first.
  final int score;

  final List<MuhurtaReason> reasons;

  Duration get duration => end.difference(start);

  bool get isRecommended => score >= 60;
}

/// Nekath / śubha muhūrta — choosing a time to begin something (KAN-22).
///
/// ## What this does
///
/// Takes a day's pañcāṅga, removes the periods nobody starts anything in
/// (rāhu kālaya, yamaganda, gulika), and scores what is left against the
/// activity in hand using the classical factors: the nakṣatra's character,
/// the tithi's group, the yoga, the karaṇa and the weekday.
///
/// ## The sunrise convention, and why windows get cut short
///
/// A day's pañcāṅga is the one standing at sunrise; that is the tradition and
/// it is what [Panchangam] computes. But a tithi or nakṣatra can end at two in
/// the afternoon, and after that the score no longer describes the sky.
///
/// Rather than quietly scoring a whole day on values that stopped applying,
/// windows are **truncated at the first boundary where a scored element
/// changes**, and the window carries [MuhurtaReason.shortenedByChange] to say
/// so. That is honest about the limit of what a day-level pañcāṅga can tell
/// you, at the cost of shorter recommendations on days when things move early.
///
/// ## What is left out
///
/// No lagna-based muhūrta, no choghadiya, no hora, no tārā-bala or candra-bala
/// against the user's own chart. Those need either the querent's birth data or
/// a second layer of rules, and several are stated differently by different
/// schools. A short answer that is right beats a long one that is guessed.
abstract final class Muhurta {
  /// The sevenfold class of each nakṣatra.
  static NakshatraClass classOf(Nakshatra n) => switch (n) {
    Nakshatra.rohini ||
    Nakshatra.uttaraPhalguni ||
    Nakshatra.uttaraAshadha ||
    Nakshatra.uttaraBhadrapada => NakshatraClass.dhruva,

    Nakshatra.punarvasu ||
    Nakshatra.swati ||
    Nakshatra.shravana ||
    Nakshatra.dhanishta ||
    Nakshatra.shatabhisha => NakshatraClass.chara,

    Nakshatra.bharani ||
    Nakshatra.magha ||
    Nakshatra.purvaPhalguni ||
    Nakshatra.purvaAshadha ||
    Nakshatra.purvaBhadrapada => NakshatraClass.ugra,

    Nakshatra.krittika || Nakshatra.vishakha => NakshatraClass.mishra,

    Nakshatra.ashwini ||
    Nakshatra.pushya ||
    Nakshatra.hasta => NakshatraClass.kshipra,

    Nakshatra.mrigashira ||
    Nakshatra.chitra ||
    Nakshatra.anuradha ||
    Nakshatra.revati => NakshatraClass.mridu,

    Nakshatra.ardra ||
    Nakshatra.ashlesha ||
    Nakshatra.jyeshtha ||
    Nakshatra.mula => NakshatraClass.tikshna,
  };

  /// Tithi group, from the position in the fortnight.
  ///
  /// The pattern repeats every five, so it is computed rather than tabled —
  /// the 15th (pūrṇimā or amāvāsyā) lands on pūrṇa, which is correct.
  static TithiGroup groupOf(Tithi t) => TithiGroup.values[t.index % 5];

  /// Classes each activity is helped by.
  static const Map<Activity, Set<NakshatraClass>> favours = {
    Activity.travel: {NakshatraClass.chara, NakshatraClass.kshipra,
        NakshatraClass.mridu},
    Activity.workOrStudy: {NakshatraClass.kshipra, NakshatraClass.dhruva,
        NakshatraClass.mridu},
    Activity.business: {NakshatraClass.kshipra, NakshatraClass.chara,
        NakshatraClass.dhruva},
    Activity.marriage: {NakshatraClass.mridu, NakshatraClass.dhruva},
    Activity.houseEntry: {NakshatraClass.dhruva, NakshatraClass.mridu},
    Activity.vehicle: {NakshatraClass.chara, NakshatraClass.kshipra,
        NakshatraClass.mridu},
  };

  /// Classes each activity is warned against.
  ///
  /// Ugra and tīkṣṇa warn against every one of these — they suit demolition
  /// and surgery, not beginnings. Marriage and house entry additionally avoid
  /// the movable nakṣatras, since neither is meant to be temporary.
  static const Map<Activity, Set<NakshatraClass>> warnsAgainst = {
    Activity.travel: {NakshatraClass.ugra, NakshatraClass.tikshna},
    Activity.workOrStudy: {NakshatraClass.ugra, NakshatraClass.tikshna},
    Activity.business: {NakshatraClass.ugra, NakshatraClass.tikshna},
    Activity.marriage: {NakshatraClass.ugra, NakshatraClass.tikshna,
        NakshatraClass.chara},
    Activity.houseEntry: {NakshatraClass.ugra, NakshatraClass.tikshna,
        NakshatraClass.chara},
    Activity.vehicle: {NakshatraClass.ugra, NakshatraClass.tikshna},
  };

  /// The nine yogas held to spoil a beginning.
  static const Set<Yoga> inauspiciousYogas = {
    Yoga.vishkambha,
    Yoga.atiganda,
    Yoga.shula,
    Yoga.ganda,
    Yoga.vyaghata,
    Yoga.vajra,
    Yoga.vyatipata,
    Yoga.parigha,
    Yoga.vaidhriti,
  };

  /// Weekdays generally avoided for starting something of consequence.
  ///
  /// Tuesday belongs to Mars and Saturday to Saturn. This is the weakest of
  /// the factors used here and carries the smallest weight, because plenty of
  /// practice ignores it when everything else agrees.
  static const Set<Vara> unfavourableVaras = {Vara.mangala, Vara.shani};

  /// Ranked windows for [activity] on the day [panchanga] describes.
  ///
  /// Ordered best first. An empty list means the whole of daylight was taken
  /// up by inauspicious periods, which does happen on short days.
  static List<MuhurtaWindow> forActivity(
    Panchanga panchanga,
    Activity activity,
  ) {
    final cutoff = _firstChange(panchanga);

    final windows = <MuhurtaWindow>[];
    for (final clear in Nekath.auspiciousWindows(panchanga)) {
      // Nothing after the first element change is described by this score.
      final end = (cutoff != null && cutoff.isBefore(clear.end))
          ? cutoff
          : clear.end;
      if (!end.isAfter(clear.start)) continue;

      final (score, reasons) = _score(
        panchanga,
        activity,
        truncated: end != clear.end,
      );

      windows.add(
        MuhurtaWindow(
          start: clear.start,
          end: end,
          score: score,
          reasons: reasons,
        ),
      );
    }

    // Equal scores are broken by length: given the same quality, a longer
    // window is more use than a shorter one.
    windows.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      return byScore != 0 ? byScore : b.duration.compareTo(a.duration);
    });
    return windows;
  }

  /// The earliest moment a scored element stops applying.
  static DateTime? _firstChange(Panchanga p) {
    final ends = [
      p.tithi.endsAt,
      p.nakshatra.endsAt,
      p.yoga.endsAt,
      p.karana.endsAt,
    ].whereType<DateTime>().toList();

    if (ends.isEmpty) return null;
    ends.sort();
    return ends.first;
  }

  /// Scores the day for an activity.
  ///
  /// Starts from a neutral 50 and moves from there, so a day with nothing
  /// notable about it reads as "unremarkable" rather than as good or bad.
  static (int, List<MuhurtaReason>) _score(
    Panchanga p,
    Activity activity, {
    required bool truncated,
  }) {
    var score = 50;
    final reasons = <MuhurtaReason>[];

    // The nakṣatra carries the most weight: it is the factor muhūrta is
    // usually chosen on.
    final klass = classOf(p.nakshatra.value);
    if (favours[activity]!.contains(klass)) {
      score += 25;
      reasons.add(MuhurtaReason.nakshatraFavours);
    } else if (warnsAgainst[activity]!.contains(klass)) {
      score -= 30;
      reasons.add(MuhurtaReason.nakshatraWarnsAgainst);
    } else {
      reasons.add(MuhurtaReason.nakshatraNeutral);
    }

    final group = groupOf(p.tithi.value);
    if (group == TithiGroup.rikta) {
      score -= 20;
      reasons.add(MuhurtaReason.tithiRikta);
    } else if (group == TithiGroup.jaya || group == TithiGroup.purna) {
      score += 10;
      reasons.add(MuhurtaReason.tithiFavourable);
    }

    if (inauspiciousYogas.contains(p.yoga.value)) {
      score -= 15;
      reasons.add(MuhurtaReason.yogaInauspicious);
    }

    if (p.karana.value.isInauspicious) {
      score -= 20;
      reasons.add(MuhurtaReason.karanaVishti);
    }

    if (unfavourableVaras.contains(p.vara)) {
      score -= 10;
      reasons.add(MuhurtaReason.varaUnfavourable);
    } else {
      score += 5;
      reasons.add(MuhurtaReason.varaFavourable);
    }

    if (truncated) reasons.add(MuhurtaReason.shortenedByChange);

    return (score.clamp(0, 100), reasons);
  }
}
