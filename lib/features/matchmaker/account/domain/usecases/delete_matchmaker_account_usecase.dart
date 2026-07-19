import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../repositories/matchmaker_account_repository.dart';

/// Permanently deletes the signed-in Moderator's account
/// (`DELETE /matchmaker/me/account`). Mirrors the user delete: irreversible,
/// with the device-unlink → local-wipe → login cleanup orchestrated above.
class DeleteMatchmakerAccountUseCase {
  final MatchmakerAccountRepository _repository;

  const DeleteMatchmakerAccountUseCase(this._repository);

  Future<Either<Failure, Unit>> call() => _repository.deleteAccount();
}
