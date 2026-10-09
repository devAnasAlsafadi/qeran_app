import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/core/errors/retry_after.dart';
import 'package:qeran/core/services/google_sign_in_service.dart';
import 'package:qeran/core/services/storage_service.dart';
import 'package:qeran/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:qeran/features/auth/data/error_codes.dart';
import 'package:qeran/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:qeran/generated/locale_keys.g.dart';

class _MockApiConsumer extends Mock implements ApiConsumer {}

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockSharedPref extends Mock implements SharedPrefService {}

class _MockStorage extends Mock implements StorageService {}

class _MockGoogleSignIn extends Mock implements GoogleSignInService {}

/// B2 (M8): add-phone's `OTP_COOLDOWN` carries `data.retryAfterSeconds`. The
/// data source still hands up a locale key, but no longer drops the code and
/// the wait on the way.
void main() {
  late _MockApiConsumer api;
  late AuthRemoteDataSourceImpl ds;

  setUp(() {
    api = _MockApiConsumer();
    final sharedPref = _MockSharedPref();
    ds = AuthRemoteDataSourceImpl(
      firebaseAuth: _MockFirebaseAuth(),
      apiConsumer: api,
      sharedPref: sharedPref,
      secureStorage: _MockStorage(),
      googleSignIn: _MockGoogleSignIn(),
    );
    when(() => sharedPref.get<String>(any())).thenAnswer((_) async => 'uid-1');
    when(() => api.post(any(), body: any(named: 'body'))).thenThrow(
      CodedServerException(
        message: 'Please wait before requesting another code',
        errorCode: AuthErrorCodes.otpCooldown,
        data: {'retryAfterSeconds': 42},
      ),
    );
  });

  test('the data source keeps the code and the wait, with a key', () async {
    await expectLater(
      ds.sendWhatsappOtp(phoneNumber: '+962790000000'),
      throwsA(
        isA<CodedServerException>()
            .having((e) => e.message, 'message', LocaleKeys.errors_otp_cooldown)
            .having((e) => e.errorCode, 'code', AuthErrorCodes.otpCooldown)
            .having((e) => e.data, 'data', {'retryAfterSeconds': 42}),
      ),
    );
  });

  test('the repository hands up a failure that says 42 seconds', () async {
    final result = await AuthRepositoryImpl(
      ds,
    ).sendWhatsappOtp(phoneNumber: '+962790000000');

    final failure = result.fold((f) => f, (_) => fail('expected a failure'));
    expect(failure.message, LocaleKeys.errors_otp_cooldown);
    expect(retryAfterOf(failure), const Duration(seconds: 42));
  });

  test('an uncoded failure is still just its key', () async {
    when(
      () => api.post(any(), body: any(named: 'body')),
    ).thenThrow(ServerException(message: 'Something broke'));

    await expectLater(
      ds.sendWhatsappOtp(phoneNumber: '+962790000000'),
      throwsA(
        isA<ServerException>()
            .having((e) => e, 'type', isNot(isA<CodedServerException>()))
            .having((e) => e.message, 'message', LocaleKeys.errors_generic),
      ),
    );
  });
}
