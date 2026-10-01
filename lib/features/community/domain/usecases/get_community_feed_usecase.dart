import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/community_page.dart';
import '../entities/community_page_sizes.dart';
import '../entities/community_post.dart';
import '../repositories/community_repository.dart';

class GetCommunityFeedUseCase {
  final CommunityRepository _repository;
  const GetCommunityFeedUseCase(this._repository);

  Future<Either<Failure, CommunityPage<CommunityPost>>> call({required int page}) =>
      _repository.getFeed(page: page, pageSize: CommunityPageSizes.feed);
}
