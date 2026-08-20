import 'package:dartz/dartz.dart';

import 'package:qeran/core/errors/errors.dart';

import '../entities/chat_messages_page.dart';
import '../entities/my_matchmaker_outcome.dart';
import '../entities/send_text_outcome.dart';
import '../entities/share_profile_outcome.dart';

/// Domain-layer contract for chat.
///
/// Transport / unmapped failures go on `Left(Failure)`; semantic
/// outcomes (no-matchmaker, validation, rate limit, etc) ride the
/// `Right` of the typed outcome sealed unions so the cubit branches
/// without inspecting raw backend messages.
abstract interface class ChatRepository {
  /// `GET /api/chat/my-matchmaker`.
  Future<Either<Failure, MyMatchmakerOutcome>> getMyMatchmaker();

  /// `GET /api/chat/conversations/{id}/messages?page=N&pageSize=M`.
  /// Newest-first per server contract.
  Future<Either<Failure, ChatMessagesPage>> getMessages({
    required int conversationId,
    required int page,
    required int pageSize,
  });

  /// `POST /api/chat/conversations/{id}/messages` — body `{content}`.
  Future<Either<Failure, SendTextOutcome>> sendTextMessage({
    required int conversationId,
    required String content,
  });

  /// `POST /api/chat/conversations/{id}/share-profile` — body
  /// `{sharedUserId}`.
  Future<Either<Failure, ShareProfileOutcome>> shareProfile({
    required int conversationId,
    required String sharedUserId,
  });

  /// `POST /api/chat/conversations/{id}/read`.
  Future<Either<Failure, Unit>> markAsRead(int conversationId);
}
