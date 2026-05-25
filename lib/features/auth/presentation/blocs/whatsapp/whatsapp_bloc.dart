import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/features/auth/domain/usecases/send_whatsapp_otp_usecase.dart';
import 'package:qeran/features/auth/domain/usecases/verify_whatsapp_otp_usecase.dart';
import 'package:qeran/features/devices/application/device_bootstrap_service.dart';
import '../user_session/user_session_cubit.dart';
import 'whatsapp_event.dart';
import 'whatsapp_state.dart';

class WhatsappBloc extends Bloc<WhatsappEvent, WhatsappState> {
  final SendWhatsappOtpUseCase _sendOtp;
  final VerifyWhatsappOtpUseCase _verifyOtp;
  final DeviceBootstrapService _deviceBootstrap;
  final UserSessionCubit _userSession;

  WhatsappBloc({
    required SendWhatsappOtpUseCase sendOtp,
    required VerifyWhatsappOtpUseCase verifyOtp,
    required DeviceBootstrapService deviceBootstrap,
    required UserSessionCubit userSession,
  }) : _sendOtp = sendOtp,
       _verifyOtp = verifyOtp,
       _deviceBootstrap = deviceBootstrap,
       _userSession = userSession,
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
      (user) {
        _userSession.onAuthenticated(user);
        emit(WhatsappOtpVerified(user));
        if (user.token != null && user.token!.isNotEmpty) {
          _deviceBootstrap.linkSilently();
        }
      },
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
