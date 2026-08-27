import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/formal_step_outcome.dart';
import '../repositories/compatibility_case_repository.dart';

/// Takes the RELATIONSHIP id (`likeRequestId`), not a formal-step request id.
/// Ends the case irreversibly, so the caller confirms before reaching this.
class CancelCaseUseCase {
  final CompatibilityCaseRepository _repository;
  const CancelCaseUseCase(this._repository);

  Future<Either<Failure, CaseCancelOutcome>> call(int likeRequestId) =>
      _repository.cancelCase(likeRequestId);
}
