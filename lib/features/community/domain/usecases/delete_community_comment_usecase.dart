import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../repositories/community_repository.dart';

class DeleteCommunityCommentUseCase {
  final CommunityRepository _repository;
  const DeleteCommunityCommentUseCase(this._repository);

  Future<Either<Failure, Unit>> call(int commentId) =>
      _repository.deleteComment(commentId);
}
