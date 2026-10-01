import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/comment_submit_outcome.dart';
import '../repositories/community_repository.dart';

class CreateCommunityCommentUseCase {
  final CommunityRepository _repository;
  const CreateCommunityCommentUseCase(this._repository);

  Future<Either<Failure, CommentSubmitOutcome>> call(int postId, String text) =>
      _repository.createComment(postId, text);
}
