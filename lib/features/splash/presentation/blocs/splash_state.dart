abstract class SplashState {}

class SplashInitial extends SplashState {}
class NavigateToOnboarding extends SplashState {}
class NavigateToLogin extends SplashState {}
class NavigateToHome extends SplashState {}
class NavigateToKhatabaDashboard extends SplashState {}
class NavigateToIncompleteProfile extends SplashState {
  final String step; // 'questions', 'oath', 'photos'
  NavigateToIncompleteProfile(this.step);
}