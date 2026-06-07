import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../../../conversations/domain/entities/matchmaker_conversations_page.dart';
import '../entities/matchmaker_colleagues_page.dart';

abstract interface class MatchmakerColleaguesRepository {
  /// Fetches one page of the colleague directory (to start a chat). Left on
  /// transport / auth failure, Right with the parsed page on success.
  Future<Either<Failure, MatchmakerColleaguesPage>> getColleagues({
    required int page,
    required int pageSize,
  });

  /// Fetches one page of active colleague↔colleague conversations (same shape
  /// as user conversations → reuses the generic page entity).
  Future<Either<Failure, MatchmakerConversationsPage>> getColleagueConversations({
    required int page,
    required int pageSize,
  });

  /// Opens the conversation with colleague [colleagueId]. Right with its
  /// `conversationId` on success, Left on transport / auth failure.
  Future<Either<Failure, int>> openColleagueChat(String colleagueId);
}
