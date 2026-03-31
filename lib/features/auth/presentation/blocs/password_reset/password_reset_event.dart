sealed class PasswordResetEvent {}

final class RequestForgotPasswordOtpRequested extends PasswordResetEvent {
  final String phoneNumber;

  RequestForgotPasswordOtpRequested(this.phoneNumber);
}

final class VerifyForgotPasswordOtpRequested extends PasswordResetEvent {
  final String phoneNumber;
  final String code;

  VerifyForgotPasswordOtpRequested({required this.phoneNumber, required this.code});
}

final class ResetPasswordRequested extends PasswordResetEvent {
  final String phoneNumber;
  final String code;
  final String newPassword;

  ResetPasswordRequested({
    required this.phoneNumber,
    required this.code,
    required this.newPassword,
  });
}
