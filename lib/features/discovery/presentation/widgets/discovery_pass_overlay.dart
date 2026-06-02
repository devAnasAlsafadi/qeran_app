import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';

/// Calm grey-X shown over the card during left drags + Pass exits.
///
/// Mirror of [DiscoveryLikeOverlay] but with a muted neutral color so
/// the two directions read distinctly without either feeling alarming.
/// Same bell-curve scale + opacity mapping; see that widget's doc for
/// the curve shape.
class DiscoveryPassOverlay extends StatelessWidget {
  final double progress;

  const DiscoveryPassOverlay({super.key, required this.progress});

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
              Icons.close_rounded,
              size: 120,
              color: QeranColors.inkMuted,
            ),
          ),
        ),
      ),
    );
  }
}
