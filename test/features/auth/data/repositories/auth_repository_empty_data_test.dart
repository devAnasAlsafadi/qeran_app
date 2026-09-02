import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/domain/entities/success_response.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:qeran/features/auth/data/models/user_model.dart';
import 'package:qeran/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// A `status: 1` envelope carrying no payload used to surface the server's own
/// `message` — English prose — or the hardcoded literal `'Unknown Error'`.
/// Both reached the UI in every locale, so an Arabic user saw English.
///
/// There is no `errorCode` to classify on here, so the only correct outcome is
/// the generic localized key. These tests kill both regressions: restoring the
/// prose fallback, and restoring the English literal.
class _MockDataSource extends Mock implements AuthRemoteDataSource {}

/// What the backend would send: success envelope, no user object, English text.
SuccessResponse<UserModel> emptyPayload() => const SuccessResponse<UserModel>(
  status: 1,
  data: null,
  message: 'Operation completed but no user was returned',
);

void main() {
  late _MockDataSource ds;
  late AuthRepositoryImpl repository;

  setUp(() {
    ds = _MockDataSource();
    repository = AuthRepositoryImpl(ds);
  });

  void expectGenericKey(Failure failure) {
    // Equality pins the fix; the two `isNot`s kill the two mutants directly.
    expect(failure.message, LocaleKeys.errors_generic);
    expect(failure.message, isNot(contains('no user was returned')));
    expect(failure.message, isNot('Unknown Error'));
  }

  test('loginWithEmail: empty payload yields the generic key, not prose', () async {
    when(() => ds.loginWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => emptyPayload());

    final result = await repository.loginWithEmail(
      email: 'a@b.c',
      password: 'pw',
    );

    result.fold(expectGenericKey, (_) => fail('expected a Failure'));
  });

  test('verifyWhatsappOtp: empty payload yields the generic key, not prose', () async {
    when(() => ds.verifyWhatsappOtp(
          phoneNumber: any(named: 'phoneNumber'),
          otp: any(named: 'otp'),
        )).thenAnswer((_) async => emptyPayload());

    final result = await repository.verifyWhatsappOtp(
      phoneNumber: '970599123456',
      otp: '1111',
    );

    result.fold(expectGenericKey, (_) => fail('expected a Failure'));
  });

  test('registerUser: defensive branch also degrades to the generic key', () async {
    when(() => ds.registerUser(
          name: any(named: 'name'),
          email: any(named: 'email'),
          password: any(named: 'password'),
          referralCode: any(named: 'referralCode'),
        )).thenAnswer((_) async => emptyPayload());

    final result = await repository.registerUser(
      name: 'Ahmed',
      email: 'a@b.c',
      password: 'pw',
    );

    result.fold(expectGenericKey, (_) => fail('expected a Failure'));
  });

  test('loginWithGoogle: defensive branch also degrades to the generic key', () async {
    when(() => ds.loginWithGoogle()).thenAnswer((_) async => emptyPayload());
    final result = await repository.loginWithGoogle();
    result.fold(expectGenericKey, (_) => fail('expected a Failure'));
  });

  test('loginWithApple: defensive branch also degrades to the generic key', () async {
    when(() => ds.loginWithApple()).thenAnswer((_) async => emptyPayload());
    final result = await repository.loginWithApple();
    result.fold(expectGenericKey, (_) => fail('expected a Failure'));
  });
}
