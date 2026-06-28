import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';

class OnboardingGradientOverlay extends StatelessWidget {
  const OnboardingGradientOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              QeranColors.wine.withValues(alpha: 0.55),
              QeranColors.wine.withValues(alpha: 0.95),
            ],
            stops: const [0.35, 0.65, 1.0],
          ),
        ),
      ),
    );
  }
}
