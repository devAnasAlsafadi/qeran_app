import '../../../domain/entities/community_like_state.dart';
import '../../../domain/entities/community_post.dart';

/// List operations on the feed's posts — pure, so the cubit stays small and
/// each rule has its own test.

/// [posts] followed by the [page]'s posts it doesn't have yet. A post
/// published while the member scrolls shifts the later pages by one, so a
/// page can repeat the previous page's last post.
List<CommunityPost> appendNewPosts(
  List<CommunityPost> posts,
  List<CommunityPost> page,
) {
  final seen = {for (final post in posts) post.id};
  return [
    ...posts,
    for (final post in page)
      if (seen.add(post.id)) post,
  ];
}

/// [page] with each post once — the first page of a refresh replaces the
/// list.
List<CommunityPost> distinctPosts(List<CommunityPost> page) =>
    appendNewPosts(const [], page);

/// [posts] with [updated] in place of the post with its id, if it's there.
List<CommunityPost> replacePost(
  List<CommunityPost> posts,
  CommunityPost updated,
) => [for (final post in posts) post.id == updated.id ? updated : post];

/// [posts] with [postId]'s like set to [like].
List<CommunityPost> withLike(
  List<CommunityPost> posts,
  int postId,
  CommunityLikeState like,
) => [
  for (final post in posts)
    post.id == postId
        ? CommunityPost(
            id: post.id,
            author: post.author,
            text: post.text,
            media: post.media,
            likeCount: like.likeCount,
            likedByMe: like.likedByMe,
            commentCount: post.commentCount,
            createdAt: post.createdAt,
            canDelete: post.canDelete,
            status: post.status,
          )
        : post,
];

/// [posts] without [postId].
List<CommunityPost> withoutPost(List<CommunityPost> posts, int postId) => [
  for (final post in posts)
    if (post.id != postId) post,
];

/// [post]'s like as it reads the moment the member taps: flipped, the count
/// one up or down (never below zero) — before the server answers.
CommunityLikeState flippedLike(CommunityPost post) {
  final liked = !post.likedByMe;
  final count = post.likeCount + (liked ? 1 : -1);
  return CommunityLikeState(likeCount: count < 0 ? 0 : count, likedByMe: liked);
}
