import 'package:qeran/generated/locale_keys.g.dart';

import 'error_codes.dart';

/// `errorCode` → locale key maps for the auth endpoints, passed to
/// `serverFailureKey`. They live here rather than in the data source so
/// classifying another call adds a map entry, not another 500-line file.
///
/// Only codes the backend actually sends belong here. An unmapped code is not
/// a gap to paper over with a guess — it degrades to `errors.generic`, which
/// is localized and correct, just less specific.
///
/// Most maps below are deliberately EMPTY: `Auth/login` is the only endpoint
/// whose codes are confirmed. An empty map is not an oversight — it routes
/// every failure to the transport key or `errors.generic`, which is the
/// correctness fix. Specificity comes later, one confirmed code at a time.
class AuthFailureKeys {
  AuthFailureKeys._();

  /// `POST Auth/login` — the only endpoint with confirmed codes today.
  static const Map<String, String> login = {
    AuthErrorCodes.invalidCredentials: LocaleKeys.errors_invalid_credentials,
    AuthErrorCodes.accountDeactivated: LocaleKeys.errors_account_deactivated,
    AuthErrorCodes.validationError: LocaleKeys.errors_bad_request,
  };

  /// `POST Auth/register-new`. A duplicate-email code would belong here.
  static const Map<String, String> register = {};

  /// `POST Auth/add-phone`. A duplicate-phone code would belong here.
  static const Map<String, String> addPhone = {};

  /// `POST Auth/verify-otp`. Expired/invalid-code codes would belong here.
  static const Map<String, String> verifyOtp = {};

  /// `POST Auth/forgot-password`.
  static const Map<String, String> forgotPassword = {};

  /// `POST Auth/verify-forgot-password-otp`.
  static const Map<String, String> verifyForgotPasswordOtp = {};

  /// `POST Auth/reset-password`.
  static const Map<String, String> resetPassword = {};

  /// `POST Auth/firebase-signin` — backs BOTH Google and Apple sign-in.
  /// Firebase SDK errors are a different source and stay with
  /// `_mapFirebaseError`; this map is only for the server's own envelope.
  static const Map<String, String> firebaseSignIn = {};
}
