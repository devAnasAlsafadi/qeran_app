import 'package:flutter/material.dart';

/// Spacing scale. Multiples of 4, with 2/6 for micro-adjustments.
///
/// Usage guide:
/// - s8  inside chip / dense control
/// - s12 between related elements (icon + label)
/// - s16 between siblings inside a card
/// - s20 card inner padding (default)
/// - s24 between sections in a body
/// - s32 between major sections / above-below heroes
/// - s48 hero top/bottom padding on splash-style surfaces
/// - s64 max hero vertical rhythm
class QeranSpacing {
  const QeranSpacing._();

  static const double s2 = 2.0;
  static const double s4 = 4.0;
  static const double s6 = 6.0;
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;
  static const double s48 = 48.0;
  static const double s64 = 64.0;

  // Vertical sized boxes (const-friendly)
  static const Widget vs4 = SizedBox(height: s4);
  static const Widget vs8 = SizedBox(height: s8);
  static const Widget vs12 = SizedBox(height: s12);
  static const Widget vs16 = SizedBox(height: s16);
  static const Widget vs20 = SizedBox(height: s20);
  static const Widget vs24 = SizedBox(height: s24);
  static const Widget vs32 = SizedBox(height: s32);
  static const Widget vs48 = SizedBox(height: s48);

  // Horizontal sized boxes
  static const Widget hs4 = SizedBox(width: s4);
  static const Widget hs8 = SizedBox(width: s8);
  static const Widget hs12 = SizedBox(width: s12);
  static const Widget hs16 = SizedBox(width: s16);
  static const Widget hs20 = SizedBox(width: s20);
  static const Widget hs24 = SizedBox(width: s24);

  // Common insets
  static const EdgeInsets cardInner = EdgeInsets.all(s20);
  static const EdgeInsets cardInnerHero = EdgeInsets.all(s24);
  static const EdgeInsets screenH = EdgeInsets.symmetric(horizontal: s20);
  static const EdgeInsets chipPad = EdgeInsets.symmetric(
    horizontal: s12,
    vertical: s6,
  );
}
