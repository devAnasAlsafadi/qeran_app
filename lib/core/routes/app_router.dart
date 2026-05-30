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
import 'package:qeran/features/likes/presentation/screens/match_success_screen.dart';
import 'package:qeran/features/matchmaker/account/presentation/screens/matchmaker_account_screen.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/compatibility_case.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/presentation/screens/matchmaker_case_detail_screen.dart';
import 'package:qeran/features/matchmaker/conversations/domain/entities/matchmaker_conversation.dart';
import 'package:qeran/features/matchmaker/conversations/presentation/screens/matchmaker_user_chat_screen.dart';
import 'package:qeran/features/matchmaker/home/presentation/screens/matchmaker_home_screen.dart';
import 'package:qeran/features/matchmaker/notifications/presentation/screens/matchmaker_notifications_screen.dart';
import 'package:qeran/features/matchmaker/users/presentation/screens/matchmaker_editable_answers_screen.dart';
import 'package:qeran/features/matchmaker/users/presentation/screens/matchmaker_user_profile_screen.dart';
import 'package:qeran/features/likes/presentation/screens/matchmaker_chat_screen.dart';
import 'package:qeran/features/notifications/presentation/screens/notifications_demo_screen.dart';
import 'package:qeran/features/onboarding/presentation/screens/on_boarding_screen.dart';
import 'package:qeran/features/profile/presentation/full_profile_details_args.dart';
import 'package:qeran/features/profile/presentation/screens/full_profile_details_screen.dart';
import 'package:qeran/features/profile/presentation/screens/my_profile_screen.dart';
import 'package:qeran/features/questionnaire/domain/entities/question_entity.dart';
import 'package:qeran/features/questionnaire/presentation/screens/gender_selection/gender_selection_screen.dart';
import 'package:qeran/features/questionnaire/presentation/screens/questionnaire_flow/questionnaire_flow_screen.dart';
import 'package:qeran/features/splash/presentation/screens/splash_screen.dart';
import 'package:qeran/features/subscriptions/presentation/screens/packages_screen.dart';
import 'package:qeran/features/subscriptions/presentation/screens/subscription_details_screen.dart';
import 'package:qeran/features/subscriptions/presentation/screens/subscription_purchase_screen.dart';

class AppRouter {
  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.splashScreen:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => const SplashScreen(),
        );

      case RouteNames.onboarding:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => const OnBoardingScreen(),
        );

      case RouteNames.loginScreen:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => const LoginScreen(),
        );

      case RouteNames.registerScreen:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => const RegisterScreen(),
        );
      case RouteNames.forgotPasswordEmail:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => const ForgetPassScreen(),
        );
      case RouteNames.resetPassword:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => const ResetPassScreen(),
        );
      case RouteNames.whatsappInput:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => const WhatsappInputScreen(),
        );
      case RouteNames.whatsappVerification:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => const WhatsappVerificationScreen(),
        );
      case RouteNames.genderSelectionScreen:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => const GenderSelectionScreen(),
        );
      case RouteNames.questionsScreen:
        final questions = settings.arguments as List<QuestionEntity>?;
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => QuestionnaireFlowScreen(questions: questions),
        );
      case RouteNames.oathScreen:
        final answersPayload =
            settings.arguments is List<Map<String, dynamic>>
                ? settings.arguments as List<Map<String, dynamic>>
                : null;
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => OathScreen(answersPayload: answersPayload),
        );
      case RouteNames.matchmakerHome:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => const MatchmakerHomeScreen(),
        );
      case RouteNames.matchmakerNotifications:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => const MatchmakerNotificationsScreen(),
        );
      case RouteNames.matchmakerAccount:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => const MatchmakerAccountScreen(),
        );
      case RouteNames.matchmakerUserProfile:
        final userId = settings.arguments as String?;
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => userId == null
              ? Scaffold(
                  body: Center(
                    child: Text('Missing args for ${settings.name}'),
                  ),
                )
              : MatchmakerUserProfileScreen(userId: userId),
        );
      case RouteNames.matchmakerEditableAnswers:
        final userId = settings.arguments as String?;
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => userId == null
              ? Scaffold(
                  body: Center(
                    child: Text('Missing args for ${settings.name}'),
                  ),
                )
              : MatchmakerEditableAnswersScreen(userId: userId),
        );
      case RouteNames.matchmakerCaseDetail:
        final caseArg = settings.arguments as CompatibilityCase?;
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => caseArg == null
              ? Scaffold(
                  body: Center(
                    child: Text('Missing args for ${settings.name}'),
                  ),
                )
              : MatchmakerCaseDetailScreen(caseItem: caseArg),
        );
      case RouteNames.matchmakerUserChat:
        final conv = settings.arguments as MatchmakerConversation?;
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => conv == null
              ? Scaffold(
                  body: Center(
                    child: Text('Missing args for ${settings.name}'),
                  ),
                )
              : MatchmakerUserChatScreen(conversation: conv),
        );
      case RouteNames.homeScreen:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => const HomeScreen(),
        );
      case RouteNames.photoUploadScreen:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => const UploadImageProfileScreen(),
        );
      case RouteNames.notificationsDemo:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => const NotificationsDemoScreen(),
        );
      case RouteNames.packagesScreen:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => const PackagesScreen(),
        );
      case RouteNames.subscriptionDetails:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => const SubscriptionDetailsScreen(),
        );
      case RouteNames.subscriptionPurchase:
        final args = settings.arguments as SubscriptionPurchaseArgs?;
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => args == null
              ? Scaffold(
                  body: Center(
                    child: Text('Missing args for ${settings.name}'),
                  ),
                )
              : SubscriptionPurchaseScreen(args: args),
        );
      case RouteNames.matchSuccess:
        final args = settings.arguments as MatchSuccessArgs?;
        return PageRouteBuilder<void>(
          settings: settings,
          opaque: true,
          transitionDuration: const Duration(milliseconds: 280),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          pageBuilder: (_, _, _) => MatchSuccessScreen(args: args),
          transitionsBuilder: (_, animation, _, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      case RouteNames.matchmakerChat:
        final chatArgs = settings.arguments as MatchmakerChatScreenArgs?;
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => chatArgs == null
              ? Scaffold(
                  body: Center(
                    child: Text('Missing args for ${settings.name}'),
                  ),
                )
              : MatchmakerChatScreen(args: chatArgs),
        );
      case RouteNames.fullProfileDetails:
        final args = settings.arguments as FullProfileDetailsArgs?;
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => args == null
              ? Scaffold(
                  body: Center(
                    child: Text('Missing args for ${settings.name}'),
                  ),
                )
              : FullProfileDetailsScreen(args: args),
        );
      case RouteNames.myProfile:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => const MyProfileScreen(),
        );
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
