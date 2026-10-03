import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/community/presentation/blocs/comments/comment_thread.dart';
import 'package:qeran/features/community/presentation/blocs/comments/community_comments_state.dart';

import '../../../fixtures/community_comment_fixtures.dart';
import 'comments_cubit_harness.dart';

void main() {
  late CommentsHarness h;
  setUp(() => h = CommentsHarness());
  tearDown(() => h.dispose());

  group('the first page', () {
    test('starts loading: the skeleton rows (C5)', () {
      expect(h.cubit.state.status, CommunityCommentsStatus.loading);
    });

    test('comments → loaded, newest first as sent (C1)', () async {
      h.page(1, comments(1, 3), totalPages: 2);

      await h.cubit.load();

      expect(h.cubit.state.status, CommunityCommentsStatus.loaded);
      expect(h.ids, [1, 2, 3]);
      expect(h.cubit.state.hasMore, isTrue);
    });

    test('none → empty (C4)', () async {
      h.page(1, const []);

      await h.cubit.load();

      expect(h.cubit.state.status, CommunityCommentsStatus.empty);
    });

    test('a failure → the error, and its retry loads again (C6)', () async {
      h.pageFails(1);
      await h.cubit.load();
      expect(h.cubit.state.status, CommunityCommentsStatus.failure);

      h.page(1, comments(1, 2));
      await h.cubit.load();
      expect(h.cubit.state.status, CommunityCommentsStatus.loaded);
    });
  });

  group('more comments (C3)', () {
    setUp(() async {
      h.page(1, comments(1, 3), totalPages: 3);
      await h.cubit.load();
    });

    test('adds what it hasn\'t got, with a loader meanwhile', () async {
      final answer = Completer<CommentsAnswer>();
      when(() => h.getComments(1, page: 2)).thenAnswer((_) => answer.future);

      final more = h.cubit.loadMore();
      expect(h.cubit.state.loadingMore, isTrue);
      answer.complete(
        Right(commentPage(comments(3, 5), page: 2, totalPages: 3)),
      );
      await more;

      expect(h.ids, [1, 2, 3, 4, 5]);
      expect(h.cubit.state.loadingMore, isFalse);
    });

    test('a failure says so; its retry asks again', () async {
      h.pageFails(2);
      await h.cubit.loadMore();
      expect(h.cubit.state.pageFailed, isTrue);

      h.page(2, comments(4, 5), totalPages: 3);
      await h.cubit.loadMore();
      expect(h.cubit.state.pageFailed, isFalse);
      expect(h.ids, [1, 2, 3, 4, 5]);
    });

    test('the last page ends it', () async {
      h.page(2, comments(4, 5), totalPages: 2);

      await h.cubit.loadMore();
      await h.cubit.loadMore();

      expect(h.cubit.state.hasMore, isFalse);
      verifyNever(() => h.getComments(1, page: 3));
    });
  });

  group('replies (C2)', () {
    setUp(() async {
      h.page(1, [testComment(id: 10, replyCount: 3), testComment(id: 11)]);
      await h.cubit.load();
    });

    test('the first page opens the thread, oldest first, and counts the '
        'rest', () async {
      h.replies(
        10,
        1,
        [testReply(id: 100), testReply(id: 101)],
        totalPages: 2,
        totalCount: 3,
      );

      await h.cubit.showReplies(10);

      final thread = h.thread(10);
      expect([for (final r in thread.replies) r.id], [100, 101]);
      expect(thread.repliesStatus, RepliesStatus.open);
      expect((thread.offersReplies, thread.hiddenReplies), (true, 1));
    });

    test('the next page adds the rest, each reply once', () async {
      h.replies(
        10,
        1,
        [testReply(id: 100), testReply(id: 101)],
        totalPages: 2,
        totalCount: 3,
      );
      await h.cubit.showReplies(10);
      h.replies(
        10,
        2,
        [testReply(id: 101), testReply(id: 102)],
        totalPages: 2,
        totalCount: 3,
      );

      await h.cubit.showReplies(10);

      final thread = h.thread(10);
      expect([for (final r in thread.replies) r.id], [100, 101, 102]);
      expect(thread.offersReplies, isFalse);
    });

    test(
      'a page on its way: a second tap waits; a failure is retried',
      () async {
        final answer = Completer<CommentsAnswer>();
        when(() => h.getReplies(10, page: 1)).thenAnswer((_) => answer.future);

        final first = h.cubit.showReplies(10);
        expect(h.thread(10).repliesStatus, RepliesStatus.loading);
        await h.cubit.showReplies(10);
        answer.complete(const Left(OfflineFailure()));
        await first;
        expect(h.thread(10).repliesStatus, RepliesStatus.failed);
        verify(() => h.getReplies(10, page: 1)).called(1);

        h.replies(10, 1, [testReply()]);
        await h.cubit.showReplies(10);
        expect(h.thread(10).replies, [testReply()]);
      },
    );
  });
}
