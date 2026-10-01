import 'community_like_state.dart';
import 'community_post.dart';

/// Something the repository learned about a post that other screens showing
/// it should apply — so a like or a new comment on the post screen is on the
/// feed card when the member goes back. App-lifetime, like the repository.
sealed class CommunityPostChange {
  const CommunityPostChange();

  int get postId;
}

/// A fresh copy of the post (a re-read after a comment, a reply, a delete).
final class CommunityPostUpdated extends CommunityPostChange {
  final CommunityPost post;
  const CommunityPostUpdated(this.post);

  @override
  int get postId => post.id;
}

/// The server's answer to a like or an unlike on the post.
final class CommunityPostLikeChanged extends CommunityPostChange {
  @override
  final int postId;
  final CommunityLikeState like;
  const CommunityPostLikeChanged(this.postId, this.like);
}

/// `POST_NOT_FOUND` — deleted, or no longer visible to this viewer.
final class CommunityPostGone extends CommunityPostChange {
  @override
  final int postId;
  const CommunityPostGone(this.postId);
}
