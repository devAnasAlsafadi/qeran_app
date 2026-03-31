sealed class LoginEvent {}

final class LoginWithEmailRequested extends LoginEvent {
  final String email;
  final String password;

  LoginWithEmailRequested({required this.email, required this.password});
}

final class LoginWithGoogleRequested extends LoginEvent {}

final class LoginWithAppleRequested extends LoginEvent {}
