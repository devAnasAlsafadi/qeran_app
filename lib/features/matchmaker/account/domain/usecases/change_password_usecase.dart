import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../repositories/matchmaker_account_repository.dart';

/// Changes the signed-in matchmaker's password via the shared auth endpoint.
class ChangePasswordUseCase {
  final MatchmakerAccountRepository _repository;
  const ChangePasswordUseCase(this._repository);

  Future<Either<Failure, Unit>> call({
    required String currentPassword,
    required String newPassword,
  }) =>
      _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
}
