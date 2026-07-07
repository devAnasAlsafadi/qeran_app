import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../repositories/change_password_repository.dart';

/// Changes the signed-in user's password (current + new + confirm).
class ChangePasswordUseCase {
  final ChangePasswordRepository _repository;

  const ChangePasswordUseCase(this._repository);

  Future<Either<Failure, Unit>> call({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) =>
      _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
}
