import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/features/community/domain/usecases/get_community_post_usecase.dart';
import 'package:qeran/features/community/domain/usecases/get_my_community_posts_usecase.dart';
import 'package:qeran/features/community/presentation/blocs/feed/community_feed_cubit.dart';
import 'package:qeran/features/community/presentation/blocs/feed/community_feed_state.dart';

import '../../../../shared/domain/entities/community_post_status_change.dart';
import 'processing_watch.dart';

/// Her «منشوراتي» (B2–B5): her posts in every status (6.1), newest first,
/// with the feed's paging, likes and changes; a post she publishes joins at
/// the top whatever its status (D4, D5). Opening it, and pulling it to
/// refresh, clears «تعليقات جديدة على منشوراتك» (D33, S20). A post still
/// processing is watched until it's published or failed (§3.5).
class MyPostsCubit extends CommunityFeedCubit {
  MyPostsCubit({
    required GetMyCommunityPostsUseCase getMyPosts,
    required GetCommunityPostUseCase getPost,
    required super.setPostLike,
    required super.watchChanges,
    required Future<void> Function() markCommentsSeen,
    required Stream<CommunityPostStatusChange> statusChanges,
    PeriodicTimerStarter startTimer = Timer.periodic,
  }) : _markCommentsSeen = markCommentsSeen,
       super(getFeed: getMyPosts.call, getPost: getPost, anyStatus: true) {
    _watch = ProcessingWatch(
      statusChanges: statusChanges,
      reread: (postId) => getPost(postId),
      startTimer: startTimer,
    );
  }

  final Future<void> Function() _markCommentsSeen;
  late final ProcessingWatch _watch;

  /// She opened «منشوراتي»: the new comments on her posts are seen (D33).
  Future<void> seen() => _markCommentsSeen();

  /// The app is back in front: her processing posts are read again now.
  void checkProcessing() => _watch.checkNow();

  @override
  Future<void> refresh() {
    unawaited(seen());
    return super.refresh();
  }

  @override
  void onChange(Change<CommunityFeedState> change) {
    super.onChange(change);
    _watch.follow(change.nextState.posts);
  }

  @override
  Future<void> close() async {
    await _watch.dispose();
    return super.close();
  }
}
