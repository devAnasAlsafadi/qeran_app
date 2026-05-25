import 'package:flutter/material.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import '../../../../on_boarding_model.dart';
import '../../../cubit/onboarding_cubit.dart';
import '../../../widgets/onboarding_nav_row.dart';
import '../../../widgets/onboarding_text_content.dart';

class OnboardingBottomPanel extends StatelessWidget {
  final OnboardingState state;
  final PageController pageController;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onGetStarted;

  const OnboardingBottomPanel({
    super.key,
    required this.state,
    required this.pageController,
    required this.onNext,
    required this.onPrevious,
    required this.onGetStarted,
  });

  @override
  Widget build(BuildContext context) {
    return PositionedDirectional(
      bottom: 0,
      start: 0,
      end: 0,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppDimens.p24,
          AppDimens.p16,
          AppDimens.p24,
          AppDimens.p48,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            OnboardingTextContent(
              page: onboardingData[state.currentPage],
              currentPageIndex: state.currentPage,
            ),
            AppDimens.verticalSpace24,
            OnboardingNavRow(
              state: state,
              pageController: pageController,
              onNext: onNext,
              onPrevious: onPrevious,
              onGetStarted: onGetStarted,
            ),
          ],
        ),
      ),
    );
  }
}
