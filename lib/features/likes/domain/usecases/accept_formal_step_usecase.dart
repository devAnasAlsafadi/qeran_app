import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/formal_step_outcome.dart';
import '../repositories/compatibility_case_repository.dart';

/// Takes `pendingFormalStep.id`, NOT the like id.
class AcceptFormalStepUseCase {
  final CompatibilityCaseRepository _repository;
  const AcceptFormalStepUseCase(this._repository);

  Future<Either<Failure, FormalStepRespondOutcome>> call(int requestId) =>
      _repository.acceptFormalStep(requestId);
}
