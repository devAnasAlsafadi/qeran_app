import 'package:dartz/dartz.dart';

import 'package:qeran/core/data/repositories/base_repository.dart';
import 'package:qeran/core/errors/errors.dart';

import '../../domain/entities/match_card.dart';
import '../../domain/entities/photo_exchange_outcome.dart';
import '../../domain/repositories/matches_repository.dart';
import '../datasources/matches_remote_datasource.dart';

class MatchesRepositoryImpl with BaseRepository implements MatchesRepository {
  final MatchesRemoteDataSource _dataSource;

  const MatchesRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, List<MatchCard>>> getMatches() {
    return executeApiCall(() async {
      final models = await _dataSource.getMatches();
      return models.map((m) => m.toEntity()).toList(growable: false);
    });
  }

  @override
  Future<Either<Failure, PhotoExchangeRequestOutcome>> requestPhotoExchange(
    int likeRequestId,
  ) {
    return executeApiCall(
      () => _dataSource.requestPhotoExchange(likeRequestId),
    );
  }

  @override
  Future<Either<Failure, PhotoExchangeRespondOutcome>> acceptPhotoExchange(
    int requestId,
  ) {
    return executeApiCall(() => _dataSource.acceptPhotoExchange(requestId));
  }

  @override
  Future<Either<Failure, PhotoExchangeRespondOutcome>> rejectPhotoExchange(
    int requestId,
  ) {
    return executeApiCall(() => _dataSource.rejectPhotoExchange(requestId));
  }
}
