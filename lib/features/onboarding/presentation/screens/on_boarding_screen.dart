import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';
import 'package:qeran/core/utils/app_assets.dart';

import '../../on_boarding_model.dart';
import '../cubit/onboarding_cubit.dart';
import '../widgets/frames/onboarding_essence_frame.dart';
import '../widgets/frames/onboarding_mediation_frame.dart';
import '../widgets/frames/onboarding_roadmap_frame.dart';
import '../widgets/onboarding_top_bar.dart';

/// The onboarding wizard coordinator: a 3-page `PageView` (essence · mediation ·
/// roadmap) with a shared top bar (skip / language) and per-frame in-dome
/// footer. All page math routes through the untouched [OnboardingCubit]; the
/// brand-splash moment now lives in the Lottie splash, so onboarding opens
/// directly on essence/privacy.
class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  final PageController _pageController = PageController();
  bool _portraitPrecached = false;
  bool _pageAnimating = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_portraitPrecached) return;
    _portraitPrecached = true;
    unawaited(
      precacheImage(const AssetImage(AppAssets.welcomePortrait), context),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _animateToPage(int page) async {
    if (!_pageController.hasClients || _pageAnimating) return;
    _pageAnimating = true;
    try {
      await _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutQuart,
      );
    } finally {
      _pageAnimating = false;
    }
  }

  void _advance(OnboardingCubit cubit, OnboardingState state) {
    if (state.isLastPage) {
      cubit.nextPage();
      return;
    }
    unawaited(_animateToPage(state.currentPage + 1));
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
        listenWhen: (_, curr) => curr is OnboardingDone,
        listener: (context, state) {
          if (state is OnboardingDone) {
            NavigationManager.pushNamedAndRemoveUntil(
              context,
              _postOnboardingRoute(),
            );
          }
        },
        builder: (context, state) {
          final cubit = context.read<OnboardingCubit>();
          return Scaffold(
            backgroundColor: QeranColors.wine,
            body: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: onboardingData.length,
                  allowImplicitScrolling: true,
                  physics: const PageScrollPhysics(
                    parent: ClampingScrollPhysics(),
                  ),
                  onPageChanged: cubit.onPageChanged,
                  itemBuilder: (_, index) => RepaintBoundary(
                    child: TickerMode(
                      // The blur-reveal seam remains fully animated on the
                      // visible privacy page, but all repeating tickers pause
                      // as soon as their page leaves the viewport.
                      enabled: index == state.currentPage,
                      child: _frameFor(index, cubit, state),
                    ),
                  ),
                ),
                // Chrome shows on every frame. Skip is hidden on the last frame
                // (roadmap); each frame owns its in-dome footer, so there is no
                // floating bottom nav.
                SafeArea(
                  bottom: false,
                  child: OnboardingTopBar(
                    onSkip: cubit.skip,
                    showSkip: !state.isLastPage,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _frameFor(int index, OnboardingCubit cubit, OnboardingState state) {
    // The 3 frames map 1:1 to the 3 dots: dotCount = total frames, activeDot =
    // the current page, and onDot navigates straight to that page (no offset —
    // the former non-dotted brand-splash frame 0 is gone).
    switch (onboardingData[index]) {
      case OnboardingFrame.essencePrivacy:
        return OnboardingEssenceFrame(
          dotCount: onboardingData.length,
          activeDot: state.currentPage,
          onDot: _animateToPage,
          onNext: () => _advance(cubit, state),
        );
      case OnboardingFrame.mediation:
        return OnboardingMediationFrame(
          dotCount: onboardingData.length,
          activeDot: state.currentPage,
          onDot: _animateToPage,
          onNext: () => _advance(cubit, state),
          onSearch: () => _advance(cubit, state),
        );
      case OnboardingFrame.roadmap:
        return OnboardingRoadmapFrame(
          onFinish: cubit.nextPage,
          dotCount: onboardingData.length,
          activeDot: state.currentPage,
          onDot: _animateToPage,
        );
    }
  }
}
