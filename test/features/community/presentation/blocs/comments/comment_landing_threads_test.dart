import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/community/domain/entities/community_like_state.dart';
import 'package:qeran/features/community/presentation/blocs/comments/comment_removals.dart';
import 'package:qeran/features/community/presentation/blocs/comments/comment_thread.dart';
import 'package:qeran/features/community/presentation/blocs/comments/comment_threads.dart';

import '../../../fixtures/community_comment_fixtures.dart';

/// A landing's threads (C8, K11): the comment a notification is about
/// first, the reply it's about under it, and what happens to that reply as
/// the rest come.
void main() {
  final mine = testComment(id: 20, replyCount: 3, isMine: true);
  final landed = testReply(id: 203, parentId: 20, author: fahad);

  List<CommentThread> landing() =>
      landedThreads(mine, landed, commentPage(comments(30, 32)));

  test('its thread first, however old, with the reply under it', () {
    final threads = landing();

    expect([for (final t in threads) t.id], [20, 30, 31, 32]);
    expect(threads.first.landed, [landed]);
    expect(threads.first.replies, isEmpty);
  });

  test('a first page that has the comment shows it once', () {
    final threads = landedThreads(
      mine,
      null,
      commentPage([testComment(id: 31), mine, testComment(id: 19)]),
    );

    expect([for (final t in threads) t.id], [20, 31, 19]);
    expect(threads.first.landed, isEmpty);
  });

  test('«عرض ردود أخرى»: the replies not shown, the landed one counted', () {
    final thread = landing().first;

    expect((thread.offersReplies, thread.hiddenReplies), (true, 2));
  });

  test('the page that brings it puts it in its place', () {
    final thread = withRepliesPage(
      landing().first,
      commentPage([
        testReply(id: 201, parentId: 20),
        testReply(id: 202, parentId: 20),
        landed,
      ], totalCount: 3),
    );

    expect([for (final r in thread.replies) r.id], [201, 202, 203]);
    expect(thread.landed, isEmpty);
    expect(thread.offersReplies, isFalse);
  });

  test('a page without it leaves it after them, still counted', () {
    final thread = withRepliesPage(
      landing().first,
      commentPage(
        [testReply(id: 201, parentId: 20)],
        totalPages: 2,
        totalCount: 3,
      ),
    );

    expect([for (final r in thread.replies) r.id], [201]);
    expect(thread.landed, [landed]);
    expect((thread.offersReplies, thread.hiddenReplies), (true, 1));
  });

  test('its like and its lookup reach it', () {
    const liked = CommunityLikeState(likeCount: 1, likedByMe: true);

    final threads = withCommentLike(landing(), 203, liked);

    expect(findComment(threads, 203)?.likedByMe, isTrue);
  });

  test('its author blocked: it goes, one fewer on the comment', () {
    final [after, ...] = withoutAuthor(landing(), fahad.id);

    expect(after.landed, isEmpty);
    expect(after.comment.replyCount, 2);
  });

  test('deleted: it goes, one fewer on the comment', () {
    final [after, ...] = withoutReply(landing(), landed);

    expect(after.landed, isEmpty);
    expect(after.comment.replyCount, 2);
  });
}
