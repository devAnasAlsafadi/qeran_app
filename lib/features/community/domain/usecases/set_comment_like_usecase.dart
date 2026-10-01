import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/community_like_state.dart';
import '../repositories/community_repository.dart';

class SetCommentLikeUseCase {
  final CommunityRepository _repository;
  const SetCommentLikeUseCase(this._repository);

  Future<Either<Failure, CommunityLikeState>> call(
    int commentId, {
    required bool liked,
  }) =>
      _repository.setCommentLike(commentId, liked: liked);
}
