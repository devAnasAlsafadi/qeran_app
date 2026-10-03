import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/community/domain/entities/comment_submit_outcome.dart';
import 'package:qeran/features/community/domain/entities/community_author.dart';
import 'package:qeran/features/community/presentation/blocs/comments/comment_thread.dart';
import 'package:qeran/features/community/presentation/blocs/comments/community_comments_state.dart';

import '../../../fixtures/community_comment_fixtures.dart';
import 'comments_cubit_harness.dart';

const _me = CommunityAuthor(
  id: 'member-9',
  displayName: 'Dima Alsafadi',
  isMatchmaker: false,
);

const _question = 'متى يكون الوقت المناسب لطلب الرؤية الشرعية؟';

void main() {
  late CommentsHarness h;
  setUp(() async {
    h = CommentsHarness();
    h.page(1, [testComment(id: 10, replyCount: 2), testComment(id: 11)]);
    await h.cubit.load();
  });
  tearDown(() => h.dispose());

  CommunityCommentsState s() => h.cubit.state;

  group('a comment', () {
    test('shows at once at the top, «جارٍ النشر…», then the server\'s copy '
        '(D5, D6)', () async {
      final answer = Completer<Either<Failure, CommentSubmitOutcome>>();
      when(
        () => h.createComment(1, _question),
      ).thenAnswer((_) => answer.future);

      final sending = h.cubit.send(_question, me: _me);
      final local = s().threads.first.comment;
      expect((local.id < 0, local.author, local.text), (true, _me, _question));
      expect(s().delivery[local.id], CommentDelivery.pending);

      answer.complete(
        Right(CommentPosted(testComment(id: 99, text: _question))),
      );
      expect(await sending, isNull);

      expect(h.ids, [99, 10, 11]);
      expect(s().delivery, isEmpty);
      verify(() => h.getPost(1)).called(1);
    });

    test('failed: the row stays with its retry, which sends the same text '
        '(D7)', () async {
      h.commentAnswers(const Left(OfflineFailure()));
      await h.cubit.send(_question, me: _me);
      final local = s().threads.first.id;
      expect(s().delivery[local], CommentDelivery.failed);

      h.commentAnswers(Right(CommentPosted(testComment(id: 99))));
      await h.cubit.retry(local);

      verify(() => h.createComment(1, _question)).called(2);
      expect(h.ids, [99, 10, 11]);
      expect(s().delivery, isEmpty);
    });

    test(
      'refused: the row goes, and the outcome comes back for the field',
      () async {
        h.commentAnswers(const Right(CommentFiltered()));

        final outcome = await h.cubit.send(_question, me: _me);

        expect(outcome, isA<CommentFiltered>());
        expect(h.ids, [10, 11]);
        expect(s().delivery, isEmpty);
      },
    );

    test('the first on the post: the discussion has it, then not', () async {
      h.page(1, const []);
      await h.cubit.load();
      h.commentAnswers(const Right(CommentRateLimited()));

      final sending = h.cubit.send(_question, me: _me);
      expect(s().status, CommunityCommentsStatus.loaded);
      await sending;

      expect(s().status, CommunityCommentsStatus.empty);
    });

    test('the post gone: it\'s read again, so the screen learns it', () async {
      h.commentAnswers(const Right(CommentPostGone()));

      await h.cubit.send(_question, me: _me);

      verify(() => h.getPost(1)).called(1);
    });
  });

  group('a reply', () {
    test(
      'under its comment, after the rest; posted, it counts (D10)',
      () async {
        h.replyAnswers(10, Right(CommentPosted(testReply(id: 98))));

        final sending = h.cubit.send('شكراً', parentId: 10, me: _me);
        expect(h.thread(10).mine.single.text, 'شكراً');
        await sending;

        final thread = h.thread(10);
        expect(thread.mine.single.id, 98);
        expect(thread.comment.replyCount, 3);
        expect(thread.hiddenReplies, 2);
      },
    );

    test('its comment gone: the reply and the comment go (S9)', () async {
      h.replyAnswers(10, const Right(CommentParentGone()));

      final outcome = await h.cubit.send('شكراً', parentId: 10, me: _me);

      expect(outcome, isA<CommentParentGone>());
      expect(h.ids, [11]);
    });
  });

  test('a pull to refresh keeps what isn\'t settled', () async {
    h.commentAnswers(const Left(OfflineFailure()));
    await h.cubit.send(_question, me: _me);
    h.replyAnswers(10, const Left(OfflineFailure()));
    await h.cubit.send('شكراً', parentId: 10, me: _me);

    h.page(1, [testComment(id: 12), testComment(id: 10, replyCount: 2)]);
    await h.cubit.refresh();

    expect(h.ids.skip(1), [12, 10]);
    expect(h.ids.first, lessThan(0));
    expect(h.thread(10).mine.single.text, 'شكراً');
  });
}
