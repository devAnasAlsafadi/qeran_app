import '../../../domain/entities/community_comment.dart';
import '../../../domain/entities/community_like_state.dart';
import '../../../domain/entities/community_page.dart';
import '../likes.dart';
import 'comment_thread.dart';

/// List operations on a post's threads — pure, so the cubit stays small and
/// each rule has its own test.

/// [threads] followed by a thread for each of [comments] it doesn't have
/// yet. A comment posted while the member reads shifts the later pages by
/// one, so a page can repeat the previous page's last comment.
List<CommentThread> appendNewThreads(
  List<CommentThread> threads,
  List<CommunityComment> comments,
) {
  final seen = {for (final thread in threads) thread.id};
  return [
    ...threads,
    for (final comment in comments)
      if (seen.add(comment.id)) CommentThread(comment),
  ];
}

/// [threads] with [commentId]'s thread replaced by what [update] makes of it.
List<CommentThread> updateThread(
  List<CommentThread> threads,
  int commentId,
  CommentThread Function(CommentThread thread) update,
) => [
  for (final thread in threads)
    thread.id == commentId ? update(thread) : thread,
];

/// [thread] with [page]'s replies it doesn't have yet after its own, open,
/// and what the page says about the rest.
CommentThread withRepliesPage(
  CommentThread thread,
  CommunityPage<CommunityComment> page,
) {
  final seen = {for (final reply in thread.replies) reply.id};
  return thread.copyWith(
    replies: [
      ...thread.replies,
      for (final reply in page.items)
        if (seen.add(reply.id)) reply,
    ],
    repliesStatus: RepliesStatus.open,
    repliesPage: page.pageNumber,
    repliesTotal: page.totalCount,
    hasMoreReplies: page.hasMore,
  );
}

/// The comment or reply [commentId], in whichever thread it is.
CommunityComment? findComment(List<CommentThread> threads, int commentId) {
  for (final thread in threads) {
    if (thread.id == commentId) return thread.comment;
    for (final reply in thread.replies) {
      if (reply.id == commentId) return reply;
    }
  }
  return null;
}

/// [threads] with the like of [commentId] — a comment or a reply — set to
/// [like].
List<CommentThread> withCommentLike(
  List<CommentThread> threads,
  int commentId,
  CommunityLikeState like,
) => [
  for (final thread in threads)
    thread.copyWith(
      comment: thread.id == commentId
          ? thread.comment.withLike(like)
          : thread.comment,
      replies: [
        for (final reply in thread.replies)
          reply.id == commentId ? reply.withLike(like) : reply,
      ],
    ),
];
