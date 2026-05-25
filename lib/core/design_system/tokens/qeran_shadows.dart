import 'package:flutter/material.dart';

import 'qeran_colors.dart';

/// Wine-tinted elevation tokens. Never grey, never Material default.
class QeranShadows {
  const QeranShadows._();

  /// Flat — no shadow.
  static const List<BoxShadow> e0 = <BoxShadow>[];

  /// Hairline lift — chips, inputs at rest.
  static const List<BoxShadow> e1 = <BoxShadow>[
    BoxShadow(
      color: Color(0x0A431C33),
      blurRadius: 12,
      offset: Offset(0, 2),
    ),
  ];

  /// Card surfaces — the default card lift.
  static const List<BoxShadow> e2 = <BoxShadow>[
    BoxShadow(
      color: Color(0x12431C33),
      blurRadius: 20,
      offset: Offset(0, 6),
    ),
  ];

  /// Floating CTAs, action bars, sheets.
  static const List<BoxShadow> e3 = <BoxShadow>[
    BoxShadow(
      color: Color(0x1A431C33),
      blurRadius: 28,
      offset: Offset(0, 10),
    ),
  ];

  /// Hero surfaces — gold outer glow + e3 underneath.
  static const List<BoxShadow> eHero = <BoxShadow>[
    BoxShadow(
      color: Color(0x14E4C094),
      blurRadius: 36,
      offset: Offset(0, 0),
      spreadRadius: 2,
    ),
    BoxShadow(
      color: Color(0x1A431C33),
      blurRadius: 28,
      offset: Offset(0, 10),
    ),
  ];

  /// Reference: same wine alpha used for hairline borders when shadows
  /// are inappropriate (e.g. inside cards).
  static const Color hairlineBorder = QeranColors.wine08;
}
