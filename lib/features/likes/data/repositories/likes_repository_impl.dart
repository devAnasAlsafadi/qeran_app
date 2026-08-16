import 'package:dartz/dartz.dart';

import 'package:qeran/core/data/repositories/base_repository.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/utils/server_clock.dart';

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
      return _calibrated(model.toEntity());
    });
  }

  @override
  Future<Either<Failure, LikeRequestsData>> getOutgoing() {
    return executeApiCall(() async {
      final model = await _dataSource.getOutgoingLikes();
      return _calibrated(model.toEntity());
    });
  }

  /// These rows carry BOTH `expiresAt` and the server's own `remainingSeconds`
  /// snapshot, which together pin the server's clock — see [ServerClock]. Both
  /// apps hit these endpoints, so this is the main place the offset is learned.
  LikeRequestsData _calibrated(LikeRequestsData data) {
    ServerClock.instance.calibrateFromAny([
      for (final card in data.pending)
        (expiresAt: card.expiresAt, remainingSeconds: card.remainingSeconds),
    ]);
    return data;
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
