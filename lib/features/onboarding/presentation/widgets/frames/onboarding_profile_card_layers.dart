import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';

/// The wine/gold veils layered over the essence profile portrait. Grouped here
/// so the card widget itself stays focused on composition. All are decoration
/// only and ignore pointers.

/// A wine scrim along the top edge so the floating skip / language controls
/// stay legible over the full-bleed photo.
class OnboardingCardTopScrim extends StatelessWidget {
  const OnboardingCardTopScrim({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 130,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                QeranColors.wine.withValues(alpha: 0.55),
                QeranColors.wine.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A full wine veil for depth, deepening toward the base.
class OnboardingCardFullOverlay extends StatelessWidget {
  const OnboardingCardFullOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.42, 1.0],
              colors: [
                QeranColors.wine.withValues(alpha: 0.16),
                QeranColors.wine.withValues(alpha: 0.22),
                QeranColors.wine.withValues(alpha: 0.66),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A wine gradient shielding the lower card so the paper meta stays legible.
class OnboardingCardBottomScrim extends StatelessWidget {
  const OnboardingCardBottomScrim({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: 200,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                QeranColors.wine.withValues(alpha: 0),
                QeranColors.wine.withValues(alpha: 0.90),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
