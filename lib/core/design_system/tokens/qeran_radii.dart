import 'package:flutter/material.dart';

/// Six semantic radii — collapses the 30+ ad-hoc values in the codebase.
class QeranRadii {
  const QeranRadii._();

  /// Smallest rounding — tiny controls like the oath agreement checkbox.
  static const double xs = 6.0;
  static const double chip = 999.0;
  static const double control = 14.0;
  static const double card = 20.0;
  static const double panel = 28.0;
  static const double dome = 36.0;

  static const BorderRadius xsR = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(chip));
  static const BorderRadius controlR = BorderRadius.all(
    Radius.circular(control),
  );
  static const BorderRadius cardR = BorderRadius.all(Radius.circular(card));
  static const BorderRadius panelR = BorderRadius.all(Radius.circular(panel));

  /// Top-only dome — for bottom sheets and image-into-content overlap.
  static const BorderRadius domeTop = BorderRadius.only(
    topLeft: Radius.circular(dome),
    topRight: Radius.circular(dome),
  );
}
