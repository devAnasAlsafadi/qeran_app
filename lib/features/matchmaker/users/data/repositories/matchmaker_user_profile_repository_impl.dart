import 'package:dartz/dartz.dart';
import 'package:qeran/core/data/repositories/base_repository.dart';
import 'package:qeran/core/errors/errors.dart';

import '../../domain/entities/matchmaker_user_profile.dart';
import '../../domain/repositories/matchmaker_user_profile_repository.dart';
import '../datasources/matchmaker_user_profile_remote_datasource.dart';

class MatchmakerUserProfileRepositoryImpl
    with BaseRepository
    implements MatchmakerUserProfileRepository {
  final MatchmakerUserProfileRemoteDataSource _dataSource;

  const MatchmakerUserProfileRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, MatchmakerUserProfile>> getUserProfile(
    String userId,
  ) {
    return executeApiCall(() async {
      final model = await _dataSource.getUserProfile(userId);
      return model.toEntity();
    });
  }
}
