import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/community_flagged_item.dart';
import '../entities/community_page.dart';
import '../entities/community_post.dart';

/// What the post's author does that members can't (contract §5.3, §6): her
/// own posts, deleting one, and the flags on comments under them. Its post
/// changes go out on the same stream as `CommunityRepository`'s.
abstract class CommunityAuthorRepository {
  /// 6.1 — her posts in every status, newest first.
  Future<Either<Failure, CommunityPage<CommunityPost>>> getMyPosts({
    required int page,
    required int pageSize,
  });

  /// 6.3 — announces the post gone. One already gone counts as deleted.
  Future<Either<Failure, Unit>> deletePost(int postId);

  /// 5.3 — open flags on her posts, newest report first.
  Future<Either<Failure, CommunityPage<CommunityFlaggedItem>>> getFlags({
    required int page,
    required int pageSize,
  });

  /// 5.3 — keep the item: its flag clears for her; admin still sees it.
  Future<Either<Failure, Unit>> dismissFlag(int flagId);
}
