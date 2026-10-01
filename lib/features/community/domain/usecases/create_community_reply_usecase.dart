import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/comment_submit_outcome.dart';
import '../repositories/community_repository.dart';

class CreateCommunityReplyUseCase {
  final CommunityRepository _repository;
  const CreateCommunityReplyUseCase(this._repository);

  Future<Either<Failure, CommentSubmitOutcome>> call(
    int commentId,
    String text,
  ) =>
      _repository.createReply(commentId, text);
}
