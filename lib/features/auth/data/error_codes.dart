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

  /// Malformed/rejected input.
  static const String validationError = 'VALIDATION_ERROR';
}
