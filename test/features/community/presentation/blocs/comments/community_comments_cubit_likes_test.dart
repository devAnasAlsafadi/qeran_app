import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/community/domain/entities/community_like_state.dart';
import 'package:qeran/features/community/presentation/blocs/comments/community_comments_state.dart';

import '../../../fixtures/community_comment_fixtures.dart';
import 'comments_cubit_harness.dart';

void main() {
  late CommentsHarness h;
  setUp(() => h = CommentsHarness());
  tearDown(() => h.dispose());

  group('likes, on a comment or a reply', () {
    setUp(() async {
      h.page(1, [testComment(id: 10, likeCount: 4, replyCount: 1)]);
      h.replies(10, 1, [testReply(id: 100)]);
      await h.cubit.load();
      await h.cubit.showReplies(10);
    });

    (int, bool) comment() =>
        (h.thread(10).comment.likeCount, h.thread(10).comment.likedByMe);
    (int, bool) reply() => (
      h.thread(10).replies.single.likeCount,
      h.thread(10).replies.single.likedByMe,
    );

    test('a comment\'s shows at once, then the server\'s answer', () async {
      final answer = Completer<Either<Failure, CommunityLikeState>>();
      when(() => h.setLike(10, liked: true)).thenAnswer((_) => answer.future);

      final liking = h.cubit.toggleLike(10);
      expect(comment(), (5, true));
      answer.complete(
        const Right(CommunityLikeState(likeCount: 8, likedByMe: true)),
      );
      await liking;

      expect(comment(), (8, true));
    });

    test('a reply\'s, likewise', () async {
      h.likeAnswers(
        100,
        const Right(CommunityLikeState(likeCount: 1, likedByMe: true)),
      );

      await h.cubit.toggleLike(100);

      expect(reply(), (1, true));
      expect(comment(), (4, false));
    });

    test('failed: taken back, and the screen says so', () async {
      h.likeAnswers(10, const Left(ServerFailure(message: 'x')));

      await h.cubit.toggleLike(10);

      expect(comment(), (4, false));
      expect(h.cubit.state.event, CommunityCommentsEvent.likeFailed);
    });

    test('turned away as not approved: told why', () async {
      h.likeAnswers(
        100,
        const Left(
          CodedServerFailure(message: 'x', errorCode: 'PROFILE_NOT_APPROVED'),
        ),
      );

      await h.cubit.toggleLike(100);

      expect(reply(), (0, false));
      expect(h.cubit.state.event, CommunityCommentsEvent.readOnlyLike);
    });

    test('read-only: told why, and nothing is sent (D9)', () async {
      final before = h.cubit.state.eventVersion;

      await h.cubit.toggleLike(10, readOnly: true);

      expect(h.cubit.state.event, CommunityCommentsEvent.readOnlyLike);
      expect(h.cubit.state.eventVersion, before + 1);
      verifyNever(() => h.setLike(any(), liked: any(named: 'liked')));
    });

    test('a second tap waits for the first answer', () async {
      final answer = Completer<Either<Failure, CommunityLikeState>>();
      when(
        () => h.setLike(10, liked: any(named: 'liked')),
      ).thenAnswer((_) => answer.future);

      final first = h.cubit.toggleLike(10);
      await h.cubit.toggleLike(10);
      answer.complete(
        const Right(CommunityLikeState(likeCount: 5, likedByMe: true)),
      );
      await first;

      verify(() => h.setLike(10, liked: true)).called(1);
    });
  });
}
