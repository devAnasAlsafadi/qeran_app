import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/features/auth/domain/usecases/send_whatsapp_otp_usecase.dart';
import 'package:qeran/features/auth/domain/usecases/verify_whatsapp_otp_usecase.dart';
import 'whatsapp_event.dart';
import 'whatsapp_state.dart';

class WhatsappBloc extends Bloc<WhatsappEvent, WhatsappState> {
  final SendWhatsappOtpUseCase _sendOtp;
  final VerifyWhatsappOtpUseCase _verifyOtp;

  WhatsappBloc({
    required SendWhatsappOtpUseCase sendOtp,
    required VerifyWhatsappOtpUseCase verifyOtp,
  })  : _sendOtp = sendOtp,
        _verifyOtp = verifyOtp,
        super(WhatsappInitial()) {
    on<SendOtpRequested>(_onSendOtp);
    on<VerifyOtpRequested>(_onVerifyOtp);
    on<ResendOtpRequested>(_onResendOtp);
  }

  Future<void> _onSendOtp(
    SendOtpRequested event,
    Emitter<WhatsappState> emit,
  ) async {
    emit(WhatsappLoading());
    final result = await _sendOtp(phoneNumber: event.phoneNumber);
    result.fold(
      (failure) => emit(WhatsappFailure(failure.message)),
      (_) => emit(WhatsappOtpSent(event.phoneNumber)),
    );
  }

  Future<void> _onVerifyOtp(
    VerifyOtpRequested event,
    Emitter<WhatsappState> emit,
  ) async {
    emit(WhatsappLoading());
    final result = await _verifyOtp(
      phoneNumber: event.phoneNumber,
      otp: event.otp,
    );
    result.fold(
      (failure) => emit(WhatsappFailure(failure.message)),
      (user) => emit(WhatsappOtpVerified(user)),
    );
  }

  Future<void> _onResendOtp(
    ResendOtpRequested event,
    Emitter<WhatsappState> emit,
  ) async {
    emit(WhatsappLoading());
    final result = await _sendOtp(phoneNumber: event.phoneNumber);
    result.fold(
      (failure) => emit(WhatsappFailure(failure.message)),
      (_) => emit(WhatsappOtpSent(event.phoneNumber, isResend: true)),
    );
  }
}
