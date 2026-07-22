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
import 'package:qeran/features/matchmaker/affiliate/presentation/screens/matchmaker_affiliate_screen.dart';
import 'package:qeran/features/matchmaker/colleagues/presentation/screens/matchmaker_colleagues_directory_screen.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/compatibility_case.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/presentation/screens/matchmaker_case_detail_screen.dart';
import 'package:qeran/features/matchmaker/conversations/domain/entities/matchmaker_conversation.dart';
import 'package:qeran/features/matchmaker/conversations/presentation/screens/matchmaker_user_chat_screen.dart';
import 'package:qeran/features/matchmaker/home/presentation/screens/matchmaker_home_screen.dart';
import 'package:qeran/features/matchmaker/interests/presentation/screens/matchmaker_interests_screen.dart';
import 'package:qeran/features/matchmaker/notifications/presentation/screens/matchmaker_notifications_screen.dart';
import 'package:qeran/features/matchmaker/users/presentation/screens/matchmaker_user_profile_screen.dart';
import 'package:qeran/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:qeran/features/onboarding/presentation/screens/on_boarding_screen.dart';
import 'package:qeran/features/profile/presentation/full_profile_details_args.dart';
import 'package:qeran/features/profile/presentation/screens/full_profile_details_screen.dart';
import 'package:qeran/features/profile/presentation/screens/profile_hub_screen.dart';
import 'package:qeran/features/settings/presentation/screens/settings_support_screen.dart';
import 'package:qeran/features/block/presentation/screens/blocked_users_screen.dart';
import 'package:qeran/features/legal/domain/entities/legal_document_type.dart';
import 'package:qeran/features/legal/presentation/screens/legal_screen.dart';
import 'package:qeran/features/questionnaire/domain/entities/question_entity.dart';
import 'package:qeran/features/questionnaire/presentation/screens/gender_selection/gender_selection_screen.dart';
import 'package:qeran/features/questionnaire/presentation/screens/questionnaire_flow/questionnaire_flow_screen.dart';
import 'package:qeran/features/splash/presentation/screens/splash_screen.dart';
import 'package:qeran/features/subscriptions/domain/entities/subscription_plan.dart';
import 'package:qeran/features/subscriptions/presentation/screens/packages_screen.dart';
import 'package:qeran/features/subscriptions/presentation/screens/subscription_details_screen.dart';
import 'package:qeran/features/subscriptions/presentation/screens/purchase_success_screen.dart';
import 'package:qeran/features/subscriptions/presentation/screens/purchase_failure_screen.dart';

class AppRouter {
  /// Helper for building smooth, luxury page transitions (Fade + subtle Slide).
  static PageRouteBuilder<T> _buildSmoothRoute<T>({
    required RouteSettings settings,
    required Widget Function(BuildContext context) builder,
    Duration duration = const Duration(milliseconds: 400),
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: Duration(milliseconds: (duration.inMilliseconds * 0.80).round()),
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnim = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubicEmphasized,
          reverseCurve: Curves.easeInOutCubic,
        );
        return FadeTransition(
          opacity: curvedAnim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0.0),
              end: Offset.zero,
            ).animate(curvedAnim),
            child: child,
          ),
        );
      },
    );
  }

  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.splashScreen:
        return _buildSmoothRoute(
          settings: settings,
          builder: (context) => const SplashScreen(),
        );

      case RouteNames.onboarding:
        return _buildSmoothRoute(
          settings: settings,
          builder: (context) => const OnBoardingScreen(),
        );

      case RouteNames.loginScreen:
        return _buildSmoothRoute(
          settings: settings,
          builder: (context) => const LoginScreen(),
        );

      case RouteNames.registerScreen:
        return _buildSmoothRoute(
          settings: settings,
          builder: (context) => const RegisterScreen(),
        );
      case RouteNames.forgotPasswordEmail:
        return _buildSmoothRoute(
          settings: settings,
          builder: (context) => const ForgetPassScreen(),
        );
      case RouteNames.resetPassword:
        return _buildSmoothRoute(
          settings: settings,
          builder: (context) => const ResetPassScreen(),
        );
      case RouteNames.whatsappInput:
        return _buildSmoothRoute(
          settings: settings,
          builder: (context) => const WhatsappInputScreen(),
        );
      case RouteNames.whatsappVerification:
        return _buildSmoothRoute(
          settings: settings,
          builder: (context) => const WhatsappVerificationScreen(),
        );
      case RouteNames.genderSelectionScreen:
        return _buildSmoothRoute(
          settings: settings,
          builder: (context) => const GenderSelectionScreen(),
        );
      case RouteNames.questionsScreen:
        final questions = settings.arguments as List<QuestionEntity>?;
        return _buildSmoothRoute(
          settings: settings,
          builder: (context) => QuestionnaireFlowScreen(questions: questions),
        );
      case RouteNames.oathScreen:
        final answersPayload =
            settings.arguments is List<Map<String, dynamic>>
                ? settings.arguments as List<Map<String, dynamic>>
                : null;
        return _buildSmoothRoute(
          settings: settings,
          builder: (context) => OathScreen(answersPayload: answersPayload),
        );
      case RouteNames.matchmakerHome:
        return _buildSmoothRoute(
          settings: settings,
          builder: (context) => const MatchmakerHomeScreen(),
        );
      case RouteNames.matchmakerNotifications:
        return _buildSmoothRoute(
          settings: settings,
          builder: (context) => const MatchmakerNotificationsScreen(),
        );
      case RouteNames.matchmakerAccount:
        return _buildSmoothRoute(
          settings: settings,
          builder: (context) => const MatchmakerAccountScreen(),
        );
      case RouteNames.matchmakerColleaguesDirectory:
        return _buildSmoothRoute(
          settings: settings,
          builder: (context) => const MatchmakerColleaguesDirectoryScreen(),
        );
      case RouteNames.matchmakerAffiliate:
        return _buildSmoothRoute(
          settings: settings,
          builder: (context) => const MatchmakerAffiliateScreen(),
        );
      case RouteNames.matchmakerUserProfile:
        final userId = settings.arguments as String?;
        return _buildSmoothRoute(
          settings: settings,
          builder: (context) => userId == null
              ? Scaffold(
                  body: Center(
                    child: Text('Missing args for ${settings.name}'),
                  ),
                )
              : MatchmakerUserProfileScreen(userId: userId),
        );
      case RouteNames.matchmakerCaseDetail:
        final caseArg = settings.arguments as CompatibilityCase?;
        return _buildSmoothRoute(
          settings: settings,
          builder: (context) => caseArg == null
              ? Scaffold(
                  body: Center(
                    child: Text('Missing args for ${settings.name}'),
                  ),
                )
              : MatchmakerCaseDetailScreen(caseItem: caseArg),
        );
      case RouteNames.matchmakerInterests:
        final userId = settings.arguments as String?;
        return _buildSmoothRoute(
          settings: settings,
          builder: (context) => userId == null
              ? Scaffold(
                  body: Center(
                    child: Text('Missing args for ${settings.name}'),
                  ),
                )
              : MatchmakerInterestsScreen(userId: userId),
        );
      case RouteNames.matchmakerUserChat:
        final conv = settings.arguments as MatchmakerConversation?;
        return _buildSmoothRoute(
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
        return _buildSmoothRoute(
          settings: settings,
          builder: (context) => const HomeScreen(),
        );
      case RouteNames.photoUploadScreen:
        return _buildSmoothRoute(
          settings: settings,
          builder: (context) => const UploadImageProfileScreen(),
        );
      case RouteNames.notifications:
        return _buildSmoothRoute(
          settings: settings,
          builder: (context) => const NotificationsScreen(),
        );
      case RouteNames.packagesScreen:
        return _buildSmoothRoute(
          settings: settings,
          builder: (context) => const PackagesScreen(),
        );
      case RouteNames.subscriptionDetails:
        return _buildSmoothRoute(
          settings: settings,
          builder: (context) => const SubscriptionDetailsScreen(),
        );
      case RouteNames.purchaseSuccess:
        final purchasedPlan = settings.arguments as SubscriptionPlan?;
        return _buildSmoothRoute(
          settings: settings,
          builder: (context) => PurchaseSuccessScreen(plan: purchasedPlan),
        );
      case RouteNames.purchaseFailure:
        final failureMessageKey = settings.arguments as String?;
        return _buildSmoothRoute(
          settings: settings,
          builder: (context) =>
              PurchaseFailureScreen(messageKey: failureMessageKey),
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
      case RouteNames.fullProfileDetails:
        final args = settings.arguments as FullProfileDetailsArgs?;
        return PageRouteBuilder(
          settings: settings,
          transitionDuration: const Duration(milliseconds: 1100),
          reverseTransitionDuration: const Duration(milliseconds: 850),
          pageBuilder: (context, animation, secondaryAnimation) => args == null
              ? Scaffold(
                  body: Center(
                    child: Text('Missing args for ${settings.name}'),
                  ),
                )
              : FullProfileDetailsScreen(args: args),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnim = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubicEmphasized,
              reverseCurve: Curves.easeInOutCubic,
            );
            return FadeTransition(
              opacity: curvedAnim,
              child: child,
            );
          },
        );
      case RouteNames.myProfile:
        return _buildSmoothRoute(
          settings: settings,
          builder: (context) => const ProfileHubScreen(),
        );
      case RouteNames.settingsSupport:
        return _buildSmoothRoute(
          settings: settings,
          builder: (context) => const SettingsSupportScreen(),
        );
      case RouteNames.settingsTerms:
        return _buildSmoothRoute(
          settings: settings,
          builder: (context) => LegalScreen(
            initialType: settings.arguments is LegalDocumentType
                ? settings.arguments as LegalDocumentType
                : LegalDocumentType.termsAndConditions,
          ),
        );
      case RouteNames.blockedUsers:
        return _buildSmoothRoute(
          settings: settings,
          builder: (context) => const BlockedUsersScreen(),
        );
      default:
        return _buildSmoothRoute(
          settings: settings,
          builder: (context) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
