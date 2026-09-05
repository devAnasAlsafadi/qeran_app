/// Backend `errorCode` constants for the auth domain. Bare strings (same
/// convention as the likes / chat / compatibility-cases modules) so data
/// sources and tests reference them without importing presentation code.
///
/// Classification happens on THESE, never on the response `message` — the
/// server sends English prose there and it must never reach the UI.
class AuthErrorCodes {
  AuthErrorCodes._();

  /// Wrong email or password on `POST /api/auth/login`.
  static const String invalidCredentials = 'INVALID_CREDENTIALS';

  /// The account exists but has been deactivated.
  static const String accountDeactivated = 'ACCOUNT_DEACTIVATED';

  /// Malformed/rejected input. Global since batch 26 — it can now arrive from
  /// any endpoint, not just login.
  static const String validationError = 'VALIDATION_ERROR';

  // ── Batch 26. Live on the server; each is mapped by the endpoint that can
  // actually send it, in `AuthFailureKeys`. A code listed on the wrong map is
  // inert (it degrades to the generic key), never wrong.

  /// `POST Auth/register-new` — the address already has an account.
  static const String emailAlreadyExists = 'EMAIL_ALREADY_EXISTS';

  /// `POST Auth/add-phone` — the number already belongs to an account.
  static const String phoneAlreadyRegistered = 'PHONE_ALREADY_REGISTERED';

  /// Wrong OTP **or** an expired one. Deliberately ONE code on the server so a
  /// caller cannot learn which — do not try to split it into two messages.
  static const String otpInvalid = 'OTP_INVALID';

  /// No OTP is outstanding for this number at all.
  static const String otpNotFound = 'OTP_NOT_FOUND';

  /// The attempt limit for the current OTP is spent.
  static const String otpMaxAttempts = 'OTP_MAX_ATTEMPTS';

  /// A new OTP was requested too soon after the last one.
  static const String otpCooldown = 'OTP_COOLDOWN';

  /// The OTP could not be delivered. Infrastructure, not the member — stays
  /// unmapped so it reads as a generic failure.
  static const String otpSendFailed = 'OTP_SEND_FAILED';

  /// No account matches the details given (forgot-password).
  static const String userNotFound = 'USER_NOT_FOUND';

  /// The password and its confirmation disagree, per the server.
  static const String passwordMismatch = 'PASSWORD_MISMATCH';

  /// The current password given to `Auth/change-password` is wrong. Mapped in
  /// the change-password work, not here — that data source is not classified.
  static const String invalidOldPassword = 'INVALID_OLD_PASSWORD';

  /// The Firebase ID token was rejected. Internal — stays unmapped.
  static const String firebaseTokenInvalid = 'FIREBASE_TOKEN_INVALID';

  /// The social identity is already attached to a different account.
  static const String socialAccountAlreadyLinked =
      'SOCIAL_ACCOUNT_ALREADY_LINKED';
}
