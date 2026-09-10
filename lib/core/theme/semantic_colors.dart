import 'package:flutter/material.dart';

/// The colours that carry meaning, in the version that suits the surface they
/// are drawn on (KAN-51).
///
/// ## Why these cannot be plain constants
///
/// They were, and it could not have worked. A colour readable on this app's
/// near-black surface is not readable on its near-white one, and the gap is
/// not small — measured against the actual surfaces, the old single gold hit
/// 8.03:1 on dark and **2.26:1** on light, which is below the threshold for
/// body text by a wide margin. There is no gold that clears 4.5:1 on both;
/// the same is true of the red and the green. One constant for two surfaces
/// is a choice to be wrong on one of them.
///
/// So the values come in pairs and the theme hands over whichever fits. Every
/// one of the six clears 5:1 against its own surface, and most clear 6:1.
///
/// ## Colour is never the only signal, and cannot be
///
/// This is the constraint that shaped the whole thing. Red for inauspicious
/// and green for auspicious is the reading this audience expects, and roughly
/// one Sri Lankan man in twelve cannot see the difference between them.
///
/// That is not fixable by choosing better colours, and the arithmetic says so
/// rather than intuition: simulating protanopia and deuteranopia over the
/// whole red and green hue ranges, no pair exists that both clears 4.5:1
/// against the surface and stays 3:1 apart from the other. To separate red
/// from green under that deficiency you have to separate them by lightness,
/// and a red dark enough to manage it is no longer read as red.
///
/// So the rule is the other one WCAG gives: **never let colour be the only
/// thing carrying the meaning.** Every place that uses [inauspicious] or
/// [auspicious] must also carry a word, an icon or a shape that says the same
/// thing. The rāhu card names itself and says "avoid starting anything
/// important"; the inauspicious-period rows carry icons. Anything added later
/// has to do the same — a coloured dot on its own is not enough.
@immutable
class SemanticColors extends ThemeExtension<SemanticColors> {
  const SemanticColors({
    required this.accent,
    required this.inauspicious,
    required this.auspicious,
    required this.accentSurface,
    required this.inauspiciousSurface,
    required this.auspiciousSurface,
  });

  /// Gold. The brand's emphasis colour, used for values worth reading first.
  final Color accent;

  /// Rāhu kālaya, yamaganda, gulika — times to avoid.
  final Color inauspicious;

  /// Subha nekath — times that are favourable.
  final Color auspicious;

  /// The wash behind a card in each of those meanings.
  ///
  /// Explicit rather than the text colour at low alpha, which is what this
  /// used to be. The two want opposite things: text has to be dark enough to
  /// read on the surface, and a tint has to stay light enough to *be* a tint —
  /// so a 10% wash of the light theme's deep gold came out #F4ECE8, a warm
  /// grey with no gold left in it.
  ///
  /// Borders still take the text colour at ~40% alpha. A line is not a
  /// background; it wants the hue at strength.
  final Color accentSurface;
  final Color inauspiciousSurface;
  final Color auspiciousSurface;

  /// Contrast against `#FFFBFE`: gold 5.12:1, red 6.36:1, green 6.26:1.
  static const light = SemanticColors(
    accent: Color(0xFF8C6521),
    inauspicious: Color(0xFFB3271A),
    auspicious: Color(0xFF1F6B4F),
    accentSurface: Color(0xFFF7EEDC),
    inauspiciousSurface: Color(0xFFFBEBE8),
    auspiciousSurface: Color(0xFFE7F4EE),
  );

  /// Contrast against `#141218`: gold 8.03:1, red 6.12:1, green 8.58:1.
  static const dark = SemanticColors(
    accent: Color(0xFFD4A24C),
    inauspicious: Color(0xFFE8705E),
    auspicious: Color(0xFF4FC49A),
    accentSurface: Color(0xFF241E12),
    inauspiciousSurface: Color(0xFF2A1A17),
    auspiciousSurface: Color(0xFF12241D),
  );

  static SemanticColors of(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  @override
  SemanticColors copyWith({
    Color? accent,
    Color? inauspicious,
    Color? auspicious,
    Color? accentSurface,
    Color? inauspiciousSurface,
    Color? auspiciousSurface,
  }) => SemanticColors(
    accent: accent ?? this.accent,
    inauspicious: inauspicious ?? this.inauspicious,
    auspicious: auspicious ?? this.auspicious,
    accentSurface: accentSurface ?? this.accentSurface,
    inauspiciousSurface: inauspiciousSurface ?? this.inauspiciousSurface,
    auspiciousSurface: auspiciousSurface ?? this.auspiciousSurface,
  );

  @override
  SemanticColors lerp(covariant SemanticColors? other, double t) {
    if (other == null) return this;
    return SemanticColors(
      accent: Color.lerp(accent, other.accent, t)!,
      inauspicious: Color.lerp(inauspicious, other.inauspicious, t)!,
      auspicious: Color.lerp(auspicious, other.auspicious, t)!,
      accentSurface: Color.lerp(accentSurface, other.accentSurface, t)!,
      inauspiciousSurface: Color.lerp(
        inauspiciousSurface,
        other.inauspiciousSurface,
        t,
      )!,
      auspiciousSurface: Color.lerp(
        auspiciousSurface,
        other.auspiciousSurface,
        t,
      )!,
    );
  }
}

extension SemanticColorsOf on BuildContext {
  /// The meaning-carrying colours for the theme in force here.
  ///
  /// Falls back to the light set rather than throwing. A missing extension is
  /// a wiring mistake, and the right punishment for it is a slightly wrong
  /// colour on one screen, not a red error box over the almanac.
  SemanticColors get semantic =>
      Theme.of(this).extension<SemanticColors>() ??
      SemanticColors.of(Theme.of(this).brightness);
}
