import 'package:flutter/material.dart';

import '../effects/ring_motif.dart';
import '../tokens/qeran_colors.dart';
import '../tokens/qeran_shadows.dart';
import '../tokens/qeran_strokes.dart';

/// Visual weight of a [QeranHeroBadge].
enum QeranHeroBadgeTone {
  /// Light gold-tinted disc with a wine glyph — a quiet accent (e.g. the
  /// gated-action paywall sheet).
  soft,

  /// Wine-gradient disc with a gold border, gold glow, and a gold glyph —
  /// a prominent focal hero (e.g. the daily-limit / photo-exchange surfaces).
  prominent,
}

/// The identity hero badge: a concentric [RingMotif] behind a circular disc
/// with a centered glyph. One widget, two tones — see [QeranHeroBadgeTone].
///
/// [size] is the disc diameter; [ringSize] the outer ring diameter (defaults
/// proportionally per tone). Place it directly, or inside a smaller `SizedBox`
/// to crop the ring's vertical footprint.
class QeranHeroBadge extends StatelessWidget {
  const QeranHeroBadge({
    super.key,
    required this.glyph,
    required this.size,
    this.tone = QeranHeroBadgeTone.prominent,
    this.ringSize,
    this.glyphSize,
  });

  /// The centered icon.
  final IconData glyph;

  /// Disc diameter.
  final double size;

  /// Soft accent vs prominent focal hero.
  final QeranHeroBadgeTone tone;

  /// Outer ring diameter. Defaults to a per-tone multiple of [size].
  final double? ringSize;

  /// Glyph size. Defaults to ~0.44 × [size].
  final double? glyphSize;

  // Ring-to-disc ratios matching the reference surfaces (soft: 72→140;
  // prominent: ~84→200 / 104→260).
  static const double _softRingRatio = 140 / 72;
  static const double _prominentRingRatio = 2.4;

  @override
  Widget build(BuildContext context) {
    final isSoft = tone == QeranHeroBadgeTone.soft;
    final ring = ringSize ??
        size * (isSoft ? _softRingRatio : _prominentRingRatio);
    final resolvedGlyphSize = glyphSize ?? size * 0.44;

    return Stack(
      alignment: Alignment.center,
      children: [
        RingMotif(
          color: QeranColors.gold,
          opacity: 0.10,
          size: ring,
          ringCount: 2,
          spacing: 14,
        ),
        Container(
          width: size,
          height: size,
          decoration: isSoft
              ? const BoxDecoration(
                  shape: BoxShape.circle,
                  color: QeranColors.gold20,
                )
              : BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [QeranColors.wineLight, QeranColors.wine],
                  ),
                  border: Border.all(
                    color: QeranColors.gold,
                    width: QeranStrokes.emphasis,
                  ),
                  boxShadow: QeranShadows.eHero,
                ),
          alignment: Alignment.center,
          child: Icon(
            glyph,
            size: resolvedGlyphSize,
            color: isSoft ? QeranColors.wine : QeranColors.gold,
          ),
        ),
      ],
    );
  }
}
