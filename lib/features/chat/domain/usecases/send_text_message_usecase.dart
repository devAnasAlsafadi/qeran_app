import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/send_text_outcome.dart';
import '../repositories/chat_repository.dart';

class SendTextMessageUseCase {
  final ChatRepository _repository;
  const SendTextMessageUseCase(this._repository);

  Future<Either<Failure, SendTextOutcome>> call({
    required int conversationId,
    required String content,
  }) =>
      _repository.sendTextMessage(
        conversationId: conversationId,
        content: content,
      );
}
