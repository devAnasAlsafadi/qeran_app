import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/matchmaker_me.dart';
import '../repositories/matchmaker_account_repository.dart';

/// Loads the signed-in matchmaker's own account.
class GetMeUseCase {
  final MatchmakerAccountRepository _repository;
  const GetMeUseCase(this._repository);

  Future<Either<Failure, MatchmakerMe>> call() => _repository.getMe();
}
