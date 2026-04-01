import 'package:flutter/material.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/features/auth/presentation/screens/forgot_password/forget_pass_screen.dart';
import 'package:qeran/features/auth/presentation/screens/login_screen/login_screen.dart';
import 'package:qeran/features/auth/presentation/screens/oath/oath_screen.dart';
import 'package:qeran/features/auth/presentation/screens/register_screen/register_screen.dart';
import 'package:qeran/features/auth/presentation/screens/reset_password/reset_pass_screen.dart';
import 'package:qeran/features/auth/presentation/screens/upload_image/upload_image_profile_screen.dart';
import 'package:qeran/features/auth/presentation/screens/whatsapp_input/whatsapp_input_screen.dart';
import 'package:qeran/features/auth/presentation/screens/whatsapp_verification/whatsapp_verification.dart';
import 'package:qeran/features/home/presentation/screens/home_screen.dart';
import 'package:qeran/features/khataba_dashboard/presentation/screens/dashboard_screen.dart';
import 'package:qeran/features/onboarding/presentation/screens/on_boarding_screen.dart';
import 'package:qeran/features/questionnaire/domain/entities/question_entity.dart';
import 'package:qeran/features/questionnaire/presentation/screens/gender_selection/gender_selection_screen.dart';
import 'package:qeran/features/questionnaire/presentation/screens/questionnaire_flow/questionnaire_flow_screen.dart';
import 'package:qeran/features/splash/presentation/screens/splash_screen.dart';

class AppRouter {

   Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.splashScreen:
        return MaterialPageRoute(settings: settings, builder: (context) => const SplashScreen());

      case RouteNames.onboarding:
        return MaterialPageRoute(settings: settings, builder: (context) => const OnBoardingScreen());

      case RouteNames.loginScreen:
        return MaterialPageRoute(settings: settings, builder: (context) => const LoginScreen());

      case RouteNames.registerScreen:
        return MaterialPageRoute(settings: settings, builder: (context) => const RegisterScreen());
      case RouteNames.forgotPasswordEmail:
        return MaterialPageRoute(settings: settings, builder: (context) => const ForgetPassScreen());
      case RouteNames.resetPassword:
        return MaterialPageRoute(settings: settings, builder: (context) => const ResetPassScreen());
      case RouteNames.whatsappInput:
        return MaterialPageRoute(settings: settings, builder: (context) => const WhatsappInputScreen());
      case RouteNames.whatsappVerification:
        return MaterialPageRoute(settings: settings, builder: (context) => const WhatsappVerificationScreen());
      case RouteNames.genderSelectionScreen:
        return MaterialPageRoute(settings: settings, builder: (context) => const GenderSelectionScreen());
      case RouteNames.questionsScreen:
        final questions = settings.arguments as List<QuestionEntity>?;
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => QuestionnaireFlowScreen(questions: questions),
        );
      case RouteNames.oathScreen:
        return MaterialPageRoute(settings: settings, builder: (context) => const OathScreen());
      case RouteNames.khatabaDashboard:
        return MaterialPageRoute(settings: settings, builder: (context) => const DashboardScreen());
      case RouteNames.homeScreen:
        return MaterialPageRoute(settings: settings, builder: (context) => const HomeScreen());
      case RouteNames.photoUploadScreen:
        return MaterialPageRoute(settings: settings, builder: (context) => const UploadImageProfileScreen());
      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }



}

