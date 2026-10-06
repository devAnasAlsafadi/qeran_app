import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/errors/errors.dart';
import '../../../domain/entities/community_like_state.dart';
import '../../../domain/entities/community_post.dart';
import '../../../domain/usecases/set_post_like_usecase.dart';
import '../likes.dart';
import 'community_feed_state.dart';
import 'feed_posts.dart';

/// The feed cubit's likes (B12, B13): at once, then the server's answer.
mixin FeedLikes on Cubit<CommunityFeedState> {
  @protected
  SetPostLikeUseCase get setPostLike;

  /// Posts whose like is on its way: a second tap waits for the answer.
  @protected
  final Set<int> liking = {};

  /// Like or unlike [postId] at once, then settle on the server's answer;
  /// on failure, take it back and say so (B13). A [readOnly] member is told
  /// why instead (B12) — and so is one the server turns away.
  Future<void> toggleLike(int postId, {bool readOnly = false}) async {
    if (readOnly) return emit(state.withEvent(CommunityFeedEvent.readOnlyLike));
    final before = _post(postId);
    if (before == null || !liking.add(postId)) return;
    final optimistic = flippedLike(before);
    emit(state.copyWith(posts: withLike(state.posts, postId, optimistic)));
    final result = await setPostLike(postId, liked: optimistic.likedByMe);
    liking.remove(postId);
    result.fold(
      (failure) => emit(
        state
            .copyWith(posts: _restoreLike(postId, before))
            .withEvent(_likeFailureEvent(failure)),
      ),
      (like) =>
          emit(state.copyWith(posts: withLike(state.posts, postId, like))),
    );
  }

  CommunityPost? _post(int postId) =>
      state.posts.where((post) => post.id == postId).firstOrNull;

  /// [postId]'s like back as it was before the tap.
  List<CommunityPost> _restoreLike(int postId, CommunityPost before) =>
      withLike(
        state.posts,
        postId,
        CommunityLikeState(
          likeCount: before.likeCount,
          likedByMe: before.likedByMe,
        ),
      );

  static CommunityFeedEvent _likeFailureEvent(Failure failure) =>
      isNotApprovedFailure(failure)
      ? CommunityFeedEvent.readOnlyLike
      : CommunityFeedEvent.likeFailed;
}
