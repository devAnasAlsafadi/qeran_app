import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/safe_emit.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../../data/error_codes.dart';
import '../../../domain/usecases/change_password_usecase.dart';
import 'change_password_state.dart';

/// Drives the signed-in user's password change as a single in-flight
/// mutation. Field-level rules (length/regex/confirm/differs) are enforced by
/// the sheet's form before this is called; here we only run the request and
/// route its outcome.
///
/// Emits a locale KEY plus the slot it belongs in. The key comes from the data
/// source, which classifies on `errorCode`; the SLOT is decided here and only
/// here, from that same code.
class ChangePasswordCubit extends Cubit<ChangePasswordState> with SafeEmit<ChangePasswordState> {
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
      clearError: true,
      errorSlot: ChangePasswordErrorSlot.none,
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
        errorKey: _keyFor(failure),
        errorSlot: _slotFor(failure),
        version: state.version + 1,
      )),
      (_) => emit(state.copyWith(
        status: ChangePasswordStatus.success,
        clearError: true,
        errorSlot: ChangePasswordErrorSlot.none,
        version: state.version + 1,
      )),
    );
  }

  /// The data source already classified, so a coded failure's message IS a
  /// locale key. Anything else never went through it and is not shown.
  String _keyFor(Failure failure) => switch (failure) {
    OfflineFailure() => LocaleKeys.errors_offline,
    CodedServerFailure() => failure.message,
    _ => LocaleKeys.errors_generic,
  };

  /// The ONLY place placement is decided.
  ///
  /// Anchoring under the current-password field is claimed for exactly one
  /// code, because it is the only one that is about that field. Everything
  /// else — a mismatch the client already checked, an unrecognised code, a
  /// fault, being offline — is announced without blaming an input. Defaulting
  /// the unknown case to the field was the bug: it told the member their
  /// password was wrong whenever the app did not understand the answer.
  ChangePasswordErrorSlot _slotFor(Failure failure) {
    final code = failure is CodedServerFailure ? failure.errorCode : null;
    return code == AuthErrorCodes.invalidOldPassword
        ? ChangePasswordErrorSlot.field
        : ChangePasswordErrorSlot.banner;
  }
}
