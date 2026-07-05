import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';

import 'custom_dot_indicator.dart';

/// The content-frame bottom navigation: `[ Back · ●●○ dots · Next ]`.
///
/// Shown on frames 1–3 (never on the splash). Back is hidden on the first
/// content frame (design floors "back" at frame 1). The dots track the active
/// content frame ([activeDot] = `currentPage - 1`), and tapping a dot jumps via
/// [onDot]. All callbacks are pure so the widget stays decoupled from the cubit.
class OnboardingBottomNav extends StatelessWidget {
  final int dotCount;
  final int activeDot;
  final bool showBack;
  final bool showNext;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final ValueChanged<int> onDot;

  const OnboardingBottomNav({
    super.key,
    required this.dotCount,
    required this.activeDot,
    required this.showBack,
    required this.onBack,
    required this.onNext,
    required this.onDot,
    this.showNext = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        QeranSpacing.s20,
        QeranSpacing.s12,
        QeranSpacing.s20,
        QeranSpacing.s24,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Transparent placeholder keeps the dots centred when Back is hidden.
          showBack
              ? _NavCircle(
                  onTap: onBack,
                  pointForward: false,
                  background: QeranColors.wine08,
                  iconColor: QeranColors.wine,
                )
              : const SizedBox(width: 52, height: 52),
          CustomDotIndicator(
            count: dotCount,
            activeIndex: activeDot,
            onTap: onDot,
          ),
          // Hidden on the last frame — the in-frame CTA is the finisher there.
          showNext
              ? _NavCircle(
                  onTap: onNext,
                  pointForward: true,
                  background: QeranColors.gold,
                  iconColor: QeranColors.wine,
                )
              : const SizedBox(width: 52, height: 52),
        ],
      ),
    );
  }
}

/// A 52×52 circle button with a directional chevron.
///
/// [pointForward] = true → toward the reading end (→ LTR, ← RTL); false → toward
/// the start. One base right-chevron is flipped for RTL, so no manual ternary.
class _NavCircle extends StatelessWidget {
  final VoidCallback onTap;
  final bool pointForward;
  final Color background;
  final Color iconColor;

  const _NavCircle({
    required this.onTap,
    required this.pointForward,
    required this.background,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Transform.flip(
          flipX: pointForward == isRtl,
          child: Icon(
            Icons.arrow_forward_ios_rounded,
            color: iconColor,
            size: 18,
          ),
        ),
      ),
    );
  }
}
