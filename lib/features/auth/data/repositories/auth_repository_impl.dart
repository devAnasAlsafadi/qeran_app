import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import 'package:qeran/core/data/repositories/base_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl with BaseRepository implements AuthRepository {
  final AuthRemoteDataSource _dataSource;

  const AuthRepositoryImpl(this._dataSource);

  // ─── Manual Auth (Custom REST API) ────────────────────────────

  @override
  Future<Either<Failure, UserEntity>> loginWithEmail({
    required String email,
    required String password,
  }) {
    return executeApiCall(() async {
      final successResponse = await _dataSource.loginWithEmail(
        email: email,
        password: password,
      );
      if (successResponse.data != null) {
        return successResponse.data!.toEntity();
      } else {
        // The server's own prose is English and must never reach the UI;
        // a status:1 envelope with no payload has no code to classify on,
        // so it degrades to the generic localized key.
        throw ServerException(message: LocaleKeys.errors_generic);
      }
    });
  }

  @override
  Future<Either<Failure, UserEntity>> registerUser({
    required String name,
    required String email,
    required String password,
    String? referralCode,
  }) {
    return executeApiCall(() async {
      final successResponse = await _dataSource.registerUser(
        name: name,
        email: email,
        password: password,
        referralCode: referralCode,
      );
      if (successResponse.data != null) {
        return successResponse.data!.toEntity();
      } else {
        // The server's own prose is English and must never reach the UI;
        // a status:1 envelope with no payload has no code to classify on,
        // so it degrades to the generic localized key.
        throw ServerException(message: LocaleKeys.errors_generic);
      }
    });
  }

  @override
  Future<Either<Failure, Unit>> sendWhatsappOtp({required String phoneNumber}) {
    return executeApiCall(() async {
      await _dataSource.sendWhatsappOtp(phoneNumber: phoneNumber);
      return unit;
    });
  }

  @override
  Future<Either<Failure, UserEntity>> verifyWhatsappOtp({
    required String phoneNumber,
    required String otp,
  }) {
    return executeApiCall(() async {
      final successResponse = await _dataSource.verifyWhatsappOtp(
        phoneNumber: phoneNumber,
        otp: otp,
      );
      if (successResponse.data != null) {
        return successResponse.data!.toEntity();
      } else {
        // The server's own prose is English and must never reach the UI;
        // a status:1 envelope with no payload has no code to classify on,
        // so it degrades to the generic localized key.
        throw ServerException(message: LocaleKeys.errors_generic);
      }
    });
  }

  @override
  Future<Either<Failure, Unit>> requestForgotPasswordOtp({
    required String phoneNumber,
  }) {
    return executeApiCall(() async {
      await _dataSource.requestForgotPasswordOtp(phoneNumber: phoneNumber);
      return unit;
    });
  }

  @override
  Future<Either<Failure, Unit>> verifyForgotPasswordOtp({
    required String phoneNumber,
    required String code,
  }) {
    return executeApiCall(() async {
      await _dataSource.verifyForgotPasswordOtp(
        phoneNumber: phoneNumber,
        code: code,
      );
      return unit;
    });
  }

  @override
  Future<Either<Failure, Unit>> resetPassword({
    required String phoneNumber,
    required String code,
    required String newPassword,
  }) {
    return executeApiCall(() async {
      await _dataSource.resetPassword(
        phoneNumber: phoneNumber,
        code: code,
        newPassword: newPassword,
      );
      return unit;
    });
  }

  // ─── Social Auth (Firebase) ───────────────────────────────────

  @override
  Future<Either<Failure, UserEntity>> loginWithGoogle() {
    return executeApiCall(() async {
      final successResponse = await _dataSource.loginWithGoogle();
      if (successResponse.data != null) {
        return successResponse.data!.toEntity();
      } else {
        // The server's own prose is English and must never reach the UI;
        // a status:1 envelope with no payload has no code to classify on,
        // so it degrades to the generic localized key.
        throw ServerException(message: LocaleKeys.errors_generic);
      }
    });
  }

  @override
  Future<Either<Failure, UserEntity>> loginWithApple() {
    return executeApiCall(() async {
      final successResponse = await _dataSource.loginWithApple();
      if (successResponse.data != null) {
        return successResponse.data!.toEntity();
      } else {
        // The server's own prose is English and must never reach the UI;
        // a status:1 envelope with no payload has no code to classify on,
        // so it degrades to the generic localized key.
        throw ServerException(message: LocaleKeys.errors_generic);
      }
    });
  }
}
