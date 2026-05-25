import 'package:flutter/material.dart';

import '../../../../core/extensions/localization_extension.dart';
import '../../../../core/theme/app_color.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/utils/app_dimens.dart';
import '../../on_boarding_model.dart';
import '../cubit/onboarding_cubit.dart';
import 'custom_dot_indicator.dart';

/// Navigation row: [ Back | ●●○ Dots | Next / Get Started ]
///
/// Receives pure callbacks so it stays decoupled from the cubit.
class OnboardingNavRow extends StatelessWidget {
  final OnboardingState state;
  final PageController pageController;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onGetStarted;

  const OnboardingNavRow({
    super.key,
    required this.state,
    required this.pageController,
    required this.onNext,
    required this.onPrevious,
    required this.onGetStarted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Start side — transparent placeholder on page 0 keeps dots centered.
        state.isFirstPage
            ? const SizedBox(width: 56, height: 56)
            : _NavCircleButton(
                onTap: onPrevious,
                pointForward: false,
                backgroundColor: AppColors.white.withValues(alpha: 0.2),
                iconColor: AppColors.white,
              ),

        CustomDotIndicator(
          controller: pageController,
          count: onboardingData.length,
        ),

        // End side — pill button on last page, circle arrow otherwise.
        state.isLastPage
            ? _GetStartedButton(onTap: onGetStarted)
            : _NavCircleButton(
                onTap: onNext,
                pointForward: true,
                backgroundColor: AppColors.primaryLight,
                iconColor: AppColors.primary,
              ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

/// A 56×56 circle button with a directional arrow.
///
/// [pointForward] = true  → arrow points toward the reading end  (→ in LTR, ← in RTL)
/// [pointForward] = false → arrow points toward the reading start (← in LTR, → in RTL)
///
/// A single base icon [Icons.arrow_forward_ios_rounded] (→) is used for both
/// cases; [Transform.flip] handles the visual direction without any ternary.
class _NavCircleButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool pointForward;
  final Color backgroundColor;
  final Color iconColor;

  const _NavCircleButton({
    required this.onTap,
    required this.pointForward,
    required this.backgroundColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final iconData = pointForward
        ? Icons.arrow_forward_ios_rounded
        : Icons.arrow_back_ios_new_rounded;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(iconData, color: iconColor, size: 20),
      ),
    );
  }
}

class _GetStartedButton extends StatelessWidget {
  final VoidCallback onTap;

  const _GetStartedButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.p24,
          vertical: AppDimens.p12,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: AppDimens.borderRadius16,
        ),
        child: Text(
          LocaleKeys.onboarding_get_started.t(context),
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
        ),
      ),
    );
  }
}
