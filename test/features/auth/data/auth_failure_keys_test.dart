import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/core/errors/server_error_classifier.dart';
import 'package:qeran/features/auth/data/auth_failure_keys.dart';
import 'package:qeran/features/auth/data/error_codes.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Batch 26's codes, asserted through the real classifier rather than by
/// reading the maps back. The maps are only half the contract — the other half
/// is `serverFailureKey` preferring the mapped key over the server's prose,
/// and degrading an unmapped code to a generic key instead of leaking it.
///
/// Every expectation names the EXACT key. Asserting merely "some locale key"
/// would pass while every code collapsed to `errors.generic`, which is the
/// failure this whole wave exists to prevent.
String keyFor(String? code, Map<String, String> map) => serverFailureKey(
  CodedServerException(
    // The English DataAnnotations prose the server really sends. If any of
    // these tests ever sees it in the result, it reached the UI.
    message: 'The Email field is required.',
    errorCode: code,
  ),
  codeKeys: map,
);

void main() {
  group('a live code resolves to its own message', () {
    final cases = <String, ({String code, Map<String, String> map, String key})>{
      'register — duplicate email': (
        code: AuthErrorCodes.emailAlreadyExists,
        map: AuthFailureKeys.register,
        key: LocaleKeys.errors_email_already_exists,
      ),
      'register — password mismatch': (
        code: AuthErrorCodes.passwordMismatch,
        map: AuthFailureKeys.register,
        key: LocaleKeys.errors_password_mismatch,
      ),
      'add-phone — duplicate number': (
        code: AuthErrorCodes.phoneAlreadyRegistered,
        map: AuthFailureKeys.addPhone,
        key: LocaleKeys.errors_phone_already_registered,
      ),
      'add-phone — cooldown': (
        code: AuthErrorCodes.otpCooldown,
        map: AuthFailureKeys.addPhone,
        key: LocaleKeys.errors_otp_cooldown,
      ),
      'verify-otp — wrong or expired': (
        code: AuthErrorCodes.otpInvalid,
        map: AuthFailureKeys.verifyOtp,
        key: LocaleKeys.errors_otp_invalid,
      ),
      'verify-otp — none outstanding': (
        code: AuthErrorCodes.otpNotFound,
        map: AuthFailureKeys.verifyOtp,
        key: LocaleKeys.errors_otp_not_found,
      ),
      'verify-otp — attempts spent': (
        code: AuthErrorCodes.otpMaxAttempts,
        map: AuthFailureKeys.verifyOtp,
        key: LocaleKeys.errors_otp_max_attempts,
      ),
      'forgot-password — no such account': (
        code: AuthErrorCodes.userNotFound,
        map: AuthFailureKeys.forgotPassword,
        key: LocaleKeys.errors_account_not_found,
      ),
      'forgot-password — cooldown': (
        code: AuthErrorCodes.otpCooldown,
        map: AuthFailureKeys.forgotPassword,
        key: LocaleKeys.errors_otp_cooldown,
      ),
      'verify-forgot-otp — wrong or expired': (
        code: AuthErrorCodes.otpInvalid,
        map: AuthFailureKeys.verifyForgotPasswordOtp,
        key: LocaleKeys.errors_otp_invalid,
      ),
      'verify-forgot-otp — attempts spent': (
        code: AuthErrorCodes.otpMaxAttempts,
        map: AuthFailureKeys.verifyForgotPasswordOtp,
        key: LocaleKeys.errors_otp_max_attempts,
      ),
      'reset-password — password mismatch': (
        code: AuthErrorCodes.passwordMismatch,
        map: AuthFailureKeys.resetPassword,
        key: LocaleKeys.errors_password_mismatch,
      ),
      'reset-password — wrong or expired otp': (
        code: AuthErrorCodes.otpInvalid,
        map: AuthFailureKeys.resetPassword,
        key: LocaleKeys.errors_otp_invalid,
      ),
      'change-password — wrong current password': (
        code: AuthErrorCodes.invalidOldPassword,
        map: AuthFailureKeys.changePassword,
        key: LocaleKeys.settings_change_password_incorrect,
      ),
      'change-password — server-side mismatch': (
        code: AuthErrorCodes.passwordMismatch,
        map: AuthFailureKeys.changePassword,
        key: LocaleKeys.errors_password_mismatch,
      ),
      'firebase-signin — already linked': (
        code: AuthErrorCodes.socialAccountAlreadyLinked,
        map: AuthFailureKeys.firebaseSignIn,
        key: LocaleKeys.errors_social_account_already_linked,
      ),
    };

    cases.forEach((name, c) {
      test(name, () {
        expect(
          keyFor(c.code, c.map),
          c.key,
          reason: 'the exact key, not just any key — a code collapsed to '
              'errors.generic would pass a weaker assertion',
        );
      });
    });
  });

  group('a malformed request reads the same from every endpoint', () {
    // VALIDATION_ERROR went global in the same batch. Mapped on login alone it
    // would have said "check what you typed" there and "something went wrong"
    // everywhere else, for the identical server response.
    test('register — the input-error key, not the generic one', () {
      expect(
        keyFor(AuthErrorCodes.validationError, AuthFailureKeys.register),
        LocaleKeys.errors_bad_request,
        reason: 'the exact key: errors.generic is also a valid key and would '
            'pass a weaker assertion while saying nothing useful',
      );
    });

    test('every auth map agrees, login included', () {
      for (final entry in {
        'login': AuthFailureKeys.login,
        'register': AuthFailureKeys.register,
        'addPhone': AuthFailureKeys.addPhone,
        'verifyOtp': AuthFailureKeys.verifyOtp,
        'forgotPassword': AuthFailureKeys.forgotPassword,
        'verifyForgotPasswordOtp': AuthFailureKeys.verifyForgotPasswordOtp,
        'resetPassword': AuthFailureKeys.resetPassword,
        'firebaseSignIn': AuthFailureKeys.firebaseSignIn,
        'changePassword': AuthFailureKeys.changePassword,
      }.entries) {
        expect(
          keyFor(AuthErrorCodes.validationError, entry.value),
          LocaleKeys.errors_bad_request,
          reason: '${entry.key} would tell the member something different '
              'about the same response',
        );
      }
    });
  });

  test('change-password tells its two codes apart', () {
    expect(
      keyFor(AuthErrorCodes.invalidOldPassword, AuthFailureKeys.changePassword),
      isNot(
        keyFor(AuthErrorCodes.passwordMismatch, AuthFailureKeys.changePassword),
      ),
      reason: 'one accuses the current password and the other does not — '
          'sharing a key makes them the same event on screen',
    );
  });

  group('the codes left unmapped stay generic on purpose', () {
    // Nothing the member can do differently, so a specific sentence would be
    // a more precise way of saying "try again".
    test('OTP_SEND_FAILED on the send path', () {
      expect(
        keyFor(AuthErrorCodes.otpSendFailed, AuthFailureKeys.addPhone),
        LocaleKeys.errors_generic,
      );
    });

    test('FIREBASE_TOKEN_INVALID on social sign-in', () {
      expect(
        keyFor(
          AuthErrorCodes.firebaseTokenInvalid,
          AuthFailureKeys.firebaseSignIn,
        ),
        LocaleKeys.errors_generic,
      );
    });

    test('a code nobody has mapped yet, and a missing code', () {
      expect(
        keyFor('SOMETHING_TARIQ_ADDS_NEXT', AuthFailureKeys.register),
        LocaleKeys.errors_generic,
      );
      expect(keyFor(null, AuthFailureKeys.register), LocaleKeys.errors_generic);
    });
  });

  test('the server sentence never survives classification', () {
    for (final map in [
      AuthFailureKeys.login,
      AuthFailureKeys.register,
      AuthFailureKeys.addPhone,
      AuthFailureKeys.verifyOtp,
      AuthFailureKeys.forgotPassword,
      AuthFailureKeys.verifyForgotPasswordOtp,
      AuthFailureKeys.resetPassword,
      AuthFailureKeys.firebaseSignIn,
      AuthFailureKeys.changePassword,
    ]) {
      for (final code in [...map.keys, 'UNMAPPED', null]) {
        expect(
          keyFor(code, map),
          matches(kLocaleKeyShape),
          reason: 'a locale key, never the English prose the server sends',
        );
      }
    }
  });
}
