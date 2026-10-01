import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/community_post.dart';
import '../repositories/community_repository.dart';

class GetCommunityPostUseCase {
  final CommunityRepository _repository;
  const GetCommunityPostUseCase(this._repository);

  Future<Either<Failure, CommunityPost>> call(int postId) =>
      _repository.getPost(postId);
}
