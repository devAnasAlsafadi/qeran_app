import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/features/auth/domain/usecases/request_forgot_password_otp_usecase.dart';
import 'package:qeran/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:qeran/features/auth/domain/usecases/verify_forgot_password_otp_usecase.dart';
import 'password_reset_event.dart';
import 'password_reset_state.dart';

class PasswordResetBloc extends Bloc<PasswordResetEvent, PasswordResetState> {
  final RequestForgotPasswordOtpUseCase _requestReset;
  final VerifyForgotPasswordOtpUseCase _verifyOtp;
  final ResetPasswordUseCase _resetPassword;

  PasswordResetBloc({
    required RequestForgotPasswordOtpUseCase requestReset,
    required VerifyForgotPasswordOtpUseCase verifyOtp,
    required ResetPasswordUseCase resetPassword,
  })  : _requestReset = requestReset,
        _verifyOtp = verifyOtp,
        _resetPassword = resetPassword,
        super(PasswordResetInitial()) {
    on<RequestForgotPasswordOtpRequested>(_onRequestReset);
    on<VerifyForgotPasswordOtpRequested>(_onVerifyOtp);
    on<ResetPasswordRequested>(_onResetPassword);
  }

  Future<void> _onRequestReset(
    RequestForgotPasswordOtpRequested event,
    Emitter<PasswordResetState> emit,
  ) async {
    emit(PasswordResetLoading());
    final result = await _requestReset(phoneNumber: event.phoneNumber);
    result.fold(
      (failure) => emit(PasswordResetFailure(failure.message)),
      (_) => emit(PasswordResetOtpSent(event.phoneNumber)),
    );
  }

  Future<void> _onVerifyOtp(
    VerifyForgotPasswordOtpRequested event,
    Emitter<PasswordResetState> emit,
  ) async {
    emit(PasswordResetLoading());
    final result = await _verifyOtp(
      phoneNumber: event.phoneNumber,
      code: event.code,
    );
    result.fold(
      (failure) => emit(PasswordResetFailure(failure.message)),
      (_) => emit(PasswordResetOtpVerified(phoneNumber: event.phoneNumber, otp: event.code)),
    );
  }

  Future<void> _onResetPassword(
    ResetPasswordRequested event,
    Emitter<PasswordResetState> emit,
  ) async {
    emit(PasswordResetLoading());
    final result = await _resetPassword(
      phoneNumber: event.phoneNumber,
      code: event.code,
      newPassword: event.newPassword,
    );
    result.fold(
      (failure) => emit(PasswordResetFailure(failure.message)),
      (_) => emit(PasswordResetSuccess()),
    );
  }
}
