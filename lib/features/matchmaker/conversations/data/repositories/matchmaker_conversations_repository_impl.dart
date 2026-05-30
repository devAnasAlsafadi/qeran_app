import 'package:dartz/dartz.dart';
import 'package:qeran/core/data/repositories/base_repository.dart';
import 'package:qeran/core/errors/errors.dart';

import '../../domain/entities/matchmaker_conversations_page.dart';
import '../../domain/repositories/matchmaker_conversations_repository.dart';
import '../datasources/matchmaker_conversations_remote_datasource.dart';

class MatchmakerConversationsRepositoryImpl
    with BaseRepository
    implements MatchmakerConversationsRepository {
  final MatchmakerConversationsRemoteDataSource _dataSource;

  const MatchmakerConversationsRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, MatchmakerConversationsPage>> getUserConversations({
    required int page,
    required int pageSize,
  }) {
    return executeApiCall(() async {
      final model = await _dataSource.getUserConversations(
        page: page,
        pageSize: pageSize,
      );
      return model.toEntity();
    });
  }
}
