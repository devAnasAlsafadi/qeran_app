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
/// Each map lists exactly the codes its endpoint sends, from Tariq's own table
/// (`03-api-contract.md` §12.4, his answer; Phase 4 B1). A code missing from a
/// map degrades to `errors.generic`; a code the endpoint never sends would be
/// dead weight, so none is kept "just in case".
///
/// `VALIDATION_ERROR` is on EVERY map. It went global in the same batch, so a
/// malformed request now reports itself the same way from any endpoint, and a
/// map that omitted it would degrade "check what you typed" into "something
/// went wrong" on that one screen alone.
///
/// Two live codes are deliberately absent. `OTP_SEND_FAILED` and
/// `FIREBASE_TOKEN_INVALID` are infrastructure failures with nothing the
/// member can act on, so a specific sentence would only be a more precise way
/// of saying "try again".
class AuthFailureKeys {
  AuthFailureKeys._();

  /// `POST Auth/login`.
  static const Map<String, String> login = {
    AuthErrorCodes.invalidCredentials: LocaleKeys.errors_invalid_credentials,
    AuthErrorCodes.accountDeactivated: LocaleKeys.errors_account_deactivated,
    AuthErrorCodes.validationError: LocaleKeys.errors_bad_request,
  };

  /// `POST Auth/register-new`. A password mismatch arrives as
  /// `VALIDATION_ERROR`, not as `PASSWORD_MISMATCH`.
  static const Map<String, String> register = {
    AuthErrorCodes.emailAlreadyExists: LocaleKeys.errors_email_already_exists,
    AuthErrorCodes.validationError: LocaleKeys.errors_bad_request,
  };

  /// `POST Auth/add-phone` — also the OTP SEND path, hence the cooldown.
  /// `USER_NOT_FOUND` here is an account deleted mid-flow (Q7).
  static const Map<String, String> addPhone = {
    AuthErrorCodes.phoneAlreadyRegistered:
        LocaleKeys.errors_phone_already_registered,
    AuthErrorCodes.otpCooldown: LocaleKeys.errors_otp_cooldown,
    AuthErrorCodes.userNotFound: LocaleKeys.errors_account_not_found,
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

  /// `POST Auth/forgot-password` sends no code at all: it always answers with
  /// a generic success, so an address never leaks whether it has an account.
  /// `VALIDATION_ERROR` stays, as on every map.
  static const Map<String, String> forgotPassword = {
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
    AuthErrorCodes.otpInvalid: LocaleKeys.errors_otp_invalid,
    AuthErrorCodes.otpMaxAttempts: LocaleKeys.errors_otp_max_attempts,
    AuthErrorCodes.validationError: LocaleKeys.errors_bad_request,
  };

  /// `POST Auth/change-password`. Lives on a SEPARATE data source from the
  /// seven above, which is why it was unclassified until now.
  ///
  /// Where each of these is shown is decided once, in `ChangePasswordCubit` —
  /// only the wrong-current-password case is anchored under a field, because
  /// it is the only one that is about that field.
  static const Map<String, String> changePassword = {
    AuthErrorCodes.invalidOldPassword:
        LocaleKeys.settings_change_password_incorrect,
    AuthErrorCodes.passwordMismatch: LocaleKeys.errors_password_mismatch,
    AuthErrorCodes.userNotFound: LocaleKeys.errors_account_not_found,
    AuthErrorCodes.validationError: LocaleKeys.errors_bad_request,
  };

  /// `POST Auth/firebase-signin` — backs BOTH Google and Apple sign-in.
  /// Firebase SDK errors are a different source and stay with
  /// `_mapFirebaseError`; this map is only for the server's own envelope. A
  /// deactivated account reads as it does on email login.
  static const Map<String, String> firebaseSignIn = {
    AuthErrorCodes.accountDeactivated: LocaleKeys.errors_account_deactivated,
    AuthErrorCodes.validationError: LocaleKeys.errors_bad_request,
  };
}
