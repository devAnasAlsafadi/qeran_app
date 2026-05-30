import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/formal_request_status.dart';
import '../repositories/compatibility_cases_repository.dart';

class UpdateFormalRequestStatusUseCase {
  final CompatibilityCasesRepository _repository;
  const UpdateFormalRequestStatusUseCase(this._repository);

  Future<Either<Failure, String>> call({
    required int formalRequestId,
    required FormalRequestStatus newStatus,
  }) =>
      _repository.updateFormalRequestStatus(
        formalRequestId: formalRequestId,
        newStatus: newStatus,
      );
}
