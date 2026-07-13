import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/features/auth/domain/usecases/register_user_usecase.dart';
import '../user_session/user_session_cubit.dart';
import 'register_event.dart';
import 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final RegisterUserUseCase _registerUser;
  final UserSessionCubit _userSession;

  RegisterBloc({
    required RegisterUserUseCase registerUser,
    required UserSessionCubit userSession,
  }) : _registerUser = registerUser,
       _userSession = userSession,
       super(RegisterInitial()) {
    on<RegisterRequested>(_onRegister);
  }

  Future<void> _onRegister(
    RegisterRequested event,
    Emitter<RegisterState> emit,
  ) async {
    emit(RegisterLoading());
    final result = await _registerUser(
      name: event.name,
      email: event.email,
      password: event.password,
      referralCode: event.referralCode,
    );
    if (emit.isDone) return;
    result.fold(
      (failure) => emit(RegisterFailure(failure.message)),
      (user) {
        // Tolerated: register-new returns a partial user with an empty
        // token; the session still tracks the pending identity until
        // verify-otp issues a real JWT.
        _userSession.onAuthenticated(user);
        emit(RegisterSuccess(user));
      },
    );
  }
}
