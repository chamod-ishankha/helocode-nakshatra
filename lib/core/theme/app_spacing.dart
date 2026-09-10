/// The spacing scale (KAN-51).
///
/// Before this the app used thirteen different gaps — 2, 4, 6, 8, 10, 12, 16,
/// 20, 24, 28, 32, 40 and 48 — chosen a screen at a time. Most of them are one
/// of these seven; the rest were arrived at by nudging something until it
/// looked right, which is how a layout ends up impossible to adjust globally.
///
/// A four-point scale, because Material's own metrics are built on four and
/// mixing bases makes alignment look accidental.
///
/// ## The odd values still in the codebase
///
/// A few gaps are deliberately off-scale — an optical nudge inside a Row, a
/// hairline between two lines of the same sentence. Those were left alone
/// rather than rounded, because rounding them would change the layout for no
/// reason anybody asked for. Everything that already sat on the scale now says
/// so by name.
abstract final class AppSpacing {
  /// 4 — between two lines that belong to the same thought.
  static const double xs = 4;

  /// 8 — the default gap between elements in a column.
  static const double sm = 8;

  /// 12 — inside a card, between its parts.
  static const double md = 12;

  /// 16 — the screen margin, and between cards.
  static const double lg = 16;

  /// 24 — between sections of a screen.
  static const double xl = 24;

  /// 32 — above a closing note or a disclaimer.
  static const double xxl = 32;

  /// 48 — the gap that says "this is a different part of the page".
  static const double huge = 48;
}
