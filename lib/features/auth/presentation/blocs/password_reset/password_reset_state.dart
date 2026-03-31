sealed class PasswordResetState {}

final class PasswordResetInitial extends PasswordResetState {}

final class PasswordResetLoading extends PasswordResetState {}

final class PasswordResetOtpSent extends PasswordResetState {
  final String phoneNumber;

  PasswordResetOtpSent(this.phoneNumber);
}

final class PasswordResetOtpVerified extends PasswordResetState {
  final String phoneNumber;
  final String otp;

  PasswordResetOtpVerified({required this.phoneNumber, required this.otp});
}

final class PasswordResetSuccess extends PasswordResetState {}

final class PasswordResetFailure extends PasswordResetState {
  final String message;

  PasswordResetFailure(this.message);
}
