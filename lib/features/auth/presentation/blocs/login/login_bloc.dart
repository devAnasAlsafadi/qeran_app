import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/features/auth/domain/usecases/login_with_apple_usecase.dart';
import 'package:qeran/features/auth/domain/usecases/login_with_email_usecase.dart';
import 'package:qeran/features/auth/domain/usecases/login_with_google_usecase.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final LoginWithEmailUseCase _loginWithEmail;
  final LoginWithGoogleUseCase _loginWithGoogle;
  final LoginWithAppleUseCase _loginWithApple;

  LoginBloc({
    required LoginWithEmailUseCase loginWithEmail,
    required LoginWithGoogleUseCase loginWithGoogle,
    required LoginWithAppleUseCase loginWithApple,
  })  : _loginWithEmail = loginWithEmail,
        _loginWithGoogle = loginWithGoogle,
        _loginWithApple = loginWithApple,
        super(LoginInitial()) {
    on<LoginWithEmailRequested>(_onLoginWithEmail);
    on<LoginWithGoogleRequested>(_onLoginWithGoogle);
    on<LoginWithAppleRequested>(_onLoginWithApple);
  }

  Future<void> _onLoginWithEmail(
    LoginWithEmailRequested event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());
    final result = await _loginWithEmail(email: event.email, password: event.password);
    result.fold(
      (failure) => emit(LoginFailure(failure.message)),
      (user) => emit(LoginSuccess(user)),
    );
  }

  Future<void> _onLoginWithGoogle(
    LoginWithGoogleRequested event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());
    final result = await _loginWithGoogle();
    result.fold(
      (failure) => emit(LoginFailure(failure.message)),
      (user) => emit(LoginSuccess(user)),
    );
  }

  Future<void> _onLoginWithApple(
    LoginWithAppleRequested event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());
    final result = await _loginWithApple();
    result.fold(
      (failure) => emit(LoginFailure(failure.message)),
      (user) => emit(LoginSuccess(user)),
    );
  }
}
