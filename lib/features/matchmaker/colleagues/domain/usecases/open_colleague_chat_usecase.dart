import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../repositories/matchmaker_colleagues_repository.dart';

/// Opens (or fetches) the conversation with a colleague and returns its
/// `conversationId`. Used by the colleague-directory "start chat" action to
/// resolve the conversation before navigating to the shared chat screen.
class OpenColleagueChatUseCase {
  final MatchmakerColleaguesRepository _repository;
  const OpenColleagueChatUseCase(this._repository);

  Future<Either<Failure, int>> call(String colleagueId) =>
      _repository.openColleagueChat(colleagueId);
}
