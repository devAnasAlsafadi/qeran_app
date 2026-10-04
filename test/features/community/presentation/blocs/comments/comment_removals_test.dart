import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/community/presentation/blocs/comments/comment_removals.dart';
import 'package:qeran/features/community/presentation/blocs/comments/comment_thread.dart';

import '../../../fixtures/community_comment_fixtures.dart';
import '../../../fixtures/community_post_fixtures.dart';

/// What leaves the list after a delete (E9) or a block (E12), and the
/// counts that follow it.
void main() {
  final saraComment = testComment(id: 10, replyCount: 3);
  final fahadComment = testComment(id: 11, author: fahad, replyCount: 2);

  group('withoutReply', () {
    test("one of the server's: gone, one fewer on its comment", () {
      final thread = CommentThread(
        saraComment,
        replies: [testReply(id: 100), testReply(id: 101)],
        repliesPage: 1,
        repliesTotal: 3,
      );

      final [after] = withoutReply([thread], testReply(id: 100));

      expect(after.replies.map((r) => r.id), [101]);
      expect(after.comment.replyCount, 2);
      expect(after.repliesTotal, 2);
    });

    test("one the member posted from here: counted, so it's taken off", () {
      final mine = testReply(id: 102, author: sara);
      final thread = CommentThread(saraComment, mine: [mine]);

      final [after] = withoutReply([thread], mine);

      expect(after.mine, isEmpty);
      expect(after.comment.replyCount, 2);
    });
  });

  test("withoutAuthor: their comments go with every reply, and their replies "
      "under anyone else's lower that comment's count (D23)", () {
    final threads = [
      CommentThread(saraComment, replies: [testReply(id: 100, author: huda)]),
      CommentThread(
        fahadComment,
        replies: [
          testReply(id: 110, parentId: 11, author: sara),
          testReply(id: 111, parentId: 11, author: huda),
        ],
        repliesTotal: 2,
      ),
    ];

    final after = withoutAuthor(threads, sara.id);

    expect(after.map((t) => t.id), [11]);
    expect(after.single.replies.map((r) => r.id), [111]);
    expect(after.single.comment.replyCount, 1);
    expect(after.single.repliesTotal, 1);
  });
}
