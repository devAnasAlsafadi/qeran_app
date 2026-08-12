import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/conversation.dart';
import '../repositories/chat_repository.dart';

class GetConversationsUseCase {
  const GetConversationsUseCase(this._repository);

  final ChatRepository _repository;

  Future<Either<Failure, List<Conversation>>> call() =>
      _repository.getConversations();
}
