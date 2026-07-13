sealed class RegisterEvent {}

final class RegisterRequested extends RegisterEvent {
  final String name;
  final String email;
  final String password;

  /// Optional affiliate referral code. Null/empty is valid and non-blocking —
  /// the data layer omits it from the request body when empty.
  final String? referralCode;

  RegisterRequested({
    required this.name,
    required this.email,
    required this.password,
    this.referralCode,
  });
}
