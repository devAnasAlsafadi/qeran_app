import '../../../domain/entities/community_like_state.dart';
import '../../../domain/entities/community_post.dart';
import '../likes.dart';

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

/// [posts] with [created] first — a post she just published, newest of all
/// (S15) — or in its place if the list has it. Null for a post members can't
/// see yet (`Processing`): the feed shows published posts only.
List<CommunityPost>? withCreatedPost(
  List<CommunityPost> posts,
  CommunityPost created,
) {
  if (created.status != CommunityPostStatus.published) return null;
  return posts.any((post) => post.id == created.id)
      ? replacePost(posts, created)
      : [created, ...posts];
}

/// [posts] with [postId]'s like set to [like].
List<CommunityPost> withLike(
  List<CommunityPost> posts,
  int postId,
  CommunityLikeState like,
) => [for (final post in posts) post.id == postId ? post.withLike(like) : post];

/// [posts] without [postId].
List<CommunityPost> withoutPost(List<CommunityPost> posts, int postId) => [
  for (final post in posts)
    if (post.id != postId) post,
];

/// [post]'s like as it reads the moment the member taps (see
/// [FlippedLike.flipped]).
CommunityLikeState flippedLike(CommunityPost post) => post.like.flipped;
