import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';

/// The immersive wine hero canvas behind a content frame. A radial
/// wine-light→wine gradient (centred slightly high, matching the design's
/// `radial-gradient(circle at 50% 38%, …)`) gives the frames their premium
/// depth; the white dome panel then surfaces out of it.
///
/// Wrap a whole content frame with this — the frame's own bottom panel paints
/// its paper surface over the lower portion.
class OnboardingHeroBackground extends StatelessWidget {
  final Widget child;

  const OnboardingHeroBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.35),
          radius: 1.15,
          colors: [QeranColors.wineLight, QeranColors.wine],
        ),
      ),
      child: child,
    );
  }
}
