import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';
import '../entities/user_entity.dart';

abstract interface class AuthRepository {
  Future<Either<Failure, UserEntity>> loginWithEmail({
    required String email,
    required String password,
  });

  Future<Either<Failure, UserEntity>> loginWithGoogle();

  Future<Either<Failure, UserEntity>> loginWithApple();

  Future<Either<Failure, UserEntity>> registerUser({
    required String name,
    required String email,
    required String password,
    String? referralCode,
  });

  Future<Either<Failure, Unit>> sendWhatsappOtp({required String phoneNumber});

  Future<Either<Failure, UserEntity>> verifyWhatsappOtp({
    required String phoneNumber,
    required String otp,
  });

  Future<Either<Failure, Unit>> requestForgotPasswordOtp({
    required String phoneNumber,
  });

  Future<Either<Failure, Unit>> verifyForgotPasswordOtp({
    required String phoneNumber,
    required String code,
  });

  Future<Either<Failure, Unit>> resetPassword({
    required String phoneNumber,
    required String code,
    required String newPassword,
  });
}
