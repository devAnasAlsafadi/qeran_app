import 'package:flutter/material.dart';

import 'custom_dot_indicator.dart';
import 'onboarding_circle_button.dart';

/// Onboarding's navigation row: **back** at the start, page dots centred,
/// **next** at the end. Plain `Row`, so it mirrors automatically — back lands
/// on the right in Arabic and the left in English, next on the opposite edge.
///
/// Either control can be absent: [onBack] is null on the first page (nothing to
/// go back to) and [onNext] is null on the last, where a full-width CTA is the
/// action instead. A missing control still reserves
/// [OnboardingCircleButton.size], so both side slots stay equal and the dots
/// remain centred rather than sliding across when a button disappears.
///
/// All callbacks are pure, so the row stays decoupled from the cubit.
class OnboardingNavRow extends StatelessWidget {
  final int dotCount;
  final int activeDot;
  final ValueChanged<int> onDot;
  final VoidCallback? onBack;
  final VoidCallback? onNext;

  const OnboardingNavRow({
    super.key,
    required this.dotCount,
    required this.activeDot,
    required this.onDot,
    this.onBack,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final back = onBack;
    final next = onNext;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (back == null)
          const SizedBox(width: OnboardingCircleButton.size)
        else
          OnboardingCircleButton(
            icon: Icons.arrow_back_ios_rounded,
            onTap: back,
          ),
        CustomDotIndicator(
          count: dotCount,
          activeIndex: activeDot,
          onTap: onDot,
        ),
        if (next == null)
          const SizedBox(width: OnboardingCircleButton.size)
        else
          OnboardingCircleButton(
            icon: Icons.arrow_forward_ios_rounded,
            onTap: next,
          ),
      ],
    );
  }
}
