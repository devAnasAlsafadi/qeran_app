import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/formal_step_outcome.dart';
import '../repositories/formal_step_repository.dart';

/// Takes `pendingFormalStep.id`, NOT the like id. Declining ends the
/// compatibility case, so the caller confirms before reaching this.
class RejectFormalStepUseCase {
  final FormalStepRepository _repository;
  const RejectFormalStepUseCase(this._repository);

  Future<Either<Failure, FormalStepRespondOutcome>> call(int requestId) =>
      _repository.rejectFormalStep(requestId);
}
