import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/community_page.dart';
import '../entities/community_page_sizes.dart';
import '../entities/community_post.dart';
import '../repositories/community_author_repository.dart';

/// 6.1 — her posts in every status, a page at a time.
class GetMyCommunityPostsUseCase {
  final CommunityAuthorRepository _repository;
  const GetMyCommunityPostsUseCase(this._repository);

  Future<Either<Failure, CommunityPage<CommunityPost>>> call({
    required int page,
  }) => _repository.getMyPosts(page: page, pageSize: CommunityPageSizes.feed);
}
