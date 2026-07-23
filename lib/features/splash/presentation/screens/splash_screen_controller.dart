import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routes/navigation_manager.dart';
import '../../../../core/routes/route_name.dart';
import '../../../../core/services/firebase_initialization_service.dart';
import '../../../auth/presentation/blocs/user_session/user_session_cubit.dart';
import '../../../auth/presentation/blocs/user_session/user_session_state.dart';
import '../../../subscriptions/presentation/blocs/current/current_subscription_cubit.dart';
import '../blocs/splash_cubit.dart';
import '../blocs/splash_state.dart';

class SplashScreenController {
  final BuildContext context;

  SplashScreenController(this.context);

  Future<void> init() async {
    // Hydrate while the branded splash is already visible instead of delaying
    // runApp. Route resolution starts only when root session state is coherent.
    final session = sl<UserSessionCubit>();
    await Future.wait<void>([
      session.hydrate(),
      sl<FirebaseInitializationService>().ready,
    ]);
    if (!context.mounted) return;
    if (session.state is UserSessionAuthenticated) {
      unawaited(sl<CurrentSubscriptionCubit>().hydrate());
    }
    await context.read<SplashCubit>().checkAuthStatus();
  }

  void handleNavigation(SplashState state) {
    if (state is NavigateToOnboarding) {
      NavigationManager.pushNamedAndRemoveUntil(context, RouteNames.onboarding);
    } else if (state is NavigateToLogin) {
      NavigationManager.pushNamedAndRemoveUntil(
        context,
        RouteNames.loginScreen,
      );
    } else if (state is NavigateToHome) {
      NavigationManager.pushNamedAndRemoveUntil(context, RouteNames.homeScreen);
    } else if (state is NavigateToMatchmakerHome) {
      NavigationManager.pushNamedAndRemoveUntil(
        context,
        RouteNames.matchmakerHome,
      );
    } else if (state is NavigateToIncompleteProfile) {
      _handleIncompleteNavigation(state.step);
    }
  }

  void _handleIncompleteNavigation(String step) {
    String targetRoute = RouteNames.loginScreen;

    switch (step) {
      case 'gender':
        targetRoute = RouteNames.genderSelectionScreen;
        break;
      case 'questions':
        targetRoute = RouteNames.questionsScreen;
        break;
      case 'oath':
        targetRoute = RouteNames.oathScreen;
        break;
      case 'photos':
        targetRoute = RouteNames.photoUploadScreen;
        break;
      case 'whatsapp_input':
        targetRoute = RouteNames.whatsappInput;
        break;
      case 'whatsapp_verify':
        targetRoute = RouteNames.whatsappVerification;
        break;
    }

    NavigationManager.pushNamedAndRemoveUntil(context, targetRoute);
  }
}
