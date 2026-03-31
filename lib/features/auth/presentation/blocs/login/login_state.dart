import 'package:qeran/features/auth/domain/entities/user_entity.dart';

sealed class LoginState {}

final class LoginInitial extends LoginState {}

final class LoginLoading extends LoginState {}

final class LoginSuccess extends LoginState {
  final UserEntity user;

  LoginSuccess(this.user);
}

final class LoginFailure extends LoginState {
  final String message;

  LoginFailure(this.message);
}
