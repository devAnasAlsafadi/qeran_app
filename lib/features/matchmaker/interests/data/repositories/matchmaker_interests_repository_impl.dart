import 'package:dartz/dartz.dart';
import 'package:qeran/core/data/repositories/base_repository.dart';
import 'package:qeran/core/errors/errors.dart';

import '../../domain/entities/matchmaker_interest_archive_item.dart';
import '../../domain/entities/matchmaker_interest_enums.dart';
import '../../domain/entities/matchmaker_interest_match.dart';
import '../../domain/entities/matchmaker_interest_page.dart';
import '../../domain/entities/matchmaker_like_activity.dart';
import '../../domain/repositories/matchmaker_interests_repository.dart';
import '../datasources/matchmaker_interests_remote_datasource.dart';

/// Read-only GETs — a plain [BaseRepository.executeApiCall] is enough (no
/// errorCode branching like the notes / cases mutations need).
class MatchmakerInterestsRepositoryImpl
    with BaseRepository
    implements MatchmakerInterestsRepository {
  final MatchmakerInterestsRemoteDataSource _dataSource;

  const MatchmakerInterestsRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, MatchmakerInterestPage<MatchmakerLikeActivity>>>
      getLikes(String userId, MatchmakerLikeDirection direction) =>
          executeApiCall(() => _dataSource.getLikes(userId, direction));

  @override
  Future<Either<Failure, MatchmakerInterestPage<List<MatchmakerInterestMatch>>>>
      getMatches(String userId) =>
          executeApiCall(() => _dataSource.getMatches(userId));

  @override
  Future<
          Either<Failure,
              MatchmakerInterestPage<List<MatchmakerInterestArchiveItem>>>>
      getArchivedMatches(String userId) =>
          executeApiCall(() => _dataSource.getArchivedMatches(userId));
}
