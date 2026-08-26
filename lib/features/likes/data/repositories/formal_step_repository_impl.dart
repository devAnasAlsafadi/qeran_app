import 'package:dartz/dartz.dart';

import 'package:qeran/core/data/repositories/base_repository.dart';
import 'package:qeran/core/errors/errors.dart';

import '../../domain/entities/formal_step_outcome.dart';
import '../../domain/repositories/formal_step_repository.dart';
import '../datasources/formal_step_remote_datasource.dart';

class FormalStepRepositoryImpl
    with BaseRepository
    implements FormalStepRepository {
  final FormalStepRemoteDataSource _dataSource;

  const FormalStepRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, FormalStepRequestOutcome>> requestFormalStep(
    int likeRequestId,
  ) {
    return executeApiCall(() => _dataSource.requestFormalStep(likeRequestId));
  }
}
