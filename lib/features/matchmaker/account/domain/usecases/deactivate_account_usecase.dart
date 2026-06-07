import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../repositories/matchmaker_account_repository.dart';

/// Deactivates the matchmaker's account. The JWT stays valid server-side, so on
/// success the caller clears the session locally and returns to login.
class DeactivateAccountUseCase {
  final MatchmakerAccountRepository _repository;
  const DeactivateAccountUseCase(this._repository);

  Future<Either<Failure, Unit>> call() => _repository.deactivate();
}
