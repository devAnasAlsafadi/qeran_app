import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';
import '../repositories/auth_repository.dart';

class VerifyForgotPasswordOtpUseCase {
  final AuthRepository _repository;

  const VerifyForgotPasswordOtpUseCase(this._repository);

  Future<Either<Failure, Unit>> call({
    required String phoneNumber,
    required String code,
  }) =>
      _repository.verifyForgotPasswordOtp(phoneNumber: phoneNumber, code: code);
}
