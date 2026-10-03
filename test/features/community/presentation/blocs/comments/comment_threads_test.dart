import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/community/domain/entities/community_like_state.dart';
import 'package:qeran/features/community/presentation/blocs/comments/comment_thread.dart';
import 'package:qeran/features/community/presentation/blocs/comments/comment_threads.dart';

import '../../../fixtures/community_comment_fixtures.dart';

const _liked = CommunityLikeState(likeCount: 3, likedByMe: true);

void main() {
  test('a page that repeats a comment adds it once', () {
    final threads = appendNewThreads(const [], comments(1, 3));

    final next = appendNewThreads(threads, comments(3, 4));

    expect([for (final t in next) t.id], [1, 2, 3, 4]);
  });

  group('a thread\'s replies link', () {
    test('before any page: offered while the comment has replies', () {
      expect(CommentThread(testComment(replyCount: 2)).offersReplies, isTrue);
      expect(CommentThread(testComment()).offersReplies, isFalse);
      expect(CommentThread(testComment(replyCount: 2)).hiddenReplies, 2);
    });

    test('after a page: the page\'s total counts, while there are more', () {
      final thread = withRepliesPage(
        CommentThread(testComment(replyCount: 2)),
        commentPage([testReply()], totalPages: 3, totalCount: 5),
      );

      expect((thread.offersReplies, thread.hiddenReplies), (true, 4));
    });

    test('never a negative count when the totals disagree', () {
      final thread = withRepliesPage(
        CommentThread(testComment(replyCount: 1)),
        commentPage(
          [testReply(id: 100), testReply(id: 101)],
          totalPages: 2,
          totalCount: 1,
        ),
      );

      expect((thread.offersReplies, thread.hiddenReplies), (false, 0));
    });
  });

  test('a like lands on the reply it\'s for, wherever it is', () {
    final threads = [
      CommentThread(testComment(id: 10)),
      withRepliesPage(
        CommentThread(testComment(id: 11, replyCount: 1)),
        commentPage([testReply(id: 100, parentId: 11)]),
      ),
    ];

    final next = withCommentLike(threads, 100, _liked);

    expect(findComment(next, 100)?.likeCount, 3);
    expect(findComment(next, 11)?.likedByMe, isFalse);
    expect(findComment(next, 10)?.likedByMe, isFalse);
    expect(findComment(next, 999), isNull);
  });

  test('updateThread changes only its own thread', () {
    final threads = appendNewThreads(const [], comments(1, 2));

    final next = updateThread(
      threads,
      2,
      (t) => t.copyWith(repliesStatus: RepliesStatus.loading),
    );

    expect(
      [for (final t in next) t.repliesStatus],
      [RepliesStatus.collapsed, RepliesStatus.loading],
    );
  });
}
