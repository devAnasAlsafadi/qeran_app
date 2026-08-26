import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/formal_step_outcome.dart';
import '../repositories/formal_step_repository.dart';

class RequestFormalStepUseCase {
  final FormalStepRepository _repository;
  const RequestFormalStepUseCase(this._repository);

  Future<Either<Failure, FormalStepRequestOutcome>> call(int likeRequestId) =>
      _repository.requestFormalStep(likeRequestId);
}
