import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../repositories/community_author_repository.dart';

/// Whether she has any post now, in any status (D35): 6.1 with one per page,
/// read for its `totalCount` (contract §7.3).
class HasMyCommunityPostsUseCase {
  final CommunityAuthorRepository _repository;
  const HasMyCommunityPostsUseCase(this._repository);

  Future<Either<Failure, bool>> call() async => (await _repository.getMyPosts(
    page: 1,
    pageSize: 1,
  )).map((page) => page.totalCount > 0);
}
