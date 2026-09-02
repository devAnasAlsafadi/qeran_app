import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/core/services/google_sign_in_service.dart';
import 'package:qeran/core/services/storage_service.dart';
import 'package:qeran/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Every envelope-only auth call must consume the failure inside the data
/// source and hand up a locale KEY. The repository flattens the exception and
/// loses the `errorCode`, so a call left on the raw `_apiConsumer.post` would
/// send the server's English prose to `.t()` and render it verbatim.
///
/// One test per call: reverting any single one to an unclassified post fails
/// exactly that test.

class _MockApiConsumer extends Mock implements ApiConsumer {}

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockSharedPref extends Mock implements SharedPrefService {}

class _MockStorage extends Mock implements StorageService {}

class _MockGoogleSignIn extends Mock implements GoogleSignInService {}

/// Exactly what `HttpConsumer` throws for a `status: 0` envelope whose code we
/// do not (yet) map: English prose, no usable code.
const _prose = 'The email address is already registered to another account';

void main() {
  late _MockApiConsumer api;
  late _MockSharedPref sharedPref;
  late AuthRemoteDataSourceImpl ds;

  setUp(() {
    api = _MockApiConsumer();
    sharedPref = _MockSharedPref();
    ds = AuthRemoteDataSourceImpl(
      firebaseAuth: _MockFirebaseAuth(),
      apiConsumer: api,
      sharedPref: sharedPref,
      secureStorage: _MockStorage(),
      googleSignIn: _MockGoogleSignIn(),
    );
    when(() => sharedPref.get<String>(any())).thenAnswer((_) async => 'uid-1');
    when(() => sharedPref.save(any(), any())).thenAnswer((_) async => true);
    when(() => api.post(any(), body: any(named: 'body'))).thenThrow(
      CodedServerException(message: _prose, errorCode: null),
    );
  });

  /// Runs [call] and returns the message that escaped the data source.
  Future<String> escapedMessage(Future<void> Function() call) async {
    try {
      await call();
      fail('expected a ServerException');
    } on ServerException catch (e) {
      return e.message;
    }
  }

  void expectClassified(String message) {
    expect(message, LocaleKeys.errors_generic);
    expect(message, isNot(contains('already registered')));
  }

  test('registerUser classifies', () async {
    expectClassified(await escapedMessage(
      () => ds.registerUser(name: 'A', email: 'a@b.c', password: 'pw'),
    ));
  });

  test('sendWhatsappOtp classifies', () async {
    expectClassified(
      await escapedMessage(() => ds.sendWhatsappOtp(phoneNumber: '970599')),
    );
  });

  test('verifyWhatsappOtp classifies', () async {
    expectClassified(await escapedMessage(
      () => ds.verifyWhatsappOtp(phoneNumber: '970599', otp: '1111'),
    ));
  });

  test('requestForgotPasswordOtp classifies', () async {
    expectClassified(await escapedMessage(
      () => ds.requestForgotPasswordOtp(phoneNumber: '970599'),
    ));
  });

  test('verifyForgotPasswordOtp classifies', () async {
    expectClassified(await escapedMessage(
      () => ds.verifyForgotPasswordOtp(phoneNumber: '970599', code: '1111'),
    ));
  });

  test('resetPassword classifies', () async {
    expectClassified(await escapedMessage(
      () => ds.resetPassword(
        phoneNumber: '970599',
        code: '1111',
        newPassword: 'newpw',
      ),
    ));
  });
}
