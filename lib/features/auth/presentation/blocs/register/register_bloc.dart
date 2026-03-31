import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/features/auth/domain/usecases/register_user_usecase.dart';
import 'register_event.dart';
import 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final RegisterUserUseCase _registerUser;

  RegisterBloc({required RegisterUserUseCase registerUser})
      : _registerUser = registerUser,
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
    );
    result.fold(
      (failure) => emit(RegisterFailure(failure.message)),
      (user) => emit(RegisterSuccess(user)),
    );
  }
}
