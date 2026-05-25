import 'package:dartz/dartz.dart';

import 'package:qeran/core/data/repositories/base_repository.dart';
import 'package:qeran/core/errors/errors.dart';

import '../../domain/entities/chat_messages_page.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/my_matchmaker_outcome.dart';
import '../../domain/entities/send_text_outcome.dart';
import '../../domain/entities/share_profile_outcome.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';

class ChatRepositoryImpl with BaseRepository implements ChatRepository {
  final ChatRemoteDataSource _dataSource;

  const ChatRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, MyMatchmakerOutcome>> getMyMatchmaker() {
    return executeApiCall(() => _dataSource.getMyMatchmaker());
  }

  @override
  Future<Either<Failure, List<Conversation>>> getConversations() {
    return executeApiCall(() async {
      final models = await _dataSource.getConversations();
      return models.map((m) => m.toEntity()).toList(growable: false);
    });
  }

  @override
  Future<Either<Failure, ChatMessagesPage>> getMessages({
    required int conversationId,
    required int page,
    required int pageSize,
  }) {
    return executeApiCall(() async {
      final model = await _dataSource.getMessages(
        conversationId: conversationId,
        page: page,
        pageSize: pageSize,
      );
      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, SendTextOutcome>> sendTextMessage({
    required int conversationId,
    required String content,
  }) {
    return executeApiCall(
      () => _dataSource.sendTextMessage(
        conversationId: conversationId,
        content: content,
      ),
    );
  }

  @override
  Future<Either<Failure, ShareProfileOutcome>> shareProfile({
    required int conversationId,
    required String sharedUserId,
  }) {
    return executeApiCall(
      () => _dataSource.shareProfile(
        conversationId: conversationId,
        sharedUserId: sharedUserId,
      ),
    );
  }

  @override
  Future<Either<Failure, Unit>> markAsRead(int conversationId) {
    return executeApiCall(() async {
      await _dataSource.markAsRead(conversationId);
      return unit;
    });
  }
}
