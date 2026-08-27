import 'package:dartz/dartz.dart';

import 'package:qeran/core/errors/errors.dart';

import '../entities/formal_step_outcome.dart';

/// Domain-layer contract for what a MEMBER can do to their compatibility
/// case: ask for the formal step, answer one, or call the case off.
///
/// Separate from `MatchesRepository` for the same reason its datasource is:
/// its own set of endpoints with its own error vocabulary. Reading the
/// resulting state stays with `MatchesRepository` — `caseStage`, `caseStatus`
/// and `pendingFormalStep` all arrive on the matches feed, so there is
/// nothing to fetch here, only actions to take.
abstract interface class CompatibilityCaseRepository {
  /// `POST /api/formal-step/request/{likeRequestId}` — asks the other member
  /// to begin the formal step. Returns a typed outcome so the cubit can
  /// branch without reading raw backend messages.
  Future<Either<Failure, FormalStepRequestOutcome>> requestFormalStep(
    int likeRequestId,
  );

  /// `POST /api/formal-step/{requestId}/accept` — agree to begin.
  ///
  /// Takes the REQUEST id (`pendingFormalStep.id`), where [requestFormalStep]
  /// takes the like id. The two are both ints and both plausible, so the
  /// wrong one reaches a real endpoint and fails as if the server were at
  /// fault.
  Future<Either<Failure, FormalStepRespondOutcome>> acceptFormalStep(
    int requestId,
  );

  /// `POST /api/formal-step/{requestId}/reject` — decline, which ends the
  /// compatibility case.
  Future<Either<Failure, FormalStepRespondOutcome>> rejectFormalStep(
    int requestId,
  );

  /// `POST /api/matches/{likeRequestId}/cancel` — ends the case from either
  /// side, at any stage, while it is still running. Takes the RELATIONSHIP id.
  Future<Either<Failure, CaseCancelOutcome>> cancelCase(int likeRequestId);
}
