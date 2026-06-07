import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../repositories/matchmaker_account_repository.dart';

/// Updates the matchmaker's display name ([name] already trimmed by the caller).
class UpdateNameUseCase {
  final MatchmakerAccountRepository _repository;
  const UpdateNameUseCase(this._repository);

  Future<Either<Failure, Unit>> call(String name) =>
      _repository.updateName(name);
}
