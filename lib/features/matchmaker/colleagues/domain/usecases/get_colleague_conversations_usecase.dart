import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../../../conversations/domain/entities/matchmaker_conversations_page.dart';
import '../repositories/matchmaker_colleagues_repository.dart';

/// Fetches one page of active colleague↔colleague conversations.
class GetColleagueConversationsUseCase {
  final MatchmakerColleaguesRepository _repository;
  const GetColleagueConversationsUseCase(this._repository);

  Future<Either<Failure, MatchmakerConversationsPage>> call({
    required int page,
    required int pageSize,
  }) =>
      _repository.getColleagueConversations(page: page, pageSize: pageSize);
}
