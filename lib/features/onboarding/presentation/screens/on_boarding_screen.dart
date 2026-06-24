import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import '../../on_boarding_model.dart';
import '../cubit/onboarding_cubit.dart';
import '../widgets/onboarding_body.dart';
import 'on_boarding/widgets/onboarding_bottom_panel.dart';
import 'on_boarding/widgets/onboarding_gradient_overlay.dart';
import 'package:qeran/core/widgets/language_switch_button.dart';

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

  /// Where to land after onboarding finishes. Normally the unauthenticated
  /// path → login. But if a real session is already in memory (e.g. onboarding
  /// was ever shown to an authenticated user), route to their role's home
  /// instead of dumping them back to login.
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
                const OnboardingGradientOverlay(),
                OnboardingBottomPanel(
                  state: state,
                  pageController: _pageController,
                  onNext: cubit.nextPage,
                  onPrevious: cubit.previousPage,
                  onGetStarted: cubit.skip,
                ),
                if (!state.isLastPage) ...[
                  PositionedDirectional(
                    top: MediaQuery.of(context).padding.top + AppDimens.p8,
                    start: AppDimens.p16,
                    child: TextButton(
                      onPressed: cubit.skip,
                      child: Text(
                        LocaleKeys.common_skip.t(context),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.white,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    top: MediaQuery.of(context).padding.top + AppDimens.p8,
                    end: AppDimens.p16,
                    child: const LanguageSwitchButton(
                      variant: LanguageSwitchVariant.light,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
