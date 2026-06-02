import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';

/// Calm burgundy heart shown over the card during right drags + Like
/// exits.
///
/// Driven by [progress] (0..1) — the fraction of full-exit distance the
/// card has travelled. A bell curve maps progress → scale + opacity so:
///
///   * progress 0.0   → invisible (scale 0.75, opacity 0)
///   * progress 0.5   → peak     (scale 1.25, opacity 0.85)
///   * progress 1.0   → invisible (scale 0.75, opacity 0) — card is off
///                                 screen so the overlay fades with it
///
/// During a slow finger drag (progress maxes ~0.33) the heart reaches
/// roughly two-thirds of its peak intensity — subtle, premium, no
/// particles / no glow.
class DiscoveryLikeOverlay extends StatelessWidget {
  final double progress;

  const DiscoveryLikeOverlay({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    final bell = (1.0 - (2.0 * (clamped - 0.5)).abs()).clamp(0.0, 1.0);
    final scale = 0.75 + bell * 0.5;
    final opacity = bell * 0.85;
    return IgnorePointer(
      child: Center(
        child: Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: const Icon(
              Icons.favorite_rounded,
              size: 120,
              color: QeranColors.wine,
            ),
          ),
        ),
      ),
    );
  }
}
