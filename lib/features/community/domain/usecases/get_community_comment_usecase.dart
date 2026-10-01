import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/community_comment.dart';
import '../repositories/community_repository.dart';

class GetCommunityCommentUseCase {
  final CommunityRepository _repository;
  const GetCommunityCommentUseCase(this._repository);

  Future<Either<Failure, CommunityComment>> call(int commentId) =>
      _repository.getComment(commentId);
}
