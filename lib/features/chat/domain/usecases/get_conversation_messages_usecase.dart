import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/chat_messages_page.dart';
import '../repositories/chat_repository.dart';

class GetConversationMessagesUseCase {
  final ChatRepository _repository;
  const GetConversationMessagesUseCase(this._repository);

  Future<Either<Failure, ChatMessagesPage>> call({
    required int conversationId,
    required int page,
    required int pageSize,
  }) =>
      _repository.getMessages(
        conversationId: conversationId,
        page: page,
        pageSize: pageSize,
      );
}
