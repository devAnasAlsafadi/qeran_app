import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class VerifyWhatsappOtpUseCase {
  final AuthRepository _repository;

  const VerifyWhatsappOtpUseCase(this._repository);

  Future<Either<Failure, UserEntity>> call({
    required String phoneNumber,
    required String otp,
  }) => _repository.verifyWhatsappOtp(phoneNumber: phoneNumber, otp: otp);
}
