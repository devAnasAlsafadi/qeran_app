import 'dart:async';

import 'package:qeran/features/community/domain/usecases/get_my_community_posts_usecase.dart';
import 'package:qeran/features/community/presentation/blocs/feed/community_feed_cubit.dart';

/// Her «منشوراتي» (B2–B5): her posts in every status (6.1), newest first,
/// with the feed's paging, likes and changes; a post she publishes joins at
/// the top whatever its status (D4, D5). Opening it, and pulling it to
/// refresh, clears «تعليقات جديدة على منشوراتك» (D33, S20).
class MyPostsCubit extends CommunityFeedCubit {
  MyPostsCubit({
    required GetMyCommunityPostsUseCase getMyPosts,
    required super.getPost,
    required super.setPostLike,
    required super.watchChanges,
    required Future<void> Function() markCommentsSeen,
  }) : _markCommentsSeen = markCommentsSeen,
       super(getFeed: getMyPosts.call, anyStatus: true);

  final Future<void> Function() _markCommentsSeen;

  /// She opened «منشوراتي»: the new comments on her posts are seen (D33).
  Future<void> seen() => _markCommentsSeen();

  @override
  Future<void> refresh() {
    unawaited(seen());
    return super.refresh();
  }
}
