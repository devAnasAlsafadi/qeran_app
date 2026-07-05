import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_motion.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';

import '../../on_boarding_model.dart';
import '../cubit/onboarding_cubit.dart';
import '../widgets/frames/onboarding_essence_frame.dart';
import '../widgets/frames/onboarding_mediation_frame.dart';
import '../widgets/frames/onboarding_roadmap_frame.dart';
import '../widgets/frames/onboarding_splash_frame.dart';
import '../widgets/onboarding_bottom_nav.dart';
import '../widgets/onboarding_top_bar.dart';

/// The onboarding wizard coordinator: a 4-page `PageView` (splash + 3 content
/// frames) with a shared top bar (skip / language) and bottom nav (back · dots ·
/// next). All page math routes through the untouched [OnboardingCubit]; the
/// splash auto-advances via [OnboardingSplashFrame].
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
    if (!_pageController.hasClients) return;
    _pageController.animateToPage(
      page,
      duration: QeranMotion.gentle,
      curve: QeranCurves.standard,
    );
  }

  /// Where to land after onboarding finishes. Unauthenticated → login; an
  /// in-memory session → that role's home.
  String _postOnboardingRoute() {
    final user = sl<UserSessionCubit>().currentUser;
    if (user == null || (user.token?.isEmpty ?? true)) {
      return RouteNames.loginScreen;
    }
    return user.role?.toLowerCase() == 'moderator'
        ? RouteNames.matchmakerHome
        : RouteNames.homeScreen;
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
            NavigationManager.pushNamedAndRemoveUntil(
              context,
              _postOnboardingRoute(),
            );
            return;
          }
          _animateToPage(state.currentPage);
        },
        builder: (context, state) {
          final cubit = context.read<OnboardingCubit>();
          final onContent = state.currentPage != 0;
          return Scaffold(
            backgroundColor: QeranColors.wine,
            body: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: onboardingData.length,
                  onPageChanged: cubit.onPageChanged,
                  itemBuilder: (_, index) => _frameFor(index, cubit),
                ),
                // Chrome shows on content frames only (never the splash).
                if (onContent)
                  SafeArea(
                    bottom: false,
                    child: OnboardingTopBar(onSkip: cubit.skip),
                  ),
                if (onContent)
                  PositionedDirectional(
                    bottom: 0,
                    start: 0,
                    end: 0,
                    child: SafeArea(
                      top: false,
                      child: OnboardingBottomNav(
                        dotCount: onboardingData.length - 1,
                        activeDot: state.currentPage - 1,
                        showBack: state.currentPage > 1,
                        showNext: !state.isLastPage,
                        onBack: cubit.previousPage,
                        onNext: cubit.nextPage,
                        onDot: (i) => _animateToPage(i + 1),
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

  Widget _frameFor(int index, OnboardingCubit cubit) {
    switch (onboardingData[index]) {
      case OnboardingFrame.splash:
        return OnboardingSplashFrame(onAdvance: cubit.nextPage);
      case OnboardingFrame.essencePrivacy:
        return const OnboardingEssenceFrame();
      case OnboardingFrame.mediation:
        return OnboardingMediationFrame(onSearch: cubit.nextPage);
      case OnboardingFrame.roadmap:
        return OnboardingRoadmapFrame(onFinish: cubit.nextPage);
    }
  }
}
