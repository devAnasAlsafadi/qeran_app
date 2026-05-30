import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/matchmaker_conversations_page.dart';
import '../repositories/matchmaker_conversations_repository.dart';

class GetUserConversationsUseCase {
  final MatchmakerConversationsRepository _repository;
  const GetUserConversationsUseCase(this._repository);

  Future<Either<Failure, MatchmakerConversationsPage>> call({
    required int page,
    required int pageSize,
  }) =>
      _repository.getUserConversations(page: page, pageSize: pageSize);
}
