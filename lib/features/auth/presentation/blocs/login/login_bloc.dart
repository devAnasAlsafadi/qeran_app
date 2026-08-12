import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/features/auth/domain/usecases/login_with_apple_usecase.dart';
import 'package:qeran/features/auth/domain/usecases/login_with_email_usecase.dart';
import 'package:qeran/features/auth/domain/usecases/login_with_google_usecase.dart';
import 'package:qeran/features/devices/application/device_bootstrap_service.dart';
import '../user_session/user_session_cubit.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final LoginWithEmailUseCase _loginWithEmail;
  final LoginWithGoogleUseCase _loginWithGoogle;
  final LoginWithAppleUseCase _loginWithApple;
  final DeviceBootstrapService _deviceBootstrap;
  final UserSessionCubit _userSession;

  LoginBloc({
    required LoginWithEmailUseCase loginWithEmail,
    required LoginWithGoogleUseCase loginWithGoogle,
    required LoginWithAppleUseCase loginWithApple,
    required DeviceBootstrapService deviceBootstrap,
    required UserSessionCubit userSession,
  }) : _loginWithEmail = loginWithEmail,
       _loginWithGoogle = loginWithGoogle,
       _loginWithApple = loginWithApple,
       _deviceBootstrap = deviceBootstrap,
       _userSession = userSession,
       super(LoginInitial()) {
    on<LoginWithEmailRequested>(_onLoginWithEmail);
    on<LoginWithGoogleRequested>(_onLoginWithGoogle);
    on<LoginWithAppleRequested>(_onLoginWithApple);
  }

  Future<void> _onLoginWithEmail(
    LoginWithEmailRequested event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading(AuthMethod.email));
    final result = await _loginWithEmail(
      email: event.email,
      password: event.password,
    );
    if (emit.isDone) return;
    result.fold(
      (failure) => emit(LoginFailure(failure.message)),
      (user) {
        _userSession.onAuthenticated(user);
        emit(LoginSuccess(user));
        _linkIfTokenIssued(user.token);
      },
    );
  }

  Future<void> _onLoginWithGoogle(
    LoginWithGoogleRequested event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading(AuthMethod.google));
    final result = await _loginWithGoogle();
    if (emit.isDone) return;
    result.fold(
      (failure) => emit(LoginFailure(failure.message)),
      (user) {
        _userSession.onAuthenticated(user);
        emit(LoginSuccess(user));
        _linkIfTokenIssued(user.token);
      },
    );
  }

  Future<void> _onLoginWithApple(
    LoginWithAppleRequested event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading(AuthMethod.apple));
    final result = await _loginWithApple();
    if (emit.isDone) return;
    result.fold(
      (failure) => emit(LoginFailure(failure.message)),
      (user) {
        _userSession.onAuthenticated(user);
        emit(LoginSuccess(user));
        _linkIfTokenIssued(user.token);
      },
    );
  }

  void _linkIfTokenIssued(String? token) {
    if (token == null || token.isEmpty) return;
    _deviceBootstrap.linkSilently();
  }
}
