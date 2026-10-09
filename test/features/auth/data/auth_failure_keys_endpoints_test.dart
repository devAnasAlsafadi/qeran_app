import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/auth/data/auth_failure_keys.dart';
import 'package:qeran/features/auth/data/error_codes.dart';

/// Each auth map lists exactly the codes its endpoint sends — Tariq's own
/// table (`03-api-contract.md` §12.4, his answer; Phase 4 B1, M1–M9). A code
/// an endpoint never sends is a dead entry; one it sends but the map lacks
/// reads as "something went wrong".
///
/// Two codes are left out on purpose: `OTP_SEND_FAILED` and
/// `FIREBASE_TOKEN_INVALID` (infrastructure, nothing to act on).
/// `VALIDATION_ERROR` is on every map, even where his list omits it.
void main() {
  final expected = <String, (Map<String, String>, Set<String>)>{
    'login': (
      AuthFailureKeys.login,
      {
        AuthErrorCodes.invalidCredentials,
        AuthErrorCodes.accountDeactivated,
        AuthErrorCodes.validationError,
      },
    ),
    'register-new': (
      AuthFailureKeys.register,
      {AuthErrorCodes.emailAlreadyExists, AuthErrorCodes.validationError},
    ),
    'add-phone': (
      AuthFailureKeys.addPhone,
      {
        AuthErrorCodes.phoneAlreadyRegistered,
        AuthErrorCodes.otpCooldown,
        AuthErrorCodes.userNotFound,
        AuthErrorCodes.validationError,
      },
    ),
    'verify-otp': (
      AuthFailureKeys.verifyOtp,
      {
        AuthErrorCodes.otpInvalid,
        AuthErrorCodes.otpNotFound,
        AuthErrorCodes.otpMaxAttempts,
        AuthErrorCodes.validationError,
      },
    ),
    'forgot-password': (
      AuthFailureKeys.forgotPassword,
      {AuthErrorCodes.validationError},
    ),
    'verify-forgot-password-otp': (
      AuthFailureKeys.verifyForgotPasswordOtp,
      {
        AuthErrorCodes.otpInvalid,
        AuthErrorCodes.otpNotFound,
        AuthErrorCodes.otpMaxAttempts,
        AuthErrorCodes.validationError,
      },
    ),
    'reset-password': (
      AuthFailureKeys.resetPassword,
      {
        AuthErrorCodes.otpInvalid,
        AuthErrorCodes.otpMaxAttempts,
        AuthErrorCodes.validationError,
      },
    ),
    'change-password': (
      AuthFailureKeys.changePassword,
      {
        AuthErrorCodes.invalidOldPassword,
        AuthErrorCodes.passwordMismatch,
        AuthErrorCodes.userNotFound,
        AuthErrorCodes.validationError,
      },
    ),
    'firebase-signin': (
      AuthFailureKeys.firebaseSignIn,
      {AuthErrorCodes.accountDeactivated, AuthErrorCodes.validationError},
    ),
  };

  for (final MapEntry(key: endpoint, value: (map, codes)) in expected.entries) {
    test('$endpoint maps exactly the codes it sends', () {
      expect(map.keys.toSet(), codes);
    });
  }
}
