import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/share_profile_outcome.dart';
import '../repositories/chat_repository.dart';

class ShareProfileUseCase {
  final ChatRepository _repository;
  const ShareProfileUseCase(this._repository);

  Future<Either<Failure, ShareProfileOutcome>> call({
    required int conversationId,
    required String sharedUserId,
  }) =>
      _repository.shareProfile(
        conversationId: conversationId,
        sharedUserId: sharedUserId,
      );
}
