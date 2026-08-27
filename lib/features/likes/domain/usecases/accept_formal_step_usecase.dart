import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/formal_step_outcome.dart';
import '../repositories/formal_step_repository.dart';

/// Takes `pendingFormalStep.id`, NOT the like id.
class AcceptFormalStepUseCase {
  final FormalStepRepository _repository;
  const AcceptFormalStepUseCase(this._repository);

  Future<Either<Failure, FormalStepRespondOutcome>> call(int requestId) =>
      _repository.acceptFormalStep(requestId);
}
