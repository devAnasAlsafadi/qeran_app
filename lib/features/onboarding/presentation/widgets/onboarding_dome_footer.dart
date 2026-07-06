import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_shadows.dart';

import 'custom_dot_indicator.dart';

/// The in-dome footer for content frames 1–2: page dots at the start and a gold
/// circular **next** button at the end. Lives inside the frame's paper panel
/// (the design bakes navigation into the dome rather than floating it).
///
/// All callbacks are pure, so the footer stays decoupled from the cubit.
class OnboardingDomeFooter extends StatelessWidget {
  final int dotCount;
  final int activeDot;
  final ValueChanged<int> onDot;
  final VoidCallback onNext;

  const OnboardingDomeFooter({
    super.key,
    required this.dotCount,
    required this.activeDot,
    required this.onDot,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomDotIndicator(
          count: dotCount,
          activeIndex: activeDot,
          onTap: onDot,
        ),
        _NextFab(onTap: onNext),
      ],
    );
  }
}

/// A 52×52 gold circle carrying a directional forward chevron (→ in LTR,
/// ← in RTL). One base right-arrow is flipped for RTL, so no manual ternary.
class _NextFab extends StatelessWidget {
  final VoidCallback onTap;

  const _NextFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          color: QeranColors.gold,
          shape: BoxShape.circle,
          boxShadow: QeranShadows.e3,
        ),
        child: Transform.flip(
          flipX: isRtl,
          child: const Icon(
            Icons.arrow_forward_ios_rounded,
            color: QeranColors.wine,
            size: 20,
          ),
        ),
      ),
    );
  }
}
