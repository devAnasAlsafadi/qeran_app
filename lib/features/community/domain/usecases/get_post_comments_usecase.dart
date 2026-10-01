import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/community_comment.dart';
import '../entities/community_page.dart';
import '../entities/community_page_sizes.dart';
import '../repositories/community_repository.dart';

class GetPostCommentsUseCase {
  final CommunityRepository _repository;
  const GetPostCommentsUseCase(this._repository);

  Future<Either<Failure, CommunityPage<CommunityComment>>> call(
    int postId, {
    required int page,
  }) =>
      _repository.getComments(
        postId,
        page: page,
        pageSize: CommunityPageSizes.comments,
      );
}
