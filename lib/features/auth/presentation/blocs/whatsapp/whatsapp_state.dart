import 'package:qeran/features/auth/domain/entities/user_entity.dart';

sealed class WhatsappState {}

final class WhatsappInitial extends WhatsappState {}

final class WhatsappLoading extends WhatsappState {}

final class WhatsappOtpSent extends WhatsappState {
  final String phoneNumber;
  final bool isResend;

  WhatsappOtpSent(this.phoneNumber, {this.isResend = false});
}

final class WhatsappOtpVerified extends WhatsappState {
  final UserEntity user;

  WhatsappOtpVerified(this.user);
}

final class WhatsappFailure extends WhatsappState {
  final String message;

  WhatsappFailure(this.message);
}
