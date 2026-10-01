import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/community_like_state.dart';
import '../repositories/community_repository.dart';

class SetPostLikeUseCase {
  final CommunityRepository _repository;
  const SetPostLikeUseCase(this._repository);

  Future<Either<Failure, CommunityLikeState>> call(
    int postId, {
    required bool liked,
  }) =>
      _repository.setPostLike(postId, liked: liked);
}
