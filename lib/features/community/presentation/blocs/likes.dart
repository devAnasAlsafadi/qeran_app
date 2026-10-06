import '../../../../core/errors/errors.dart';
import '../../data/error_codes.dart';
import '../../domain/entities/community_comment.dart';
import '../../domain/entities/community_like_state.dart';
import '../../domain/entities/community_post.dart';

/// Whether the server turned a like away because the member's profile isn't
/// approved — the app's own gate missed it, so the member is told why, as if
/// the gate had caught it (D9).
bool isNotApprovedFailure(Failure failure) =>
    failure is CodedServerFailure &&
    failure.errorCode == CommunityErrorCodes.profileNotApproved;

/// Likes between the member's tap and the server's answer — the same rules
/// for the feed, the post screen and its comments.
extension FlippedLike on CommunityLikeState {
  /// The like as it reads the moment the member taps: flipped, the count one
  /// up or down (never below zero).
  CommunityLikeState get flipped {
    final liked = !likedByMe;
    final count = likeCount + (liked ? 1 : -1);
    return CommunityLikeState(
      likeCount: count < 0 ? 0 : count,
      likedByMe: liked,
    );
  }
}

extension CommunityPostLike on CommunityPost {
  CommunityLikeState get like =>
      CommunityLikeState(likeCount: likeCount, likedByMe: likedByMe);

  /// This post with [like] in place of its own.
  CommunityPost withLike(CommunityLikeState like) => CommunityPost(
    id: id,
    author: author,
    text: text,
    media: media,
    likeCount: like.likeCount,
    likedByMe: like.likedByMe,
    commentCount: commentCount,
    createdAt: createdAt,
    canDelete: canDelete,
    status: status,
  );
}

extension CommunityCommentLike on CommunityComment {
  CommunityLikeState get like =>
      CommunityLikeState(likeCount: likeCount, likedByMe: likedByMe);

  /// This comment or reply with [like] in place of its own.
  CommunityComment withLike(CommunityLikeState like) =>
      _copy(likeCount: like.likeCount, likedByMe: like.likedByMe);

  /// This comment with [count] replies.
  CommunityComment withReplyCount(int count) => _copy(replyCount: count);

  CommunityComment _copy({int? likeCount, bool? likedByMe, int? replyCount}) =>
      CommunityComment(
        id: id,
        postId: postId,
        parentCommentId: parentCommentId,
        author: author,
        text: text,
        likeCount: likeCount ?? this.likeCount,
        likedByMe: likedByMe ?? this.likedByMe,
        replyCount: replyCount ?? this.replyCount,
        createdAt: createdAt,
        isMine: isMine,
        canDelete: canDelete,
        canBlock: canBlock,
        flag: flag,
      );
}
