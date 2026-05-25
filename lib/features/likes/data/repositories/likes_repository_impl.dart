import 'package:dartz/dartz.dart';

import 'package:qeran/core/data/repositories/base_repository.dart';
import 'package:qeran/core/errors/errors.dart';

import '../../domain/entities/like_action_outcome.dart';
import '../../domain/entities/like_requests_data.dart';
import '../../domain/repositories/likes_repository.dart';
import '../datasources/likes_remote_datasource.dart';

class LikesRepositoryImpl with BaseRepository implements LikesRepository {
  final LikesRemoteDataSource _dataSource;

  const LikesRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, LikeRequestsData>> getIncoming() {
    return executeApiCall(() async {
      final model = await _dataSource.getIncomingLikes();
      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, LikeRequestsData>> getOutgoing() {
    return executeApiCall(() async {
      final model = await _dataSource.getOutgoingLikes();
      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, LikeActionOutcome>> acceptLike(int likeRequestId) {
    // Semantic outcomes (subscription, expired, not-found) are returned
    // by the data source on the Right side. Anything else — transport
    // error or unmapped message — becomes Left(Failure) via the mixin.
    return executeApiCall(() => _dataSource.acceptLike(likeRequestId));
  }

  @override
  Future<Either<Failure, LikeActionOutcome>> rejectLike(int likeRequestId) {
    return executeApiCall(() => _dataSource.rejectLike(likeRequestId));
  }
}
