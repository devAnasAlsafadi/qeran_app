import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/routes/navigation_manager.dart';
import '../../../../core/routes/route_name.dart';
import '../../../devices/application/device_bootstrap_service.dart';
import '../blocs/splash_cubit.dart';
import '../blocs/splash_state.dart';

class SplashScreenController {
  final BuildContext context;

  SplashScreenController(this.context);

  void init() {
    context.read<SplashCubit>().checkAuthStatus();
    // Fire-and-forget — must not block splash routing.
    unawaited(sl<DeviceBootstrapService>().bootstrap());
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
