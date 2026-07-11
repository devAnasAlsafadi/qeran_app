import 'package:flutter/material.dart';

/// Strict two-anchor palette over a warm cream canvas.
/// Source of truth: Qeran identity.pdf (wine #431C33, gold #E4C094).
class QeranColors {
  const QeranColors._();

  // Brand anchors
  static const Color wine = Color(0xFF431C33);

  /// Lighter wine for two-tone gradients (paired with [wine]).
  static const Color wineLight = Color(0xFF4A1F38);
  static const Color gold = Color(0xFFE4C094);

  /// Deeper, opaque gold for "pending / waiting" accents (status text,
  /// countdown chips) that need stronger contrast than [gold] on light
  /// surfaces. Same warm family, one step toward bronze.
  static const Color goldDeep = Color(0xFFB18454);

  /// Lighter, opaque gold — the bright stop above [gold] for gradient
  /// highlights (e.g. the onboarding marriage-rings motif).
  static const Color goldLight = Color(0xFFF2D9AC);

  // Canvas tier
  static const Color creamCanvas = Color(0xFFF8F8F8);
  static const Color creamSurface = Color(0xFFFBF4E6);
  static const Color paper = Color(0xFFFFFFFF);

  /// Faint neutral (de-warmed) inset surface — segmented-control tracks and
  /// similar recessed fills where a white/paper element sits on top. Reads as a
  /// subtle band against [creamCanvas], and is darker than [paper] so a white
  /// pill has clear contrast.
  static const Color neutralSurface = Color(0xFFEFEFF1);

  // Ink (wine-tinted neutrals, never cold grey)
  static const Color inkStrong = Color(0xFF431C33);
  static const Color inkBody = Color(0xFF5A3B4E);
  static const Color inkMuted = Color(0xFF8A7984);

  /// Lightest wine-tinted neutral — placeholders/hints and the soft icons
  /// inside input fields. One step lighter than [inkMuted].
  static const Color inkFaint = Color(0xFFB3A8AF);

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

  /// Gold @ ~18% — icon-chip fills on wine hero surfaces (the gold glyph
  /// needs a warmer bed than [gold12] but softer than [gold20]).
  static const Color gold18 = Color(0x2EE4C094);
  static const Color gold12 = Color(0x1FE4C094);
  static const Color gold08 = Color(0x14E4C094);

  // Semantics (wine/gold-leaning, never Material)
  static const Color divider = wine08;
  static const Color hairline = wine12;

  /// Soft wine-tinted neutral fill for chip-style controls (e.g. the
  /// matchmaker card's secondary action buttons) — a modern soft "grey" that
  /// stays on-identity (wine @ ~10%), never a cold grey. Sits between
  /// [wine08] and [wine12].
  static const Color softFill = Color(0x1A431C33);

  static const Color danger = Color(0xFFA33949);

  // Danger alpha shades — soft tints for failed-state borders/fills (e.g. a
  // failed chat message) so we never inline `danger.withValues(...)`.
  static const Color danger40 = Color(0x66A33949);
  static const Color danger12 = Color(0x1FA33949);
  static const Color danger08 = Color(0x14A33949);

  /// Success in Qeran wears gold, not green.
  /// The brand identity contains no green; achievements
  /// (matches, approvals, completions) celebrate via gold.
  static const Color successWarm = gold;
  static const Color info = wine;

  // Overlays
  static const Color overlayTintDark = Color(0x8C431C33); // wine @ ~55%
  static const Color overlayTintLight = Color(0xB3F8EDDA); // cream @ ~70%
  static const Color photoScrimTop = Color(0x33000000);
  static const Color photoScrimBottom = Color(0x99000000);

  /// The ONE sanctioned opaque black in the app — a brand-compliance
  /// exception for the Apple sign-in glyph (Apple HIG mandates a pure
  /// black/white Apple mark). Do NOT use for app chrome, text, or icons;
  /// the palette's dark is [inkStrong] (wine). New uses need sign-off.
  static const Color appleBlack = Color(0xFF000000);
}
