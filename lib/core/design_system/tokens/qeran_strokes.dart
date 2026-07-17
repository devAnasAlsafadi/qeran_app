/// Border / ring stroke widths. Kept deliberately thin so gold hairlines
/// read refined and premium, never heavy.
class QeranStrokes {
  const QeranStrokes._();

  /// Fine hairline — premium card borders (e.g. the Matches "earned" shell).
  /// A crisp 1dp line that frames without shouting.
  static const double hairline = 1.0;

  /// Standard emphasis stroke — avatar rings and control outlines.
  static const double regular = 1.5;

  /// Heavier emphasis stroke — the gold ring around a prominent hero disc
  /// (e.g. [QeranHeroBadge] on the daily-limit / photo-exchange surfaces).
  static const double emphasis = 2.5;
}
