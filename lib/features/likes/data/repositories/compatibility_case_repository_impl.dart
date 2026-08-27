import 'package:dartz/dartz.dart';

import 'package:qeran/core/data/repositories/base_repository.dart';
import 'package:qeran/core/errors/errors.dart';

import '../../domain/entities/formal_step_outcome.dart';
import '../../domain/repositories/compatibility_case_repository.dart';
import '../datasources/compatibility_case_remote_datasource.dart';

class CompatibilityCaseRepositoryImpl
    with BaseRepository
    implements CompatibilityCaseRepository {
  final CompatibilityCaseRemoteDataSource _dataSource;

  const CompatibilityCaseRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, FormalStepRequestOutcome>> requestFormalStep(
    int likeRequestId,
  ) {
    return executeApiCall(() => _dataSource.requestFormalStep(likeRequestId));
  }

  @override
  Future<Either<Failure, FormalStepRespondOutcome>> acceptFormalStep(
    int requestId,
  ) {
    return executeApiCall(() => _dataSource.acceptFormalStep(requestId));
  }

  @override
  Future<Either<Failure, FormalStepRespondOutcome>> rejectFormalStep(
    int requestId,
  ) {
    return executeApiCall(() => _dataSource.rejectFormalStep(requestId));
  }

  @override
  Future<Either<Failure, CaseCancelOutcome>> cancelCase(int likeRequestId) {
    return executeApiCall(() => _dataSource.cancelCase(likeRequestId));
  }
}
