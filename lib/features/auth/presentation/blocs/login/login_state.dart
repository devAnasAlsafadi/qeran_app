import 'package:qeran/features/auth/domain/entities/user_entity.dart';

/// Which sign-in path is running. The three share one bloc, so without this
/// every button on the screen would show a spinner whichever one was tapped.
enum AuthMethod { email, google, apple }

sealed class LoginState {}

final class LoginInitial extends LoginState {}

final class LoginLoading extends LoginState {
  /// The method the user actually triggered. Only that control shows a
  /// spinner; the others stay idle (but disabled).
  final AuthMethod method;

  LoginLoading(this.method);
}

final class LoginSuccess extends LoginState {
  final UserEntity user;

  LoginSuccess(this.user);
}

final class LoginFailure extends LoginState {
  final String message;

  LoginFailure(this.message);
}
