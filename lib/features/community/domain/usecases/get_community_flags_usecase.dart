import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/community_flagged_item.dart';
import '../entities/community_page.dart';
import '../entities/community_page_sizes.dart';
import '../repositories/community_author_repository.dart';

/// 5.3 — the open flags on her posts, a page at a time.
class GetCommunityFlagsUseCase {
  final CommunityAuthorRepository _repository;
  const GetCommunityFlagsUseCase(this._repository);

  Future<Either<Failure, CommunityPage<CommunityFlaggedItem>>> call({
    required int page,
  }) => _repository.getFlags(page: page, pageSize: CommunityPageSizes.feed);
}
