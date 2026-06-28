import 'package:flutter/material.dart';

import '../../../../core/extensions/localization_extension.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
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
            page.title.t(context),
            key: ValueKey<int>(currentPageIndex),
            style: QeranTypography.displaySm.copyWith(color: QeranColors.paper),
          ),
        ),
        QeranSpacing.vs8,
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: Text(
            page.description.t(context),
            key: ValueKey<String>('desc_$currentPageIndex'),
            style: QeranTypography.subtitle.copyWith(
              color: QeranColors.paper.withValues(alpha: 0.85),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
