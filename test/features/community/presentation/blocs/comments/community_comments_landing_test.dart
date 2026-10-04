import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/community/domain/entities/community_landing.dart';
import 'package:qeran/features/community/presentation/blocs/comments/community_comments_state.dart';

import '../../../fixtures/community_comment_fixtures.dart';
import 'comments_cubit_harness.dart';

const _commentNotFound = CodedServerFailure(
  message: 'x',
  errorCode: 'COMMENT_NOT_FOUND',
);

/// Opened from "New reply to your comment" (C8, S7): the comment first, the
/// reply under it in gold — or, either gone, the content no longer
/// available (C7).
void main() {
  final mine = testComment(id: 20, replyCount: 3, isMine: true);
  final reply = testReply(id: 203, parentId: 20, author: fahad);
  late CommentsHarness h;

  CommentsHarness landingAt(CommunityLanding landing) {
    h = CommentsHarness(landing: landing);
    h.single(20, Right(mine));
    h.single(203, Right(reply));
    h.page(1, comments(30, 32), totalPages: 2);
    return h;
  }

  tearDown(() => h.dispose());

  test('the comment first, the reply under it, highlighted', () async {
    landingAt(const CommunityLanding(commentId: 20, replyId: 203));

    await h.cubit.load();

    final state = h.cubit.state;
    expect(state.status, CommunityCommentsStatus.loaded);
    expect(h.ids, [20, 30, 31, 32]);
    expect(h.thread(20).landed, [reply]);
    expect(state.highlightId, 203);
    expect((state.page, state.hasMore), (1, true));
  });

  test('a landing on a comment highlights the comment', () async {
    landingAt(const CommunityLanding(commentId: 20));

    await h.cubit.load();

    expect(h.cubit.state.highlightId, 20);
    expect(h.thread(20).landed, isEmpty);
    verifyNever(() => h.getComment(203));
  });

  for (final gone in [20, 203]) {
    test('${gone == 20 ? 'the comment' : 'the reply'} gone: no longer '
        'available', () async {
      landingAt(const CommunityLanding(commentId: 20, replyId: 203));
      h.single(gone, const Left(_commentNotFound));

      await h.cubit.load();

      expect(h.cubit.state.status, CommunityCommentsStatus.targetGone);
    });
  }

  test('offline: the error, and its retry lands again', () async {
    landingAt(const CommunityLanding(commentId: 20, replyId: 203));
    h.single(20, const Left(OfflineFailure()));
    await h.cubit.load();
    expect(h.cubit.state.status, CommunityCommentsStatus.failure);

    h.single(20, Right(mine));
    await h.cubit.load();

    expect(h.ids.first, 20);
    expect(h.cubit.state.highlightId, 203);
  });

  test('«عرض ردود أخرى» brings the rest, the reply in its place', () async {
    landingAt(const CommunityLanding(commentId: 20, replyId: 203));
    await h.cubit.load();
    h.replies(20, 1, [
      testReply(id: 201, parentId: 20),
      testReply(id: 202, parentId: 20),
      reply,
    ], totalCount: 3);

    await h.cubit.showReplies(20);

    expect([for (final r in h.thread(20).replies) r.id], [201, 202, 203]);
    expect(h.thread(20).landed, isEmpty);
  });

  test(
    'landed once: a pull to refresh reads the discussion as it is',
    () async {
      landingAt(const CommunityLanding(commentId: 20, replyId: 203));
      await h.cubit.load();

      await h.cubit.refresh();

      expect(h.ids, [30, 31, 32]);
      verify(() => h.getComment(20)).called(1);
    },
  );

  test('the highlight goes when its moment is over', () async {
    landingAt(const CommunityLanding(commentId: 20, replyId: 203));
    await h.cubit.load();

    h.cubit.clearHighlight();

    expect(h.cubit.state.highlightId, isNull);
    expect(h.thread(20).landed, [reply]);
  });

  test('opened without a landing, no comment is read on its own', () async {
    h = CommentsHarness();
    h.page(1, comments(30, 31));

    await h.cubit.load();

    expect(h.ids, [30, 31]);
    expect(h.cubit.state.highlightId, isNull);
    verifyNever(() => h.getComment(any()));
  });
}
