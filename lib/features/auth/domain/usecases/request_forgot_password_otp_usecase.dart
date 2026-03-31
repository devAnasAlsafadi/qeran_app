import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';
import '../repositories/auth_repository.dart';

class RequestForgotPasswordOtpUseCase {
  final AuthRepository _repository;

  const RequestForgotPasswordOtpUseCase(this._repository);

  Future<Either<Failure, Unit>> call({required String phoneNumber}) =>
      _repository.requestForgotPasswordOtp(phoneNumber: phoneNumber);
}
