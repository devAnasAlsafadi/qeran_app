import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/matchmaker_conversations_page.dart';

abstract interface class MatchmakerConversationsRepository {
  /// Fetches one page of the matchmaker's conversations with users. Left on
  /// transport / auth failure, Right with the parsed page on success.
  Future<Either<Failure, MatchmakerConversationsPage>> getUserConversations({
    required int page,
    required int pageSize,
  });

  /// Lazily opens the matchmaker↔user conversation for [userId]. Right with
  /// its `conversationId` on success, Left on transport / auth failure.
  Future<Either<Failure, int>> openChatWithUser(String userId);
}
