import 'package:dartz/dartz.dart';
import 'package:qeran/core/data/repositories/base_repository.dart';
import 'package:qeran/core/errors/errors.dart';

import '../../domain/repositories/matchmaker_user_actions_repository.dart';
import '../datasources/matchmaker_user_actions_remote_datasource.dart';

class MatchmakerUserActionsRepositoryImpl
    with BaseRepository
    implements MatchmakerUserActionsRepository {
  final MatchmakerUserActionsRemoteDataSource _dataSource;

  const MatchmakerUserActionsRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, String>> approve(String userId) =>
      executeApiCall(() => _dataSource.approve(userId));

  @override
  Future<Either<Failure, String>> reject({
    required String userId,
    required String reason,
  }) =>
      executeApiCall(() => _dataSource.reject(userId: userId, reason: reason));

  @override
  Future<Either<Failure, String>> requestImage(String userId) =>
      executeApiCall(() => _dataSource.requestImage(userId));
}
