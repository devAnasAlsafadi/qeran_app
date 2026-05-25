import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';
import '../repositories/auth_repository.dart';

class ResetPasswordUseCase {
  final AuthRepository _repository;

  const ResetPasswordUseCase(this._repository);

  Future<Either<Failure, Unit>> call({
    required String phoneNumber,
    required String code,
    required String newPassword,
  }) => _repository.resetPassword(
    phoneNumber: phoneNumber,
    code: code,
    newPassword: newPassword,
  );
}
