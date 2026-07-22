import 'package:flutter/material.dart';

import 'qeran_colors.dart';

/// Typography roles for Qeran.
///
/// Font family is intentionally NOT hardcoded — the active theme's
/// [TextTheme] resolves NotoKufiArabic (Arabic) or Montserrat (Latin)
/// based on locale. Numeric styles force Montserrat for tabular figures
/// (Arabic Kufi has no tabular numerals).
///
/// Every style sets `letterSpacing: 0` explicitly because Material 3's
/// defaults inject non-zero spacing that breaks Arabic connected script
/// (letters appear separated instead of joined).
class QeranTypography {
  const QeranTypography._();

  static const String _montserrat = 'Montserrat';

  static const TextStyle displayLg = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 1.15,
    letterSpacing: 0,
    color: QeranColors.inkStrong,
  );

  static const TextStyle displaySm = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    height: 1.20,
    letterSpacing: 0,
    color: QeranColors.inkStrong,
  );

  static const TextStyle headline = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: 0,
    color: QeranColors.inkStrong,
  );

  static const TextStyle title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.30,
    letterSpacing: 0,
    color: QeranColors.inkStrong,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.40,
    letterSpacing: 0,
    color: QeranColors.inkStrong,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.55,
    letterSpacing: 0,
    color: QeranColors.inkBody,
  );

  static const TextStyle bodySm = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.55,
    letterSpacing: 0,
    color: QeranColors.inkBody,
  );

  static const TextStyle label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    height: 1.20,
    letterSpacing: 0,
    color: QeranColors.inkStrong,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.40,
    letterSpacing: 0,
    color: QeranColors.inkMuted,
  );

  /// Forces Montserrat regardless of locale.
  /// Use for prices, percentages, counters, timers.
  static const TextStyle numeric = TextStyle(
    fontFamily: _montserrat,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.20,
    letterSpacing: 0,
    fontFeatures: [FontFeature.tabularFigures()],
    color: QeranColors.inkStrong,
  );
}

