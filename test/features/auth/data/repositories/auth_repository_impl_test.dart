// ignore_for_file: lines_longer_than_80_chars

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/domain/entities/success_response.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:qeran/features/auth/data/models/user_model.dart';
import 'package:qeran/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:qeran/features/auth/domain/entities/user_entity.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

/// Mocktail creates a fake implementation of the interface automatically.
/// Any method not explicitly stubbed with [when] will throw a [MissingStubError],
/// which forces tests to be explicit about what they expect.
class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

// ---------------------------------------------------------------------------
// Shared fixtures — reused across all test groups
// ---------------------------------------------------------------------------

/// A realistic UserModel that the (mocked) DataSource returns.
const tUserModel = UserModel(
  id: 'user-abc-123',
  name: 'Ahmed Hassan',
  email: 'ahmed@example.com',
  token: 'jwt-token-xyz',
);

/// The Entity that AuthRepositoryImpl must produce from the model above.
/// Derived via [UserModel.toEntity] so this test stays in sync with real mapping.
final tUserEntity = tUserModel.toEntity();

/// Reusable success wrapper around [tUserModel].
final tUserSuccessResponse = SuccessResponse<UserModel>(
  status: 1,
  data: tUserModel,
  message: 'Success',
);

// ---------------------------------------------------------------------------
// Test suite
// ---------------------------------------------------------------------------

void main() {
  late MockAuthRemoteDataSource mockDataSource;
  late AuthRepositoryImpl repository;

  // [setUp] runs before every single test, giving each test a fresh instance.
  setUp(() {
    mockDataSource = MockAuthRemoteDataSource();
    repository = AuthRepositoryImpl(mockDataSource);
  });

  // ─────────────────────────────────────────────────────────────────────────
  // registerUser
  // ─────────────────────────────────────────────────────────────────────────
  group('registerUser', () {
    const tName = 'Ahmed Hassan';
    const tEmail = 'ahmed@example.com';
    const tPassword = 'secret123';

    test(
      'SUCCESS → returns Right(UserEntity) when DataSource completes normally',
      () async {
        // ── Arrange ────────────────────────────────────────────────────────
        // Tell the mock: when registerUser is called with these exact args,
        // return a successful SuccessResponse containing a UserModel.
        when(
          () => mockDataSource.registerUser(
            name: tName,
            email: tEmail,
            password: tPassword,
          ),
        ).thenAnswer((_) async => tUserSuccessResponse);

        // ── Act ────────────────────────────────────────────────────────────
        final result = await repository.registerUser(
          name: tName,
          email: tEmail,
          password: tPassword,
        );

        // ── Assert ─────────────────────────────────────────────────────────
        // The repository must return the correctly mapped entity wrapped in Right.
        expect(result, equals(Right<Failure, UserEntity>(tUserEntity)));

        // Confirm the DataSource was called exactly once with the right params.
        verify(
          () => mockDataSource.registerUser(
            name: tName,
            email: tEmail,
            password: tPassword,
          ),
        ).called(1);
      },
    );

    test(
      'FAILURE → returns Left(ServerFailure) when DataSource throws ServerException',
      () async {
        // ── Arrange ────────────────────────────────────────────────────────
        // Simulate the DataSource encountering an API / network error.
        when(
          () => mockDataSource.registerUser(
            name: any(named: 'name'),
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(
          ServerException(message: 'البريد الإلكتروني مستخدم بالفعل'),
        );

        // ── Act ────────────────────────────────────────────────────────────
        final result = await repository.registerUser(
          name: tName,
          email: tEmail,
          password: tPassword,
        );

        // ── Assert ─────────────────────────────────────────────────────────
        // BaseRepository.executeApiCall must catch ServerException → ServerFailure.
        expect(
          result,
          equals(
            Left<Failure, UserEntity>(
              const ServerFailure(message: 'البريد الإلكتروني مستخدم بالفعل'),
            ),
          ),
        );
      },
    );

    test(
      'FAILURE → returns Left(ServerFailure) when DataSource returns null data',
      () async {
        // ── Arrange ────────────────────────────────────────────────────────
        // The API responded with status=1 but no user in the body.
        // AuthRepositoryImpl throws ServerException in this case.
        when(
          () => mockDataSource.registerUser(
            name: any(named: 'name'),
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer(
          (_) async => SuccessResponse<UserModel>(
            status: 1,
            data: null,
            message: 'Unknown Error',
          ),
        );

        // ── Act ────────────────────────────────────────────────────────────
        final result = await repository.registerUser(
          name: tName,
          email: tEmail,
          password: tPassword,
        );

        // ── Assert ─────────────────────────────────────────────────────────
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Expected a Left(ServerFailure) but got Right'),
        );
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // loginWithEmail
  // ─────────────────────────────────────────────────────────────────────────
  group('loginWithEmail', () {
    const tEmail = 'ahmed@example.com';
    const tPassword = 'secret123';

    test(
      'SUCCESS → returns Right(UserEntity) when DataSource completes normally',
      () async {
        // ── Arrange ────────────────────────────────────────────────────────
        when(
          () =>
              mockDataSource.loginWithEmail(email: tEmail, password: tPassword),
        ).thenAnswer((_) async => tUserSuccessResponse);

        // ── Act ────────────────────────────────────────────────────────────
        final result = await repository.loginWithEmail(
          email: tEmail,
          password: tPassword,
        );

        // ── Assert ─────────────────────────────────────────────────────────
        expect(result, equals(Right<Failure, UserEntity>(tUserEntity)));
        verify(
          () =>
              mockDataSource.loginWithEmail(email: tEmail, password: tPassword),
        ).called(1);
      },
    );

    test(
      'FAILURE → returns Left(ServerFailure) when DataSource throws ServerException',
      () async {
        // ── Arrange ────────────────────────────────────────────────────────
        when(
          () => mockDataSource.loginWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(ServerException(message: 'كلمة المرور غير صحيحة'));

        // ── Act ────────────────────────────────────────────────────────────
        final result = await repository.loginWithEmail(
          email: tEmail,
          password: tPassword,
        );

        // ── Assert ─────────────────────────────────────────────────────────
        expect(
          result,
          equals(
            Left<Failure, UserEntity>(
              const ServerFailure(message: 'كلمة المرور غير صحيحة'),
            ),
          ),
        );
      },
    );

    test(
      'FAILURE → returns Left(AuthFailure) when DataSource throws AuthException',
      () async {
        // ── Arrange ────────────────────────────────────────────────────────
        // AuthException (e.g. Firebase social auth failure) maps to AuthFailure.
        when(
          () => mockDataSource.loginWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(AuthException(message: 'بيانات الدخول غير صحيحة'));

        // ── Act ────────────────────────────────────────────────────────────
        final result = await repository.loginWithEmail(
          email: tEmail,
          password: tPassword,
        );

        // ── Assert ─────────────────────────────────────────────────────────
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<AuthFailure>()),
          (_) => fail('Expected Left(AuthFailure) but got Right'),
        );
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // verifyWhatsappOtp
  // ─────────────────────────────────────────────────────────────────────────
  group('verifyWhatsappOtp', () {
    const tPhone = '+970591234567';
    const tOtp = '4821';

    test(
      'SUCCESS → returns Right(UserEntity) when DataSource completes normally',
      () async {
        // ── Arrange ────────────────────────────────────────────────────────
        when(
          () =>
              mockDataSource.verifyWhatsappOtp(phoneNumber: tPhone, otp: tOtp),
        ).thenAnswer((_) async => tUserSuccessResponse);

        // ── Act ────────────────────────────────────────────────────────────
        final result = await repository.verifyWhatsappOtp(
          phoneNumber: tPhone,
          otp: tOtp,
        );

        // ── Assert ─────────────────────────────────────────────────────────
        expect(result, equals(Right<Failure, UserEntity>(tUserEntity)));
        verify(
          () =>
              mockDataSource.verifyWhatsappOtp(phoneNumber: tPhone, otp: tOtp),
        ).called(1);
      },
    );

    test(
      'FAILURE → returns Left(ServerFailure) when DataSource throws ServerException',
      () async {
        // ── Arrange ────────────────────────────────────────────────────────
        when(
          () => mockDataSource.verifyWhatsappOtp(
            phoneNumber: any(named: 'phoneNumber'),
            otp: any(named: 'otp'),
          ),
        ).thenThrow(ServerException(message: 'البيانات المدخلة غير صحيحة'));

        // ── Act ────────────────────────────────────────────────────────────
        final result = await repository.verifyWhatsappOtp(
          phoneNumber: tPhone,
          otp: tOtp,
        );

        // ── Assert ─────────────────────────────────────────────────────────
        expect(
          result,
          equals(
            Left<Failure, UserEntity>(
              const ServerFailure(message: 'البيانات المدخلة غير صحيحة'),
            ),
          ),
        );
      },
    );

    test(
      'FAILURE → returns Left(ServerFailure) when DataSource returns null data',
      () async {
        // ── Arrange ────────────────────────────────────────────────────────
        when(
          () => mockDataSource.verifyWhatsappOtp(
            phoneNumber: any(named: 'phoneNumber'),
            otp: any(named: 'otp'),
          ),
        ).thenAnswer(
          (_) async => SuccessResponse<UserModel>(
            status: 1,
            data: null,
            message: 'Unknown Error',
          ),
        );

        // ── Act ────────────────────────────────────────────────────────────
        final result = await repository.verifyWhatsappOtp(
          phoneNumber: tPhone,
          otp: tOtp,
        );

        // ── Assert ─────────────────────────────────────────────────────────
        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<ServerFailure>()),
          (_) => fail('Expected Left(ServerFailure) but got Right'),
        );
      },
    );
  });
}
