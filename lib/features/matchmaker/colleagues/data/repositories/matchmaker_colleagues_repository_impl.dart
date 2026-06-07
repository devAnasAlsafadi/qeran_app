import 'package:dartz/dartz.dart';
import 'package:qeran/core/data/repositories/base_repository.dart';
import 'package:qeran/core/errors/errors.dart';

import '../../../conversations/domain/entities/matchmaker_conversations_page.dart';
import '../../domain/entities/matchmaker_colleagues_page.dart';
import '../../domain/repositories/matchmaker_colleagues_repository.dart';
import '../datasources/matchmaker_colleagues_remote_datasource.dart';

class MatchmakerColleaguesRepositoryImpl
    with BaseRepository
    implements MatchmakerColleaguesRepository {
  final MatchmakerColleaguesRemoteDataSource _dataSource;

  const MatchmakerColleaguesRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, MatchmakerColleaguesPage>> getColleagues({
    required int page,
    required int pageSize,
  }) {
    return executeApiCall(() async {
      final model = await _dataSource.getColleagues(
        page: page,
        pageSize: pageSize,
      );
      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, MatchmakerConversationsPage>> getColleagueConversations({
    required int page,
    required int pageSize,
  }) {
    return executeApiCall(() async {
      final model = await _dataSource.getColleagueConversations(
        page: page,
        pageSize: pageSize,
      );
      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, int>> openColleagueChat(String colleagueId) =>
      executeApiCall(() => _dataSource.openColleagueChat(colleagueId));
}
