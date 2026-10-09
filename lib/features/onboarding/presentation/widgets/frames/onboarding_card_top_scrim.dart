import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';

/// A wine scrim along the top edge so the floating skip / language controls
/// stay legible over a busy hero (frame 2's conversation).
class OnboardingCardTopScrim extends StatelessWidget {
  const OnboardingCardTopScrim({super.key});

  @override
  Widget build(BuildContext context) {
    return PositionedDirectional(
      top: 0,
      start: 0,
      end: 0,
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
