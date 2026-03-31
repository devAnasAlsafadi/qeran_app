import 'package:flutter/material.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/utils/app_dimens.dart';
import '../../on_boarding_model.dart';

/// Displays the title and description for the current onboarding page.
/// Uses [AnimatedSwitcher] with a fade transition when the page changes.
class OnboardingTextContent extends StatelessWidget {
  final OnboardingModel page;
  final int currentPageIndex;

  const OnboardingTextContent({
    super.key,
    required this.page,
    required this.currentPageIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: Text(
            page.title,
            key: ValueKey<int>(currentPageIndex),
            style: AppTextStyles.displayLarge.copyWith(color: AppColors.white),
          ),
        ),
        AppDimens.verticalSpace8,
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: Text(
            page.description,
            key: ValueKey<String>('desc_$currentPageIndex'),
            style: AppTextStyles.bodyLarge
                .copyWith(color: AppColors.white.withValues(alpha: 0.85)),
          ),
        ),
      ],
    );
  }
}
