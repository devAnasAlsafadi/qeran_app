import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/errors/errors.dart';

import '../../../domain/usecases/change_password_usecase.dart';
import 'change_password_state.dart';

/// Drives the signed-in user's password change as a single in-flight
/// mutation. Locale-key free — the sheet maps [ChangePasswordError] to copy.
/// Field-level rules (length/regex/confirm/differs) are enforced by the
/// sheet's form before this is called; here we only run the request and route
/// its outcome (offline vs. wrong current password).
class ChangePasswordCubit extends Cubit<ChangePasswordState> {
  final ChangePasswordUseCase _changePassword;

  ChangePasswordCubit(this._changePassword)
      : super(const ChangePasswordState());

  Future<void> submit({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (state.isSubmitting) return;
    emit(state.copyWith(
      status: ChangePasswordStatus.submitting,
      error: ChangePasswordError.none,
    ));
    final result = await _changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(
        status: ChangePasswordStatus.failure,
        error: failure is OfflineFailure
            ? ChangePasswordError.offline
            : ChangePasswordError.incorrectCurrent,
        version: state.version + 1,
      )),
      (_) => emit(state.copyWith(
        status: ChangePasswordStatus.success,
        error: ChangePasswordError.none,
        version: state.version + 1,
      )),
    );
  }
}
