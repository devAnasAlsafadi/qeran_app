import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../repositories/community_author_repository.dart';

/// 6.3 — her post and everything under it.
class DeleteCommunityPostUseCase {
  final CommunityAuthorRepository _repository;
  const DeleteCommunityPostUseCase(this._repository);

  Future<Either<Failure, Unit>> call(int postId) =>
      _repository.deletePost(postId);
}
