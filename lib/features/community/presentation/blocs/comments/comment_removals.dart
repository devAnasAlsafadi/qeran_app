import 'dart:math';

import '../../../domain/entities/community_comment.dart';
import '../likes.dart';
import 'comment_thread.dart';
import 'comment_threads.dart';

/// Taking comments out of a post's threads after a delete or a block — pure,
/// like the rest of the list operations.

/// [threads] without [reply] — the server's or the member's own — and one
/// fewer on its comment's count.
List<CommentThread> withoutReply(
  List<CommentThread> threads,
  CommunityComment reply,
) => updateThread(
  threads,
  reply.parentCommentId!,
  (thread) => _withoutReplies(thread, (r) => r.id == reply.id),
);

/// [threads] without what [authorId] wrote, after a block (D23): their
/// comments, with every reply under them, and their replies under anyone
/// else's — each comment's count lowered by the replies taken.
List<CommentThread> withoutAuthor(
  List<CommentThread> threads,
  String authorId,
) => [
  for (final thread in threads)
    if (thread.comment.author.id != authorId)
      _withoutReplies(thread, (r) => r.author.id == authorId),
];

/// [thread] without the replies [gone] picks. Only posted ones were in the
/// counts; one still on its way wasn't.
CommentThread _withoutReplies(
  CommentThread thread,
  bool Function(CommunityComment reply) gone,
) {
  final taken =
      thread.replies.where(gone).length +
      thread.landed.where(gone).length +
      thread.mine.where((r) => r.id > 0 && gone(r)).length;
  final total = thread.repliesTotal;
  return thread.copyWith(
    comment: thread.comment.withReplyCount(
      max(thread.comment.replyCount - taken, 0),
    ),
    repliesTotal: total == null ? null : max(total - taken, 0),
    replies: [
      for (final r in thread.replies)
        if (!gone(r)) r,
    ],
    landed: [
      for (final r in thread.landed)
        if (!gone(r)) r,
    ],
    mine: [
      for (final r in thread.mine)
        if (!gone(r)) r,
    ],
  );
}
