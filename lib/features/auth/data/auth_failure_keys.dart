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
/// Batch 26 filled these in: the codes below are live on the server. Which
/// endpoint sends which is INFERRED from the code names, not confirmed per
/// route — that is safe to get wrong in only one direction. A code listed on a
/// map whose endpoint never sends it is inert; a code sent by an endpoint that
/// does not list it degrades to `errors.generic`. Neither shows the member
/// anything false.
///
/// `VALIDATION_ERROR` is on EVERY map. It went global in the same batch, so a
/// malformed request now reports itself the same way from any endpoint, and a
/// map that omitted it would degrade "check what you typed" into "something
/// went wrong" on that one screen alone.
///
/// Three live codes are deliberately absent. `OTP_SEND_FAILED` and
/// `FIREBASE_TOKEN_INVALID` are infrastructure failures with nothing the
/// member can act on, so a specific sentence would only be a more precise way
/// of saying "try again". `INVALID_OLD_PASSWORD` belongs to
/// `Auth/change-password`, whose data source is not classified at all.
class AuthFailureKeys {
  AuthFailureKeys._();

  /// `POST Auth/login`.
  static const Map<String, String> login = {
    AuthErrorCodes.invalidCredentials: LocaleKeys.errors_invalid_credentials,
    AuthErrorCodes.accountDeactivated: LocaleKeys.errors_account_deactivated,
    AuthErrorCodes.validationError: LocaleKeys.errors_bad_request,
  };

  /// `POST Auth/register-new`.
  static const Map<String, String> register = {
    AuthErrorCodes.emailAlreadyExists: LocaleKeys.errors_email_already_exists,
    AuthErrorCodes.passwordMismatch: LocaleKeys.errors_password_mismatch,
    AuthErrorCodes.validationError: LocaleKeys.errors_bad_request,
  };

  /// `POST Auth/add-phone` — also the OTP SEND path, hence the cooldown.
  static const Map<String, String> addPhone = {
    AuthErrorCodes.phoneAlreadyRegistered:
        LocaleKeys.errors_phone_already_registered,
    AuthErrorCodes.otpCooldown: LocaleKeys.errors_otp_cooldown,
    AuthErrorCodes.validationError: LocaleKeys.errors_bad_request,
  };

  /// `POST Auth/verify-otp`. `OTP_INVALID` covers wrong AND expired under one
  /// message — the server merges them on purpose and the UI must not undo it.
  static const Map<String, String> verifyOtp = {
    AuthErrorCodes.otpInvalid: LocaleKeys.errors_otp_invalid,
    AuthErrorCodes.otpNotFound: LocaleKeys.errors_otp_not_found,
    AuthErrorCodes.otpMaxAttempts: LocaleKeys.errors_otp_max_attempts,
    AuthErrorCodes.validationError: LocaleKeys.errors_bad_request,
  };

  /// `POST Auth/forgot-password` — sends an OTP, so it can cool down too.
  static const Map<String, String> forgotPassword = {
    AuthErrorCodes.userNotFound: LocaleKeys.errors_account_not_found,
    AuthErrorCodes.otpCooldown: LocaleKeys.errors_otp_cooldown,
    AuthErrorCodes.validationError: LocaleKeys.errors_bad_request,
  };

  /// `POST Auth/verify-forgot-password-otp` — same OTP trio as [verifyOtp].
  static const Map<String, String> verifyForgotPasswordOtp = {
    AuthErrorCodes.otpInvalid: LocaleKeys.errors_otp_invalid,
    AuthErrorCodes.otpNotFound: LocaleKeys.errors_otp_not_found,
    AuthErrorCodes.otpMaxAttempts: LocaleKeys.errors_otp_max_attempts,
    AuthErrorCodes.validationError: LocaleKeys.errors_bad_request,
  };

  /// `POST Auth/reset-password` — carries the OTP with the new password, so a
  /// spent or wrong code surfaces here rather than on the verify step.
  static const Map<String, String> resetPassword = {
    AuthErrorCodes.passwordMismatch: LocaleKeys.errors_password_mismatch,
    AuthErrorCodes.otpInvalid: LocaleKeys.errors_otp_invalid,
    AuthErrorCodes.validationError: LocaleKeys.errors_bad_request,
  };

  /// `POST Auth/firebase-signin` — backs BOTH Google and Apple sign-in.
  /// Firebase SDK errors are a different source and stay with
  /// `_mapFirebaseError`; this map is only for the server's own envelope.
  static const Map<String, String> firebaseSignIn = {
    AuthErrorCodes.socialAccountAlreadyLinked:
        LocaleKeys.errors_social_account_already_linked,
    AuthErrorCodes.validationError: LocaleKeys.errors_bad_request,
  };
}
