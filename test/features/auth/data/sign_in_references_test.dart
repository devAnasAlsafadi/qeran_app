import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:qeran/core/data/repositories/base_repository.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/features/auth/data/sign_in_references.dart';
import 'package:qeran/features/auth/presentation/sign_in_reference.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class _Repo with BaseRepository {}

/// The reference under a failed Google or Apple sign-in names the stage and
/// the cause (run 7, item 3b): a screenshot is how we learn why it failed.
void main() {
  group('Google\'s sheet', () {
    test('every code has its own reference', () {
      final refs = GoogleSignInExceptionCode.values.map(googleReference);
      expect(refs.toSet(), hasLength(GoogleSignInExceptionCode.values.length));
      expect(googleReference(GoogleSignInExceptionCode.canceled), 'G-CANCEL');
      expect(
        googleReference(GoogleSignInExceptionCode.clientConfigurationError),
        'G-CLIENT-CONFIG',
      );
    });

    test('a network error inside Google\'s exchange is G-NET', () {
      expect(
        googlePlatformReference(
          PlatformException(code: 'NSURLErrorDomain: -1009'),
        ),
        'G-NET-1009',
      );
    });

    test('another system error is G-OS, with its number', () {
      expect(
        googlePlatformReference(
          PlatformException(code: 'org.openid.appauth.general: -3'),
        ),
        'G-OS-3',
      );
      expect(
        googlePlatformReference(PlatformException(code: 'x: 7')),
        'G-OS-7',
      );
      expect(googlePlatformReference(PlatformException(code: 'odd')), 'G-OS');
    });

    test('anything else is the app\'s own: G-APP', () {
      expect(googlePlatformReference(StateError('wiring')), 'G-APP');
    });
  });

  test('Apple\'s sheet: every code has its own reference', () {
    final refs = AuthorizationErrorCode.values.map(appleReference);
    expect(refs.toSet(), hasLength(AuthorizationErrorCode.values.length));
    expect(appleReference(AuthorizationErrorCode.canceled), 'A-CANCEL');
  });

  test('Firebase: its own code', () {
    expect(firebaseReference('internal-error'), 'F-internal-error');
  });

  group('the failure that reaches the screen', () {
    test('a sheet or Firebase failure keeps the reference it was given', () {
      expect(
        signInReference(const AuthFailure(message: 'k', reference: 'G-NET-1')),
        'G-NET-1',
      );
    });

    test('our server: its errorCode, or its status', () {
      expect(
        signInReference(
          const CodedServerFailure(
            message: 'k',
            errorCode: 'ACCOUNT_DEACTIVATED',
          ),
        ),
        'S-ACCOUNT_DEACTIVATED',
      );
      expect(
        signInReference(
          const CodedServerFailure(
            message: 'k',
            errorCode: null,
            statusCode: 503,
          ),
        ),
        'S-503',
      );
    });

    test('a timeout, a server failure without a code, no network', () {
      expect(
        signInReference(
          const ServerFailure(message: LocaleKeys.errors_timeout),
        ),
        'S-TIMEOUT',
      );
      expect(signInReference(const ServerFailure(message: 'k')), 'S');
      expect(signInReference(const OfflineFailure()), 'NET-OFFLINE');
    });

    test('the repository carries an exception\'s reference across', () async {
      final result = await _Repo().executeApiCall<void>(
        () => throw AuthException(message: 'k', reference: 'A-FAILED'),
      );
      expect(
        result,
        const Left<Failure, void>(
          AuthFailure(message: 'k', reference: 'A-FAILED'),
        ),
      );
    });
  });
}
