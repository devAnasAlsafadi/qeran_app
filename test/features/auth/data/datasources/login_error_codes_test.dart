import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/core/services/google_sign_in_service.dart';
import 'package:qeran/core/services/storage_service.dart';
import 'package:qeran/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:qeran/features/auth/data/error_codes.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// #2 — login failures classify on `errorCode`, never on the server message.
///
/// The repository flattens every `ServerException` into
/// `ServerFailure(message)`, so the code has to be consumed inside the data
/// source. What leaves `loginWithEmail` must therefore always be a locale KEY:
/// the login screen translates it, and a raw English sentence from the backend
/// would otherwise be rendered verbatim into the Arabic UI.

class _MockApiConsumer extends Mock implements ApiConsumer {}

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockSharedPref extends Mock implements SharedPrefService {}

class _MockStorage extends Mock implements StorageService {}

class _MockGoogleSignIn extends Mock implements GoogleSignInService {}

void main() {
  late _MockApiConsumer api;
  late AuthRemoteDataSourceImpl ds;

  setUp(() {
    api = _MockApiConsumer();
    ds = AuthRemoteDataSourceImpl(
      firebaseAuth: _MockFirebaseAuth(),
      apiConsumer: api,
      sharedPref: _MockSharedPref(),
      secureStorage: _MockStorage(),
      googleSignIn: _MockGoogleSignIn(),
    );
  });

  /// Makes the login POST fail exactly the way `HttpConsumer` would.
  void failWith({String? errorCode, required String message}) {
    when(() => api.post(any(), body: any(named: 'body'))).thenThrow(
      CodedServerException(message: message, errorCode: errorCode),
    );
  }

  Future<String> loginErrorMessage() async {
    try {
      await ds.loginWithEmail(email: 'a@b.c', password: 'pw');
      fail('expected a ServerException');
    } on ServerException catch (e) {
      return e.message;
    }
  }

  test('hits POST /api/auth/login', () async {
    failWith(errorCode: AuthErrorCodes.invalidCredentials, message: 'nope');
    await loginErrorMessage();
    verify(
      () => api.post(EndPoints.login, body: {
        'email': 'a@b.c',
        'password': 'pw',
      }),
    ).called(1);
  });

  test('INVALID_CREDENTIALS → errors.invalid_credentials', () async {
    failWith(
      errorCode: AuthErrorCodes.invalidCredentials,
      message: 'Invalid email or password',
    );
    expect(await loginErrorMessage(), LocaleKeys.errors_invalid_credentials);
  });

  test('ACCOUNT_DEACTIVATED → errors.account_deactivated', () async {
    failWith(
      errorCode: AuthErrorCodes.accountDeactivated,
      message: 'Account is deactivated',
    );
    expect(await loginErrorMessage(), LocaleKeys.errors_account_deactivated);
  });

  test('VALIDATION_ERROR → errors.bad_request', () async {
    failWith(
      errorCode: AuthErrorCodes.validationError,
      message: 'The Email field is required.',
    );
    expect(await loginErrorMessage(), LocaleKeys.errors_bad_request);
  });

  test('the raw English server message never escapes', () async {
    // The lead regression: this exact string used to reach `.t()` on the login
    // screen and render as-is.
    failWith(errorCode: null, message: 'Invalid email or password');
    final message = await loginErrorMessage();
    expect(message, isNot(contains('Invalid email or password')));
    expect(message, LocaleKeys.errors_generic);
  });

  test('an Arabic server sentence never escapes either', () async {
    failWith(errorCode: null, message: 'البريد أو كلمة المرور غير صحيحة');
    expect(await loginErrorMessage(), LocaleKeys.errors_generic);
  });

  test('an unknown errorCode degrades to errors.generic', () async {
    failWith(errorCode: 'SOME_FUTURE_CODE', message: 'whatever the server says');
    expect(await loginErrorMessage(), LocaleKeys.errors_generic);
  });

  test('transport keys survive — a timeout stays errors.timeout', () async {
    // `HttpConsumer` already emits locale keys for transport failures. Blanket
    // "generic" would downgrade a precise message the user benefits from.
    when(() => api.post(any(), body: any(named: 'body')))
        .thenThrow(ServerException(message: LocaleKeys.errors_timeout));
    expect(await loginErrorMessage(), LocaleKeys.errors_timeout);
  });

  test('offline still bubbles untouched to the repository', () async {
    // OfflineException is NOT a ServerException — it must pass straight
    // through so `executeApiCall` can map it to OfflineFailure.
    when(() => api.post(any(), body: any(named: 'body')))
        .thenThrow(const OfflineException());
    expect(
      () => ds.loginWithEmail(email: 'a@b.c', password: 'pw'),
      throwsA(isA<OfflineException>()),
    );
  });
}
