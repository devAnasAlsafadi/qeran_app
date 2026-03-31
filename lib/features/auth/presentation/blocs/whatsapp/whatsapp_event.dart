sealed class WhatsappEvent {}

final class SendOtpRequested extends WhatsappEvent {
  final String phoneNumber;

  SendOtpRequested(this.phoneNumber);
}

final class VerifyOtpRequested extends WhatsappEvent {
  final String phoneNumber;
  final String otp;

  VerifyOtpRequested({required this.phoneNumber, required this.otp});
}

final class ResendOtpRequested extends WhatsappEvent {
  final String phoneNumber;

  ResendOtpRequested(this.phoneNumber);
}
