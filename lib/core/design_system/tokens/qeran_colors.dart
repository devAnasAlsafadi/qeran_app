import 'package:flutter/material.dart';

/// Strict two-anchor palette over a warm cream canvas.
/// Source of truth: Qeran identity.pdf (wine #431C33, gold #E4C094).
class QeranColors {
  const QeranColors._();

  // Brand anchors
  static const Color wine = Color(0xFF431C33);
  static const Color gold = Color(0xFFE4C094);

  // Canvas tier
  static const Color creamCanvas = Color(0xFFF8EDDA);
  static const Color creamSurface = Color(0xFFFBF4E6);
  static const Color paper = Color(0xFFFFFFFF);

  // Ink (wine-tinted neutrals, never cold grey)
  static const Color inkStrong = Color(0xFF431C33);
  static const Color inkBody = Color(0xFF5A3B4E);
  static const Color inkMuted = Color(0xFF8A7984);

  // Wine alpha shades
  static const Color wine90 = Color(0xE6431C33);
  static const Color wine80 = Color(0xCC431C33);
  static const Color wine60 = Color(0x99431C33);
  static const Color wine40 = Color(0x66431C33);
  static const Color wine20 = Color(0x33431C33);
  static const Color wine12 = Color(0x1F431C33);
  static const Color wine08 = Color(0x14431C33);
  static const Color wine06 = Color(0x0F431C33);

  // Gold alpha shades
  static const Color gold80 = Color(0xCCE4C094);
  static const Color gold60 = Color(0x99E4C094);
  static const Color gold40 = Color(0x66E4C094);
  static const Color gold20 = Color(0x33E4C094);
  static const Color gold12 = Color(0x1FE4C094);
  static const Color gold08 = Color(0x14E4C094);

  // Semantics (wine/gold-leaning, never Material)
  static const Color divider = wine08;
  static const Color hairline = wine12;
  static const Color danger = Color(0xFFA33949);
  static const Color successWarm = Color(0xFF5F8F6C);
  static const Color info = wine;

  // Overlays
  static const Color overlayTintDark = Color(0x8C431C33); // wine @ ~55%
  static const Color overlayTintLight = Color(0xB3F8EDDA); // cream @ ~70%
  static const Color photoScrimTop = Color(0x33000000);
  static const Color photoScrimBottom = Color(0x99000000);
}
