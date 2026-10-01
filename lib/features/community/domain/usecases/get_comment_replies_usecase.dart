import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/community_comment.dart';
import '../entities/community_page.dart';
import '../entities/community_page_sizes.dart';
import '../repositories/community_repository.dart';

class GetCommentRepliesUseCase {
  final CommunityRepository _repository;
  const GetCommentRepliesUseCase(this._repository);

  Future<Either<Failure, CommunityPage<CommunityComment>>> call(
    int commentId, {
    required int page,
  }) =>
      _repository.getReplies(
        commentId,
        page: page,
        pageSize: CommunityPageSizes.replies,
      );
}
