import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/community_like_state.dart';
import '../../../domain/usecases/set_comment_like_usecase.dart';
import '../likes.dart';
import 'comment_threads.dart';
import 'community_comments_state.dart';

/// The comments cubit's likes: on a comment or a reply, at once, then the
/// server's answer.
mixin CommentLikes on Cubit<CommunityCommentsState> {
  @protected
  SetCommentLikeUseCase get setCommentLike;

  /// Comments and replies whose like is on its way: a second tap waits.
  final Set<int> _liking = {};

  /// Like or unlike a comment or a reply at once, then settle on the
  /// server's answer; on failure, take it back and say so. A [readOnly]
  /// member is told why instead — and so is one the server turns away.
  Future<void> toggleLike(int commentId, {bool readOnly = false}) async {
    if (readOnly) {
      return emit(state.withEvent(CommunityCommentsEvent.readOnlyLike));
    }
    final before = findComment(state.threads, commentId)?.like;
    if (before == null || !_liking.add(commentId)) return;
    _setLike(commentId, before.flipped);
    final result = await setCommentLike(commentId, liked: !before.likedByMe);
    _liking.remove(commentId);
    result.fold((failure) {
      _setLike(commentId, before);
      emit(
        state.withEvent(
          isNotApprovedFailure(failure)
              ? CommunityCommentsEvent.readOnlyLike
              : CommunityCommentsEvent.likeFailed,
        ),
      );
    }, (like) => _setLike(commentId, like));
  }

  void _setLike(int commentId, CommunityLikeState like) => emit(
    state.copyWith(threads: withCommentLike(state.threads, commentId, like)),
  );
}
