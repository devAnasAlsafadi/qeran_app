import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../repositories/matchmaker_conversations_repository.dart';

/// Lazily opens (or fetches) the matchmaker↔user conversation for a user and
/// returns its `conversationId`. Used by the user-card مراسلة action to resolve
/// the conversation before navigating to the existing chat screen.
class OpenUserChatUseCase {
  final MatchmakerConversationsRepository _repository;
  const OpenUserChatUseCase(this._repository);

  Future<Either<Failure, int>> call(String userId) =>
      _repository.openChatWithUser(userId);
}
