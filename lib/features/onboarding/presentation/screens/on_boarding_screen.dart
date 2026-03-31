import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/routes/navigation_manager.dart';
import '../../../../core/routes/route_name.dart';
import '../../../../core/theme/app_color.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../../../core/utils/app_dimens.dart';
import '../../on_boarding_model.dart';
import '../cubit/onboarding_cubit.dart';
import '../widgets/onboarding_body.dart';
import '../widgets/onboarding_nav_row.dart';
import '../widgets/onboarding_text_content.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _animateToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OnboardingCubit>(),
      child: BlocConsumer<OnboardingCubit, OnboardingState>(
        listenWhen: (prev, curr) =>
            curr is OnboardingDone || prev.currentPage != curr.currentPage,
        listener: (context, state) {
          if (state is OnboardingDone) {
            NavigationManager.pushNamedAndRemoveUntil(context, RouteNames.loginScreen);
            return;
          }
          _animateToPage(state.currentPage);
        },
        builder: (context, state) {
          final cubit = context.read<OnboardingCubit>();
          return Scaffold(
            body: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: onboardingData.length,
                  onPageChanged: cubit.onPageChanged,
                  itemBuilder: (_, index) =>
                      OnboardingBody(imagePath: onboardingData[index].image),
                ),
                _GradientOverlay(),
                _BottomPanel(
                  state: state,
                  pageController: _pageController,
                  onNext: cubit.nextPage,
                  onPrevious: cubit.previousPage,
                  onGetStarted: cubit.skip,
                ),
                if (!state.isLastPage)
                  PositionedDirectional(
                    top: MediaQuery.of(context).padding.top + AppDimens.p8,
                    start: AppDimens.p16,
                    child: TextButton(
                      onPressed: cubit.skip,
                      child: Text(
                        'تخطى',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.white,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Screen-local layout widgets
// ---------------------------------------------------------------------------

class _GradientOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.transparent,
              AppColors.primary.withValues(alpha: 0.55),
              AppColors.primary.withValues(alpha: 0.95),
            ],
            stops: const [0.35, 0.65, 1.0],
          ),
        ),
      ),
    );
  }
}

class _BottomPanel extends StatelessWidget {
  final OnboardingState state;
  final PageController pageController;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onGetStarted;

  const _BottomPanel({
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
