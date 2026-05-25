import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../repositories/chat_repository.dart';

class MarkConversationAsReadUseCase {
  final ChatRepository _repository;
  const MarkConversationAsReadUseCase(this._repository);

  Future<Either<Failure, Unit>> call(int conversationId) =>
      _repository.markAsRead(conversationId);
}
