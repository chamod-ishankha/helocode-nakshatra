import 'models.dart';

/// How well placed a graha is in the sign it occupies.
enum Dignity {
  /// In the sign it rules.
  own,

  /// In its sign of exaltation — strongest.
  exalted,

  /// Opposite its exaltation — weakest.
  debilitated,

  /// Nothing special. Most placements are this.
  neutral,
}

/// Sign dignity for the seven graha (KAN-53).
///
/// Only own, exalted and debilitated are given. These three are agreed on
/// everywhere; the finer grades — mūlatrikoṇa, friendly and inimical signs —
/// vary by school, and stating a contested judgement as fact on a detail sheet
/// would be worse than staying quiet.
///
/// **Rāhu and Ketu are deliberately absent.** They rule no sign, and different
/// traditions place their exaltation in different signs — some say Taurus and
/// Scorpio, others Gemini and Sagittarius, others that the nodes have no
/// dignity at all. [of] returns null for them rather than picking a side.
abstract final class GrahaDignity {
  static const Map<Graha, List<Rasi>> _own = {
    Graha.sun: [Rasi.simha],
    Graha.moon: [Rasi.karka],
    Graha.mars: [Rasi.mesha, Rasi.vrischika],
    Graha.mercury: [Rasi.mithuna, Rasi.kanya],
    Graha.jupiter: [Rasi.dhanu, Rasi.meena],
    Graha.venus: [Rasi.vrishabha, Rasi.tula],
    Graha.saturn: [Rasi.makara, Rasi.kumbha],
  };

  /// Sign of exaltation, and the degree within it where exaltation is exact.
  ///
  /// The degree is not used to grade strength here — it is shown so a reader
  /// can see how near the peak a placement sits, which is the thing a printed
  /// chart never tells them.
  static const Map<Graha, (Rasi, int)> _exalted = {
    Graha.sun: (Rasi.mesha, 10),
    Graha.moon: (Rasi.vrishabha, 3),
    Graha.mars: (Rasi.makara, 28),
    // Mercury is the only graha exalted in a sign it also rules.
    Graha.mercury: (Rasi.kanya, 15),
    Graha.jupiter: (Rasi.karka, 5),
    Graha.venus: (Rasi.meena, 27),
    Graha.saturn: (Rasi.tula, 20),
  };

  /// Debilitation is always the sign opposite exaltation.
  static Rasi? debilitationSign(Graha graha) {
    final exalted = _exalted[graha];
    if (exalted == null) return null;
    return Rasi.values[(exalted.$1.index + 6) % 12];
  }

  static Rasi? exaltationSign(Graha graha) => _exalted[graha]?.$1;

  /// The degree of exact exaltation, or null for the nodes.
  static int? exaltationDegree(Graha graha) => _exalted[graha]?.$2;

  static List<Rasi> ownSigns(Graha graha) => _own[graha] ?? const [];

  /// The dignity of [graha] in [rasi], or null where no judgement is offered.
  static Dignity? of(Graha graha, Rasi rasi) {
    if (!_exalted.containsKey(graha)) return null;

    // Exaltation is checked before rulership so Mercury in Virgo reads as
    // exalted, which is the stronger and more interesting statement.
    if (exaltationSign(graha) == rasi) return Dignity.exalted;
    if (debilitationSign(graha) == rasi) return Dignity.debilitated;
    if (ownSigns(graha).contains(rasi)) return Dignity.own;
    return Dignity.neutral;
  }
}
